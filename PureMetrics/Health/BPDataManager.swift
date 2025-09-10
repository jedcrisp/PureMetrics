import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
    static let userDidSignOut = Notification.Name("userDidSignOut")
}

// MARK: - BP Category Enum

enum BPCategory: String, CaseIterable {
    case normal = "Normal"
    case elevated = "Elevated"
    case highStage1 = "High Stage 1"
    case highStage2 = "High Stage 2"
    case hypertensiveCrisis = "Hypertensive Crisis"
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .elevated: return .yellow
        case .highStage1: return .orange
        case .highStage2: return .red
        case .hypertensiveCrisis: return .purple
        }
    }
    
    static func fromValues(systolic: Int, diastolic: Int) -> BPCategory {
        if systolic >= 180 || diastolic >= 120 {
            return .hypertensiveCrisis
        } else if systolic >= 140 || diastolic >= 90 {
            return .highStage2
        } else if systolic >= 130 || diastolic >= 80 {
            return .highStage1
        } else if systolic >= 120 || diastolic >= 80 {
            return .elevated
        } else {
            return .normal
        }
    }
}

// MARK: - Rolling Average Model

struct RollingAverage: Identifiable {
    let id = UUID()
    let period: Int
    let averageSystolic: Double
    let averageDiastolic: Double
    let averageHeartRate: Double?
    let readingCount: Int
    let sessionCount: Int
    let startDate: Date
    let endDate: Date
    
    var displayString: String {
        let systolic = Int(averageSystolic.rounded())
        let diastolic = Int(averageDiastolic.rounded())
        return "\(systolic)/\(diastolic)"
    }
    
    var periodLabel: String {
        switch period {
        case 3: return "3-Day"
        case 7: return "7-Day"
        case 14: return "14-Day"
        case 21: return "21-Day"
        case 30: return "30-Day"
        default: return "\(period)-Day"
        }
    }
    
    var bpCategory: BPCategory {
        BPCategory.fromValues(systolic: Int(averageSystolic.rounded()), diastolic: Int(averageDiastolic.rounded()))
    }
}

class BPDataManager: ObservableObject {
    @Published var currentSession: BPSession
    @Published var sessions: [BPSession] = []
    @Published var currentFitnessSession: FitnessSession
    @Published var fitnessSessions: [FitnessSession] = []
    @Published var userProfile: UserProfile?
    @Published var isSyncing = false
    @Published var syncError: String?
    private var hasSyncedForCurrentSession = false
    
    // Health metrics storage
    @Published var healthMetrics: [HealthMetric] = []
    
    // Custom workouts storage
    @Published var customWorkouts: [CustomWorkout] = []
    
    // Nutrition storage
    @Published var nutritionEntries: [NutritionEntry] = []
    @Published var nutritionGoals: NutritionGoals = NutritionGoals()
    
    // One Rep Max storage
    @Published var oneRepMaxManager = OneRepMaxManager()
    
    // HealthKit storage
    @Published var healthKitManager = HealthKitManager()
    
    private let maxReadingsPerSession = Int.max
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "BPSessions"
    private let fitnessSessionsKey = "FitnessSessions"
    private let customWorkoutsKey = "CustomWorkouts"
    private let nutritionEntriesKey = "NutritionEntries"
    private let nutritionGoalsKey = "NutritionGoals"
    
    // Firebase services
    private let firestoreService = FirestoreService()
    private let storageService = StorageService()
    private let authService = AuthService()
    
    init() {
        self.currentSession = BPSession()
        self.currentFitnessSession = FitnessSession()
        loadSessions()
        loadFitnessSessions()
        loadHealthMetrics()
        loadCustomWorkouts()
        loadNutritionEntries()
        loadNutritionGoals()
        
        // Load custom workouts from Firestore (with local fallback)
        loadCustomWorkoutsFromFirestore()
        
        // Listen for authentication changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidSignIn),
            name: .userDidSignIn,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidSignOut),
            name: .userDidSignOut,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func userDidSignIn() {
        // Prevent multiple simultaneous syncs or repeated syncs for same session
        guard !isSyncing && !hasSyncedForCurrentSession else {
            print("Sync already in progress or completed for this session, skipping...")
            return
        }
        
        print("User signed in, syncing data to Firebase...")
        hasSyncedForCurrentSession = true
        
        // Add a small delay to prevent rapid-fire sync attempts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.loadFromFirebase()
        }
        
        // Add a timeout to prevent indefinite hanging
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            if self?.isSyncing == true {
                print("Sync timeout - forcing completion")
                self?.isSyncing = false
                self?.syncError = "Sync timed out - using local data"
                
                // Load local data as fallback
                self?.loadSessions()
                self?.loadFitnessSessions()
                self?.loadHealthMetrics()
            }
        }
    }
    
    @objc private func userDidSignOut() {
        print("User signed out, resetting sync state...")
        hasSyncedForCurrentSession = false
        isSyncing = false
        syncError = nil
    }
    
    // MARK: - Session Management
    
    func addReading(systolic: Int, diastolic: Int, heartRate: Int? = nil, timestamp: Date? = nil) -> Bool {
        let reading = BloodPressureReading(systolic: systolic, diastolic: diastolic, heartRate: heartRate, timestamp: timestamp)
        guard reading.isValid else {
            return false
        }
        
        // Create a single-reading session and save it immediately
        var session = BPSession(startTime: timestamp ?? Date())
        session.addReading(reading)
        session.complete()
        
        // Add to sessions array
        sessions.insert(session, at: 0)
        
        // Auto-save to Firestore
        saveSessions()
        
        return true
    }
    
    func addHealthMetric(type: MetricType, value: Double, timestamp: Date? = nil) -> Bool {
        let metric = HealthMetric(type: type, value: value, timestamp: timestamp)
        guard metric.isValid else {
            return false
        }
        
        // Add to health metrics array
        healthMetrics.insert(metric, at: 0)
        
        // Save locally and to Firestore
        saveHealthMetrics()
        
        return true
    }
    
    // MARK: - Health Metrics Management
    
    func removeHealthMetric(at index: Int) {
        guard index >= 0 && index < healthMetrics.count else { return }
        healthMetrics.remove(at: index)
        saveHealthMetrics()
    }
    
    func removeHealthMetric(by id: UUID) {
        healthMetrics.removeAll { $0.id == id }
        saveHealthMetrics()
    }
    
    func getHealthMetrics(for type: MetricType, limit: Int? = nil) -> [HealthMetric] {
        let filtered = healthMetrics.filter { $0.type == type }
        if let limit = limit {
            return Array(filtered.prefix(limit))
        }
        return filtered
    }
    
    func getLatestHealthMetric(for type: MetricType) -> HealthMetric? {
        return healthMetrics.first { $0.type == type }
    }
    
    func getHealthMetricsForDate(_ date: Date) -> [HealthMetric] {
        let calendar = Calendar.current
        return healthMetrics.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
    }
    
    func getHealthMetricsForDateRange(_ startDate: Date, _ endDate: Date) -> [HealthMetric] {
        return healthMetrics.filter { $0.timestamp >= startDate && $0.timestamp <= endDate }
    }
    
    // MARK: - Health Metrics Analytics
    
    func getAverageValue(for type: MetricType, days: Int = 30) -> Double? {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let recentMetrics = healthMetrics.filter { 
            $0.type == type && $0.timestamp >= cutoffDate 
        }
        
        guard !recentMetrics.isEmpty else { return nil }
        
        let sum = recentMetrics.reduce(0) { $0 + $1.value }
        return sum / Double(recentMetrics.count)
    }
    
    func getTrend(for type: MetricType, days: Int = 7) -> HealthTrend {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        let recentMetrics = healthMetrics.filter { 
            $0.type == type && $0.timestamp >= cutoffDate 
        }.sorted { $0.timestamp < $1.timestamp }
        
        guard recentMetrics.count >= 2 else { return .stable }
        
        let firstValue = recentMetrics.first!.value
        let lastValue = recentMetrics.last!.value
        let change = lastValue - firstValue
        let changePercent = (change / firstValue) * 100
        
        if changePercent > 5 {
            return .increasing
        } else if changePercent < -5 {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    // MARK: - Health Metrics Persistence
    
    private func saveHealthMetrics() {
        do {
            let data = try JSONEncoder().encode(healthMetrics)
            userDefaults.set(data, forKey: "HealthMetrics")
            
            // Don't auto-sync individual metrics - let the full sync handle it
            // This prevents duplicate entries in Firebase
        } catch {
            print("Error saving health metrics: \(error)")
        }
    }
    
    private func loadHealthMetrics() {
        guard let data = userDefaults.data(forKey: "HealthMetrics") else { return }
        
        do {
            healthMetrics = try JSONDecoder().decode([HealthMetric].self, from: data)
        } catch {
            print("Error loading health metrics: \(error)")
            healthMetrics = []
        }
    }
    
    
    func removeReading(at index: Int) {
        currentSession.removeReading(at: index)
    }
    
    func clearCurrentSession() {
        currentSession = BPSession()
    }
    
    func startSession() {
        currentSession = BPSession(startTime: Date())
    }
    
    func stopSession() {
        currentSession.stop()
    }
    
    func saveCurrentSession() {
        guard !currentSession.readings.isEmpty else { return }
        
        currentSession.complete()
        sessions.insert(currentSession, at: 0)
        saveSessions()
        clearCurrentSession()
    }
    
    func canAddReading() -> Bool {
        return currentSession.readings.count < maxReadingsPerSession
    }
    
    // MARK: - Delete Operations
    
    func deleteSession(at index: Int) {
        guard index >= 0 && index < sessions.count else { return }
        sessions.remove(at: index)
        saveSessions()
    }
    
    func deleteSession(by id: UUID) {
        sessions.removeAll { $0.id == id }
        saveSessions()
    }
    
    func deleteSessionsForDate(_ date: Date) {
        let calendar = Calendar.current
        sessions.removeAll { session in
            calendar.isDate(session.startTime, inSameDayAs: date)
        }
        saveSessions()
    }
    
    func deleteAllSessions() {
        sessions.removeAll()
        saveSessions()
    }
    
    // MARK: - Rolling Averages
    
    func getRollingAverages() -> [RollingAverage] {
        let periods = [3, 7, 14, 21, 30]
        var rollingAverages: [RollingAverage] = []
        
        for period in periods {
            if let average = calculateRollingAverage(for: period) {
                rollingAverages.append(average)
            }
        }
        
        return rollingAverages
    }
    
    private func calculateRollingAverage(for days: Int) -> RollingAverage? {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return nil
        }
        
        let sessionsInPeriod = sessions.filter { session in
            session.startTime >= startDate && session.startTime <= endDate
        }
        
        guard !sessionsInPeriod.isEmpty else { return nil }
        
        let allReadings = sessionsInPeriod.flatMap { $0.readings }
        guard !allReadings.isEmpty else { return nil }
        
        let systolicValues = allReadings.map { Double($0.systolic) }
        let diastolicValues = allReadings.map { Double($0.diastolic) }
        let heartRateValues = allReadings.compactMap { $0.heartRate }.map { Double($0) }
        
        let avgSystolic = systolicValues.reduce(0, +) / Double(systolicValues.count)
        let avgDiastolic = diastolicValues.reduce(0, +) / Double(diastolicValues.count)
        let avgHeartRate = heartRateValues.isEmpty ? nil : heartRateValues.reduce(0, +) / Double(heartRateValues.count)
        
        return RollingAverage(
            period: days,
            averageSystolic: avgSystolic,
            averageDiastolic: avgDiastolic,
            averageHeartRate: avgHeartRate,
            readingCount: allReadings.count,
            sessionCount: sessionsInPeriod.count,
            startDate: startDate,
            endDate: endDate
        )
    }
    
    // MARK: - Data Persistence
    
    private func saveSessions() {
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: sessionsKey)
            
            // Auto-sync to Firebase if user is authenticated
            if authService.isAuthenticated {
                syncToFirebase()
            }
        } catch {
            print("Error saving sessions: \(error)")
        }
    }
    
    private func loadSessions() {
        guard let data = userDefaults.data(forKey: sessionsKey) else { return }
        
        do {
            sessions = try JSONDecoder().decode([BPSession].self, from: data)
        } catch {
            print("Error loading sessions: \(error)")
            sessions = []
        }
    }
    
    // MARK: - Fitness Session Management
    
    func addExerciseSession(_ exerciseType: ExerciseType) -> Bool {
        let exerciseSession = ExerciseSession(exerciseType: exerciseType)
        currentFitnessSession.addExerciseSession(exerciseSession)
        return true
    }
    
    func loadPreBuiltWorkout(_ workout: PreBuiltWorkout) -> Bool {
        // Clear current session but don't start it yet
        currentFitnessSession = FitnessSession()
        
        // Add all exercises from the workout
        for workoutExercise in workout.exercises {
            let exerciseSession = ExerciseSession(exerciseType: workoutExercise.exerciseType)
            currentFitnessSession.addExerciseSession(exerciseSession)
        }
        
        return true
    }
    
    func addExerciseSet(to exerciseIndex: Int, set: ExerciseSet) -> Bool {
        print("=== BPDataManager addExerciseSet ===")
        print("Exercise Index: \(exerciseIndex)")
        print("Current fitness session exercise count: \(currentFitnessSession.exerciseSessions.count)")
        print("Set being added: \(set)")
        print("Set valid: \(set.isValid)")
        
        guard exerciseIndex >= 0 && exerciseIndex < currentFitnessSession.exerciseSessions.count else {
            print("Invalid exercise index")
            return false
        }
        
        guard set.isValid else { 
            print("Set is not valid")
            return false 
        }
        
        print("Before adding set - exercise has \(currentFitnessSession.exerciseSessions[exerciseIndex].sets.count) sets")
        currentFitnessSession.exerciseSessions[exerciseIndex].addSet(set)
        print("After adding set - exercise has \(currentFitnessSession.exerciseSessions[exerciseIndex].sets.count) sets")
        print("=== End BPDataManager addExerciseSet ===")
        return true
    }
    
    func removeExerciseSet(from exerciseIndex: Int, at setIndex: Int) {
        guard exerciseIndex >= 0 && exerciseIndex < currentFitnessSession.exerciseSessions.count else { return }
        currentFitnessSession.exerciseSessions[exerciseIndex].removeSet(at: setIndex)
    }
    
    func removeExerciseSession(at index: Int) {
        currentFitnessSession.removeExerciseSession(at: index)
    }
    
    func completeExerciseSession(at index: Int) {
        guard index >= 0 && index < currentFitnessSession.exerciseSessions.count else { return }
        currentFitnessSession.exerciseSessions[index].complete()
    }
    
    func startFitnessSession() {
        currentFitnessSession.start()
    }
    
    func pauseFitnessSession() {
        currentFitnessSession.pause()
    }
    
    func resumeFitnessSession() {
        currentFitnessSession.resume()
    }
    
    func stopFitnessSession() {
        currentFitnessSession.complete()
    }
    
    func saveCurrentFitnessSession() {
        print("=== SAVING CURRENT FITNESS SESSION ===")
        print("Current session exercise count: \(currentFitnessSession.exerciseSessions.count)")
        for (index, exercise) in currentFitnessSession.exerciseSessions.enumerated() {
            print("  Exercise \(index) (\(exercise.exerciseType.rawValue)): \(exercise.sets.count) sets")
            for (setIndex, set) in exercise.sets.enumerated() {
                print("    Set \(setIndex): reps=\(set.reps ?? 0), weight=\(set.weight ?? 0)")
            }
        }
        
        guard !currentFitnessSession.exerciseSessions.isEmpty else { 
            print("No exercises to save, returning")
            return 
        }
        
        // Complete the session and prepare data on background queue
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Complete the session on background thread
            self.currentFitnessSession.complete()
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.fitnessSessions.insert(self.currentFitnessSession, at: 0)
                self.saveFitnessSessions()
                self.currentFitnessSession = FitnessSession()
                print("=== END SAVING CURRENT FITNESS SESSION ===")
                
                // Trigger Firebase sync after UI updates are complete
                if self.authService.isAuthenticated {
                    print("User is authenticated, syncing to Firebase...")
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.syncToFirebase()
                    }
                } else {
                    print("User is NOT authenticated, skipping Firebase sync")
                }
            }
        }
    }
    
    // Add this function to collect sets from UI and add them to current session
    func addSetsToCurrentSession(exerciseIndex: Int, sets: [ExerciseSet]) {
        guard exerciseIndex >= 0 && exerciseIndex < currentFitnessSession.exerciseSessions.count else {
            print("Invalid exercise index for adding sets")
            return
        }
        
        print("Adding \(sets.count) sets to exercise \(exerciseIndex)")
        for set in sets {
            currentFitnessSession.exerciseSessions[exerciseIndex].addSet(set)
        }
    }
    
    // Save current session to Firestore without closing the session
    func saveCurrentSessionToFirestore() {
        guard !currentFitnessSession.exerciseSessions.isEmpty else {
            print("No exercises to save to Firestore")
            return
        }
        
        print("=== SAVING CURRENT SESSION TO FIRESTORE ===")
        print("Current session exercise count: \(currentFitnessSession.exerciseSessions.count)")
        for (index, exercise) in currentFitnessSession.exerciseSessions.enumerated() {
            print("  Exercise \(index) (\(exercise.exerciseType.rawValue)): \(exercise.sets.count) sets")
            for (setIndex, set) in exercise.sets.enumerated() {
                print("    Set \(setIndex): reps=\(set.reps ?? 0), weight=\(set.weight ?? 0)")
            }
        }
        
        // Create a temporary session for saving (don't modify the current one)
        var tempSession = currentFitnessSession
        tempSession.complete()
        
        // Save to Firestore without adding to the main sessions array
        firestoreService.saveFitnessSessions([tempSession]) { result in
            switch result {
            case .success:
                print("Successfully saved current session to Firestore")
            case .failure(let error):
                print("Failed to save current session to Firestore: \(error)")
            }
        }
        
        print("=== END SAVING CURRENT SESSION TO FIRESTORE ===")
    }
    
    func clearCurrentFitnessSession() {
        currentFitnessSession = FitnessSession()
    }
    
    func toggleWorkoutFavorite(_ workout: FitnessSession) {
        if let index = fitnessSessions.firstIndex(where: { $0.id == workout.id }) {
            fitnessSessions[index].isFavorite.toggle()
            saveFitnessSessions()
        }
    }
    
    func clearWorkoutTemplate() {
        // Clear all exercises from current session
        currentFitnessSession.exerciseSessions.removeAll()
    }
    
    // MARK: - Custom Workout Management
    
    func saveCustomWorkout(_ workout: CustomWorkout) {
        customWorkouts.append(workout)
        saveCustomWorkouts()
        
        // Save to Firestore
        firestoreService.saveCustomWorkout(workout) { result in
            switch result {
            case .success:
                print("Custom workout saved to Firestore successfully")
            case .failure(let error):
                print("Error saving custom workout to Firestore: \(error)")
            }
        }
    }
    
    func updateCustomWorkout(_ workout: CustomWorkout) {
        if let index = customWorkouts.firstIndex(where: { $0.id == workout.id }) {
            customWorkouts[index] = workout
            saveCustomWorkouts()
            
            // Update in Firestore
            firestoreService.updateCustomWorkout(workout) { result in
                switch result {
                case .success:
                    print("Custom workout updated in Firestore successfully")
                case .failure(let error):
                    print("Error updating custom workout in Firestore: \(error)")
                }
            }
        }
    }
    
    func deleteCustomWorkout(_ workout: CustomWorkout) {
        customWorkouts.removeAll { $0.id == workout.id }
        saveCustomWorkouts()
        
        // Delete from Firestore
        firestoreService.deleteCustomWorkout(workout) { result in
            switch result {
            case .success:
                print("Custom workout deleted from Firestore successfully")
            case .failure(let error):
                print("Error deleting custom workout from Firestore: \(error)")
            }
        }
    }
    
    func toggleCustomWorkoutFavorite(_ workout: CustomWorkout) {
        if let index = customWorkouts.firstIndex(where: { $0.id == workout.id }) {
            customWorkouts[index].isFavorite.toggle()
            saveCustomWorkouts()
        }
    }
    
    func loadCustomWorkout(_ workout: CustomWorkout) {
        // Clear current session if it has exercises
        if !currentFitnessSession.exerciseSessions.isEmpty {
            saveCurrentFitnessSession()
        }
        
        // Clear current session
        clearCurrentFitnessSession()
        
        // Add exercises from custom workout
        for workoutExercise in workout.exercises {
            _ = addExerciseSession(workoutExercise.exerciseType)
        }
        
        // Update use count and last used
        if let index = customWorkouts.firstIndex(where: { $0.id == workout.id }) {
            customWorkouts[index].useCount += 1
            customWorkouts[index].lastUsed = Date()
            saveCustomWorkouts()
        }
    }
    
    private func saveCustomWorkouts() {
        do {
            let data = try JSONEncoder().encode(customWorkouts)
            userDefaults.set(data, forKey: customWorkoutsKey)
        } catch {
            print("Error saving custom workouts: \(error)")
        }
    }
    
    private func loadCustomWorkouts() {
        guard let data = userDefaults.data(forKey: customWorkoutsKey) else { return }
        
        do {
            customWorkouts = try JSONDecoder().decode([CustomWorkout].self, from: data)
        } catch {
            print("Error loading custom workouts: \(error)")
            customWorkouts = []
        }
    }
    
    func loadCustomWorkoutsFromFirestore() {
        firestoreService.loadCustomWorkouts { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let workouts):
                    self?.customWorkouts = workouts
                    self?.saveCustomWorkouts() // Save to local storage as backup
                case .failure(let error):
                    print("Error loading custom workouts from Firestore: \(error)")
                    // Fall back to local storage
                    self?.loadCustomWorkouts()
                }
            }
        }
    }
    
    // MARK: - Nutrition Management
    
    func addNutritionEntry(_ entry: NutritionEntry) {
        nutritionEntries.append(entry)
        saveNutritionEntries()
    }
    
    func updateNutritionEntry(_ entry: NutritionEntry) {
        if let index = nutritionEntries.firstIndex(where: { $0.id == entry.id }) {
            nutritionEntries[index] = entry
            saveNutritionEntries()
        }
    }
    
    func deleteNutritionEntry(_ entry: NutritionEntry) {
        nutritionEntries.removeAll { $0.id == entry.id }
        saveNutritionEntries()
    }
    
    func updateNutritionGoals(_ goals: NutritionGoals) {
        nutritionGoals = goals
        saveNutritionGoals()
    }
    
    private func saveNutritionEntries() {
        do {
            let data = try JSONEncoder().encode(nutritionEntries)
            userDefaults.set(data, forKey: nutritionEntriesKey)
        } catch {
            print("Error saving nutrition entries: \(error)")
        }
    }
    
    private func loadNutritionEntries() {
        guard let data = userDefaults.data(forKey: nutritionEntriesKey) else { return }
        
        do {
            nutritionEntries = try JSONDecoder().decode([NutritionEntry].self, from: data)
        } catch {
            print("Error loading nutrition entries: \(error)")
            nutritionEntries = []
        }
    }
    
    private func saveNutritionGoals() {
        do {
            let data = try JSONEncoder().encode(nutritionGoals)
            userDefaults.set(data, forKey: nutritionGoalsKey)
        } catch {
            print("Error saving nutrition goals: \(error)")
        }
    }
    
    private func loadNutritionGoals() {
        guard let data = userDefaults.data(forKey: nutritionGoalsKey) else { return }
        
        do {
            nutritionGoals = try JSONDecoder().decode(NutritionGoals.self, from: data)
        } catch {
            print("Error loading nutrition goals: \(error)")
            nutritionGoals = NutritionGoals()
        }
    }
    
    // MARK: - Fitness Data Analysis
    
    func getFitnessTrends(for exerciseType: ExerciseType, timeRange: TimeRange) -> [FitnessTrendData] {
        let calendar = Calendar.current
        let now = Date()
        
        let cutoffDate: Date
        switch timeRange {
        case .week:
            cutoffDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            cutoffDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            cutoffDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        let filteredSessions = fitnessSessions.filter { $0.startTime >= cutoffDate }
        let exerciseSessions = filteredSessions.flatMap { $0.exerciseSessions }.filter { $0.exerciseType == exerciseType }
        
        return exerciseSessions.map { session in
            FitnessTrendData(
                date: session.startTime,
                totalReps: session.totalReps,
                averageWeight: session.averageWeight ?? 0,
                maxWeight: session.maxWeight ?? 0,
                totalTime: session.totalTime,
                sets: session.sets.count
            )
        }.sorted { $0.date < $1.date }
    }
    
    func getFitnessTrendAnalysis(for exerciseType: ExerciseType, timeRange: TimeRange) -> FitnessTrendAnalysis {
        let trends = getFitnessTrends(for: exerciseType, timeRange: timeRange)
        
        guard trends.count >= 2 else {
            return FitnessTrendAnalysis(
                overallTrend: .stable,
                weightChange: 0,
                averageWeight: trends.first?.averageWeight ?? 0,
                maxWeight: trends.first?.maxWeight ?? 0,
                totalSessions: trends.count,
                improvementPercentage: 0
            )
        }
        
        let firstWeight = trends.first?.averageWeight ?? 0
        let lastWeight = trends.last?.averageWeight ?? 0
        let weightChange = lastWeight - firstWeight
        
        let overallTrend: WeightTrend
        if weightChange > 5 {
            overallTrend = .increasing
        } else if weightChange < -5 {
            overallTrend = .decreasing
        } else {
            overallTrend = .stable
        }
        
        let averageWeight = trends.map { $0.averageWeight }.reduce(0, +) / Double(trends.count)
        let maxWeight = trends.map { $0.maxWeight }.max() ?? 0
        
        let improvementPercentage = firstWeight > 0 ? (weightChange / firstWeight) * 100 : 0
        
        return FitnessTrendAnalysis(
            overallTrend: overallTrend,
            weightChange: weightChange,
            averageWeight: averageWeight,
            maxWeight: maxWeight,
            totalSessions: trends.count,
            improvementPercentage: improvementPercentage
        )
    }
    
    func getExerciseStats(for exerciseType: ExerciseType) -> ExerciseStats {
        let allSessions = fitnessSessions.flatMap { $0.exerciseSessions }.filter { $0.exerciseType == exerciseType }
        
        let totalSessions = allSessions.count
        let totalSets = allSessions.reduce(0) { $0 + $1.sets.count }
        let totalReps = allSessions.reduce(0) { $0 + $1.totalReps }
        let totalTime = allSessions.reduce(0) { $0 + $1.totalTime }
        
        let weights = allSessions.compactMap { $0.maxWeight }
        let maxWeight = weights.max() ?? 0
        let averageWeight = weights.isEmpty ? 0 : weights.reduce(0, +) / Double(weights.count)
        
        return ExerciseStats(
            exerciseType: exerciseType,
            totalSessions: totalSessions,
            totalSets: totalSets,
            totalReps: totalReps,
            totalTime: totalTime,
            maxWeight: maxWeight,
            averageWeight: averageWeight
        )
    }
    
    // MARK: - Fitness Data Persistence
    
    private func saveFitnessSessions() {
        print("=== SAVING FITNESS SESSIONS ===")
        print("Total fitness sessions: \(fitnessSessions.count)")
        for (index, session) in fitnessSessions.enumerated() {
            print("Session \(index): \(session.exerciseSessions.count) exercises")
            for (exIndex, exercise) in session.exerciseSessions.enumerated() {
                print("  Exercise \(exIndex) (\(exercise.exerciseType.rawValue)): \(exercise.sets.count) sets")
                for (setIndex, set) in exercise.sets.enumerated() {
                    print("    Set \(setIndex): reps=\(set.reps ?? 0), weight=\(set.weight ?? 0), time=\(set.time ?? 0)")
                }
            }
        }
        print("=== END SAVING FITNESS SESSIONS ===")
        
        do {
            let data = try JSONEncoder().encode(fitnessSessions)
            userDefaults.set(data, forKey: fitnessSessionsKey)
            
            // Note: Firebase sync is handled separately to avoid race conditions
        } catch {
            print("Error saving fitness sessions: \(error)")
        }
    }
    
    private func loadFitnessSessions() {
        guard let data = userDefaults.data(forKey: fitnessSessionsKey) else { return }
        
        do {
            fitnessSessions = try JSONDecoder().decode([FitnessSession].self, from: data)
        } catch {
            print("Error loading fitness sessions: \(error)")
            fitnessSessions = []
        }
    }
    
    // MARK: - Firebase Sync
    
    func syncToFirebase() {
        print("=== SYNC TO FIREBASE CALLED ===")
        print("Auth service is authenticated: \(authService.isAuthenticated)")
        print("Current user: \(authService.currentUser?.uid ?? "nil")")
        
        guard authService.isAuthenticated else { 
            print("Cannot sync to Firebase: No authenticated user")
            return 
        }
        
        // Prevent duplicate sync calls
        guard !isSyncing else {
            print("Sync already in progress, skipping duplicate call")
            return
        }
        
        // Set syncing state on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isSyncing = true
            self.syncError = nil
        }
        
        // Capture data on main thread first to avoid accessing @Published properties from background
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Create or update user profile
            let profile = UserProfile(
                id: self.authService.currentUser?.uid ?? "",
                email: self.authService.currentUser?.email ?? "",
                displayName: self.authService.currentUser?.displayName,
                photoURL: self.authService.currentUser?.photoURL?.absoluteString
            )
            
            // Add health metrics with correct data types
            let healthData = self.healthMetrics.map { metric in
                let dataType: HealthDataType
                switch metric.type {
                case .weight: dataType = .weight
                case .bloodPressure: dataType = .bloodPressureSession
                case .bloodSugar: dataType = .bloodSugar
                case .heartRate: dataType = .heartRate
                }
                
                return UnifiedHealthData(
                    id: metric.id,
                    dataType: dataType,
                    metricType: metric.type,
                    value: metric.value,
                    unit: metric.type.unit,
                    timestamp: metric.timestamp
                )
            }
            
            // Add BP sessions
            let bpData = self.sessions.map { session in
                UnifiedHealthData(
                    id: session.id,
                    dataType: .bloodPressureSession,
                    bpSession: session,
                    timestamp: session.startTime
                )
            }
            
            // Add fitness sessions
            let fitnessData = self.fitnessSessions.map { session in
                UnifiedHealthData(
                    id: session.id,
                    dataType: .fitnessSession,
                    fitnessSession: session,
                    timestamp: session.startTime
                )
            }
            
            // Convert all data to unified structure
            let allHealthData: [UnifiedHealthData] = healthData + bpData + fitnessData
            
            // Now run the Firebase operations on background queue
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else { return }
                
                // Save all unified data
                print("Saving \(allHealthData.count) health data items to Firestore...")
                self.firestoreService.saveHealthData(allHealthData) { result in
                    DispatchQueue.main.async {
                        self.isSyncing = false
                        
                        switch result {
                        case .success:
                            print("Successfully synced all data to Firebase using unified structure")
                            self.syncError = nil
                        case .failure(let error):
                            print("Error syncing to Firebase: \(error)")
                            self.syncError = error.localizedDescription
                        }
                    }
                }
                
                // Also save user profile separately
                self.firestoreService.saveUserProfile(profile)
            }
        }
    }
    
    func loadFromFirebase() {
        guard authService.isAuthenticated else { return }
        
        isSyncing = true
        syncError = nil
        
        // Run sync on background queue to prevent UI blocking
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Load all health data using unified structure
            self?.firestoreService.loadHealthData { result in
                DispatchQueue.main.async {
                    self?.isSyncing = false
                    
                    switch result {
                    case .success(let healthData):
                        // Separate data by type
                        var bpSessions: [BPSession] = []
                        var fitnessSessions: [FitnessSession] = []
                        var healthMetrics: [HealthMetric] = []
                        
                        for data in healthData {
                            switch data.dataType {
                            case .bloodPressureSession:
                                if let session = data.bpSession {
                                    bpSessions.append(session)
                                }
                            case .fitnessSession:
                                if let session = data.fitnessSession {
                                    fitnessSessions.append(session)
                                }
                            case .weight, .bloodSugar, .heartRate:
                                if let metricType = data.metricType,
                                   let value = data.value {
                                    let metric = HealthMetric(
                                        type: metricType,
                                        value: value,
                                        timestamp: data.timestamp
                                    )
                                    healthMetrics.append(metric)
                                }
                            default:
                                break
                            }
                        }
                        
                        // Update local data
                        self?.sessions = bpSessions
                        self?.fitnessSessions = fitnessSessions
                        self?.healthMetrics = healthMetrics
                        
                        // Save to local storage
                        self?.saveSessions()
                        self?.saveFitnessSessions()
                        self?.saveHealthMetrics()
                        
                        print("Successfully loaded all data from Firebase using unified structure")
                        print("- BP Sessions: \(bpSessions.count)")
                        print("- Fitness Sessions: \(fitnessSessions.count)")
                        print("- Health Metrics: \(healthMetrics.count)")
                        
                    case .failure(let error):
                        self?.syncError = error.localizedDescription
                        print("Error loading from Firebase: \(error)")
                        
                        // Fallback to local data if Firebase fails
                        print("Falling back to local data...")
                        self?.loadSessions()
                        self?.loadFitnessSessions()
                        self?.loadHealthMetrics()
                    }
                }
            }
            
            // Also load user profile
            self?.firestoreService.loadUserProfile { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profile):
                        self?.userProfile = profile
                    case .failure(let error):
                        print("Error loading user profile: \(error)")
                    }
                }
            }
        }
    }
    
    func uploadProfileImage(_ image: UIImage) {
        storageService.uploadProfileImage(image) { [weak self] result in
            switch result {
            case .success(let urlString):
                // Update user profile with new photo URL
                self?.authService.updateProfile(displayName: nil, photoURL: URL(string: urlString)) { _ in }
            case .failure(let error):
                self?.syncError = error.localizedDescription
            }
        }
    }
    
    func uploadWorkoutImage(_ image: UIImage, workoutID: String) {
        storageService.uploadWorkoutImage(image, workoutID: workoutID) { [weak self] result in
            switch result {
            case .success(let urlString):
                print("Workout image uploaded: \(urlString)")
            case .failure(let error):
                self?.syncError = error.localizedDescription
            }
        }
    }
    
    func signOut() {
        authService.signOut()
    }
    
    func createDataBackup() {
        let backupData = DataBackup(
            bpSessions: sessions,
            fitnessSessions: fitnessSessions,
            userProfile: userProfile,
            createdAt: Date()
        )
        
        do {
            let data = try JSONEncoder().encode(backupData)
            storageService.uploadDataBackup(data) { [weak self] result in
                switch result {
                case .success(let urlString):
                    print("Backup created: \(urlString)")
                case .failure(let error):
                    self?.syncError = error.localizedDescription
                }
            }
        } catch {
            syncError = "Failed to create backup: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Validation
    
    func isValidReading(systolic: Int, diastolic: Int, heartRate: Int? = nil) -> Bool {
        let reading = BloodPressureReading(systolic: systolic, diastolic: diastolic, heartRate: heartRate)
        return reading.isValid
    }
}

// MARK: - Fitness Trend Data

struct FitnessTrendData: Identifiable {
    let id = UUID()
    let date: Date
    let totalReps: Int
    let averageWeight: Double
    let maxWeight: Double
    let totalTime: TimeInterval
    let sets: Int
    
    var weightTrend: WeightTrend {
        if averageWeight > 0 {
            return .increasing // This will be calculated in the view
        } else {
            return .stable
        }
    }
}

enum WeightTrend {
    case increasing
    case decreasing
    case stable
    
    var icon: String {
        switch self {
        case .increasing:
            return "arrow.up.circle.fill"
        case .decreasing:
            return "arrow.down.circle.fill"
        case .stable:
            return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing:
            return .green
        case .decreasing:
            return .red
        case .stable:
            return .orange
        }
    }
    
    var description: String {
        switch self {
        case .increasing:
            return "Weight Increasing"
        case .decreasing:
            return "Weight Decreasing"
        case .stable:
            return "Weight Stable"
        }
    }
}

struct FitnessTrendAnalysis {
    let overallTrend: WeightTrend
    let weightChange: Double
    let averageWeight: Double
    let maxWeight: Double
    let totalSessions: Int
    let improvementPercentage: Double
    
    var weightChangeString: String {
        if weightChange > 0 {
            return "+\(String(format: "%.1f", weightChange)) lbs"
        } else if weightChange < 0 {
            return "\(String(format: "%.1f", weightChange)) lbs"
        } else {
            return "No change"
        }
    }
    
    var improvementString: String {
        if improvementPercentage > 0 {
            return "+\(String(format: "%.1f", improvementPercentage))%"
        } else if improvementPercentage < 0 {
            return "\(String(format: "%.1f", improvementPercentage))%"
        } else {
            return "0%"
        }
    }
}

// MARK: - Exercise Stats

struct ExerciseStats {
    let exerciseType: ExerciseType
    let totalSessions: Int
    let totalSets: Int
    let totalReps: Int
    let totalTime: TimeInterval
    let maxWeight: Double
    let averageWeight: Double
}

// MARK: - Time Range Enum for Fitness

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case year = "Year"
}

// MARK: - Data Backup Model

struct DataBackup: Codable {
    let bpSessions: [BPSession]
    let fitnessSessions: [FitnessSession]
    let userProfile: UserProfile?
    let createdAt: Date
    let version: String = "1.0"
}

// MARK: - Health Trend

enum HealthTrend {
    case increasing
    case decreasing
    case stable
    
    var icon: String {
        switch self {
        case .increasing: return "arrow.up.circle.fill"
        case .decreasing: return "arrow.down.circle.fill"
        case .stable: return "minus.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing: return .green
        case .decreasing: return .red
        case .stable: return .orange
        }
    }
    
    var description: String {
        switch self {
        case .increasing: return "Trending Up"
        case .decreasing: return "Trending Down"
        case .stable: return "Stable"
        }
    }
}
