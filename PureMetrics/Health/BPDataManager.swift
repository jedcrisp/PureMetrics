import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore

// MARK: - Migration Support

struct OldNutritionEntry: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let sodium: Double
    let sugar: Double
    let fiber: Double
    let cholesterol: Double
    let water: Double
    let notes: String?
    let label: String?
    
    enum CodingKeys: String, CodingKey {
        case date, calories, protein, carbohydrates, fat, sodium, sugar, fiber, cholesterol, water, notes, label
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
    static let userDidSignOut = Notification.Name("userDidSignOut")
    static let authStateChanged = Notification.Name("authStateChanged")
    static let dataDidSync = Notification.Name("dataDidSync")
    static let syncDidFail = Notification.Name("syncDidFail")
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
    @Published var customNutritionTemplates: [CustomNutritionTemplate] = []
    
    // Health notes storage
    @Published var healthNotes: [HealthNote] = []
    @Published var nutritionGoals: NutritionGoals = NutritionGoals()
    @Published var nutritionLabelManager = NutritionLabelManager()
    
    // Custom exercises storage
    @Published var customExercises: [CustomExercise] = []
    
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
    private let customExercisesKey = "CustomExercises"
    private let lastResetDateKey = "LastNutritionResetDate"
    
    // Firebase services
    private let firestoreService = FirestoreService()
    private let storageService = StorageService()
    private let authService = AuthService()
    
    init() {
        self.currentSession = BPSession()
        self.currentFitnessSession = FitnessSession()
        
        print("Loading local data...")
        
        loadSessions()
        loadFitnessSessions()
        loadHealthMetrics()
        loadCustomWorkouts()
        loadBeginnerWorkouts() // Load beginner workout templates
        loadNutritionEntries()
        loadNutritionGoals()
        loadCustomNutritionTemplates()
        loadCustomExercises()
        
        // Load nutrition goals from Firestore
        loadNutritionGoalsFromFirestore()
        
        // Check for daily reset
        checkAndResetDailyProgress()
        
        print("Local data loaded:")
        print("- BP Sessions: \(sessions.count)")
        print("- Fitness Sessions: \(fitnessSessions.count)")
        print("- Health Metrics: \(healthMetrics.count)")
        print("- Custom Workouts: \(customWorkouts.count)")
        print("- Nutrition Entries: \(nutritionEntries.count)")
        print("- Nutrition Goals: \(nutritionGoals.dailyCalories)")
        
        // Print sample data if available
        if !sessions.isEmpty {
            print("Sample BP Session: \(sessions.first?.id)")
        }
        if !fitnessSessions.isEmpty {
            print("Sample Fitness Session: \(fitnessSessions.first?.id)")
        }
        
        
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
        print("Current sync state - isSyncing: \(isSyncing), hasSyncedForCurrentSession: \(hasSyncedForCurrentSession)")
        print("Auth service state - isAuthenticated: \(authService.isAuthenticated), currentUser: \(authService.currentUser?.uid ?? "nil")")
        
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
            self?.loadHealthNotesFromFirestore()
            // Also reload custom nutrition templates when user signs in
            self?.loadCustomNutritionTemplates()
            // Load nutrition goals from Firestore
            self?.loadNutritionGoalsFromFirestore()
            // Load nutrition entries from Firestore
            self?.loadNutritionEntriesFromFirestore()
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
        print("Systolic: \(systolic), Diastolic: \(diastolic), Heart Rate: \(heartRate ?? 0)")
        
        let reading = BloodPressureReading(systolic: systolic, diastolic: diastolic, heartRate: heartRate, timestamp: timestamp)
        guard reading.isValid else {
            print("Reading is not valid")
            return false
        }
        
        print("Reading is valid, creating session...")
        
        // Create a single-reading session and save it immediately
        var session = BPSession(startTime: timestamp ?? Date())
        session.addReading(reading)
        session.complete()
        
        print("Session created with \(session.readings.count) readings")
        
        // Add to sessions array
        sessions.insert(session, at: 0)
        
        print("Session added to array. Total sessions: \(sessions.count)")
        
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
    
    func loadHealthMetrics() {
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
        print("Saving \(sessions.count) sessions to UserDefaults")
        
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: sessionsKey)
            print("Sessions saved to UserDefaults successfully")
            
            // Auto-sync to Firebase if user is authenticated
            if authService.isAuthenticated {
                print("User is authenticated, syncing to Firebase...")
                syncToFirebase()
            } else {
                print("User is not authenticated, skipping Firebase sync")
            }
        } catch {
            print("Error saving sessions: \(error)")
        }
        
        print("=== END SAVE SESSIONS ===")
    }
    
    func loadSessions() {
        print("=== LOAD SESSIONS CALLED ===")
        
        guard let data = userDefaults.data(forKey: sessionsKey) else { 
            print("No sessions data found in UserDefaults")
            return 
        }
        
        print("Found sessions data in UserDefaults, decoding...")
        
        do {
            sessions = try JSONDecoder().decode([BPSession].self, from: data)
            print("Successfully loaded \(sessions.count) sessions from UserDefaults")
        } catch {
            print("Error loading sessions: \(error)")
            sessions = []
        }
        
        print("=== END LOAD SESSIONS ===")
    }
    
    // MARK: - Fitness Session Management
    
    func addExerciseSession(_ exerciseType: ExerciseType) -> Bool {
        let exerciseSession = ExerciseSession(exerciseType: exerciseType)
        currentFitnessSession.addExerciseSession(exerciseSession)
        return true
    }
    
    func addCustomExerciseSession(_ customExercise: CustomExercise) -> Bool {
        // Create a new ExerciseSession with the custom exercise
        let exerciseSession = ExerciseSession(customExercise: customExercise)
        currentFitnessSession.addExerciseSession(exerciseSession)
        print("Successfully added custom exercise '\(customExercise.name)' to fitness session")
        return true
    }
    
    func loadPreBuiltWorkout(_ workout: PreBuiltWorkout) -> Bool {
        // Clear current session but don't start it yet
        currentFitnessSession = FitnessSession()
        
        // Add all exercises from the workout
        for workoutExercise in workout.exercises {
            // Only add built-in exercises (custom exercises can't be converted to ExerciseSession)
            if let exerciseType = workoutExercise.exerciseType {
                let exerciseSession = ExerciseSession(exerciseType: exerciseType)
                currentFitnessSession.addExerciseSession(exerciseSession)
            }
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
            print("  Exercise \(index) (\(exercise.exerciseName)): \(exercise.sets.count) sets")
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
            print("  Exercise \(index) (\(exercise.exerciseName)): \(exercise.sets.count) sets")
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
    
    func deleteSetFromWorkout(workoutId: UUID, exerciseIndex: Int, setIndex: Int) {
        guard let workoutIndex = fitnessSessions.firstIndex(where: { $0.id == workoutId }) else { return }
        guard exerciseIndex >= 0 && exerciseIndex < fitnessSessions[workoutIndex].exerciseSessions.count else { return }
        guard setIndex >= 0 && setIndex < fitnessSessions[workoutIndex].exerciseSessions[exerciseIndex].sets.count else { return }
        
        // Create a mutable copy of the workout
        var updatedWorkout = fitnessSessions[workoutIndex]
        updatedWorkout.exerciseSessions[exerciseIndex].removeSet(at: setIndex)
        fitnessSessions[workoutIndex] = updatedWorkout
        
        saveFitnessSessions()
        
        // Update in Firestore
        firestoreService.updateFitnessSession(updatedWorkout) { result in
            switch result {
            case .success:
                print("Successfully updated workout in Firestore after deleting set")
            case .failure(let error):
                print("Error updating workout in Firestore: \(error)")
            }
        }
    }
    
    func deleteExerciseFromWorkout(workoutId: UUID, exerciseIndex: Int) {
        guard let workoutIndex = fitnessSessions.firstIndex(where: { $0.id == workoutId }) else { return }
        guard exerciseIndex >= 0 && exerciseIndex < fitnessSessions[workoutIndex].exerciseSessions.count else { return }
        
        // Create a mutable copy of the workout
        var updatedWorkout = fitnessSessions[workoutIndex]
        updatedWorkout.exerciseSessions.remove(at: exerciseIndex)
        fitnessSessions[workoutIndex] = updatedWorkout
        
        saveFitnessSessions()
        
        // Update in Firestore
        firestoreService.updateFitnessSession(updatedWorkout) { result in
            switch result {
            case .success:
                print("Successfully updated workout in Firestore after deleting exercise")
            case .failure(let error):
                print("Error updating workout in Firestore: \(error)")
            }
        }
    }
    
    func clearAllSetsFromExercise(workoutId: UUID, exerciseIndex: Int) {
        guard let workoutIndex = fitnessSessions.firstIndex(where: { $0.id == workoutId }) else { return }
        guard exerciseIndex >= 0 && exerciseIndex < fitnessSessions[workoutIndex].exerciseSessions.count else { return }
        
        // Create a mutable copy of the workout
        var updatedWorkout = fitnessSessions[workoutIndex]
        updatedWorkout.exerciseSessions[exerciseIndex].sets.removeAll()
        fitnessSessions[workoutIndex] = updatedWorkout
        
        saveFitnessSessions()
        
        // Update in Firestore
        firestoreService.updateFitnessSession(updatedWorkout) { result in
            switch result {
            case .success:
                print("Successfully updated workout in Firestore after clearing all sets")
            case .failure(let error):
                print("Error updating workout in Firestore: \(error)")
            }
        }
    }
    
    // MARK: - Edit Individual Sets in Completed Workouts
    
    func updateSetInWorkout(workoutId: UUID, exerciseIndex: Int, setIndex: Int, reps: Int?, weight: Double?, time: Double?) {
        guard let workoutIndex = fitnessSessions.firstIndex(where: { $0.id == workoutId }) else { return }
        guard exerciseIndex >= 0 && exerciseIndex < fitnessSessions[workoutIndex].exerciseSessions.count else { return }
        guard setIndex >= 0 && setIndex < fitnessSessions[workoutIndex].exerciseSessions[exerciseIndex].sets.count else { return }
        
        // Create a mutable copy of the workout
        var updatedWorkout = fitnessSessions[workoutIndex]
        var updatedSet = updatedWorkout.exerciseSessions[exerciseIndex].sets[setIndex]
        
        // Update the set values
        updatedSet.reps = reps
        updatedSet.weight = weight
        updatedSet.time = time
        
        updatedWorkout.exerciseSessions[exerciseIndex].sets[setIndex] = updatedSet
        fitnessSessions[workoutIndex] = updatedWorkout
        
        saveFitnessSessions()
        
        // Update in Firestore
        firestoreService.updateFitnessSession(updatedWorkout) { result in
            switch result {
            case .success:
                print("Successfully updated set in Firestore")
            case .failure(let error):
                print("Error updating set in Firestore: \(error)")
            }
        }
    }
    
    func addSetToCompletedWorkout(workoutId: UUID, exerciseIndex: Int, set: ExerciseSet) {
        guard let workoutIndex = fitnessSessions.firstIndex(where: { $0.id == workoutId }) else { return }
        guard exerciseIndex >= 0 && exerciseIndex < fitnessSessions[workoutIndex].exerciseSessions.count else { return }
        
        // Create a mutable copy of the workout
        var updatedWorkout = fitnessSessions[workoutIndex]
        updatedWorkout.exerciseSessions[exerciseIndex].addSet(set)
        fitnessSessions[workoutIndex] = updatedWorkout
        
        saveFitnessSessions()
        
        // Update in Firestore
        firestoreService.updateFitnessSession(updatedWorkout) { result in
            switch result {
            case .success:
                print("Successfully added set to completed workout in Firestore")
            case .failure(let error):
                print("Error adding set to completed workout in Firestore: \(error)")
            }
        }
    }
    
    func clearWorkoutTemplate() {
        // Clear all exercises from current session
        currentFitnessSession = FitnessSession()
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
        
        // Add exercises from custom workout with pre-populated sets
        for workoutExercise in workout.exercises {
            // Only add built-in exercises (custom exercises can't be converted to ExerciseSession)
            guard let exerciseType = workoutExercise.exerciseType else { continue }
            var exerciseSession = ExerciseSession(exerciseType: exerciseType)
            
            // Pre-populate sets if planned sets are available
            if let plannedSets = workoutExercise.plannedSets {
                for plannedSet in plannedSets {
                    let exerciseSet = ExerciseSet(
                        reps: plannedSet.reps,
                        weight: plannedSet.weight,
                        time: plannedSet.time,
                        distance: plannedSet.distance,
                        timestamp: Date()
                    )
                    exerciseSession.addSet(exerciseSet)
                }
            }
            
            currentFitnessSession.addExerciseSession(exerciseSession)
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
    
    // MARK: - Beginner Workout Templates
    
    func loadBeginnerWorkouts() {
        // Check if beginner workouts are already loaded
        let hasBeginnerWorkouts = customWorkouts.contains { workout in
            workout.name.contains("Beginner")
        }
        
        if !hasBeginnerWorkouts {
            // Add all beginner workouts
            customWorkouts.append(contentsOf: BeginnerUpperBodyWorkouts.allWorkouts)
            saveCustomWorkouts()
            print("Loaded beginner upper body workout templates")
        }
    }
    
    // MARK: - Nutrition Management
    
    func addNutritionEntry(_ entry: NutritionEntry) {
        nutritionEntries.append(entry)
        saveNutritionEntries()
        
        // Also save to Firestore
        firestoreService.saveNutritionEntry(entry) { result in
            switch result {
            case .success:
                print("Successfully saved nutrition entry to Firestore")
            case .failure(let error):
                print("Error saving nutrition entry to Firestore: \(error)")
            }
        }
    }
    
    func updateNutritionEntry(_ entry: NutritionEntry) {
        if let index = nutritionEntries.firstIndex(where: { $0.id == entry.id }) {
            nutritionEntries[index] = entry
            saveNutritionEntries()
            
            // Also update in Firestore
            firestoreService.saveNutritionEntry(entry) { result in
                switch result {
                case .success:
                    print("Successfully updated nutrition entry in Firestore")
                case .failure(let error):
                    print("Error updating nutrition entry in Firestore: \(error)")
                }
            }
        }
    }
    
    func deleteNutritionEntry(_ entry: NutritionEntry) {
        nutritionEntries.removeAll { $0.id == entry.id }
        saveNutritionEntries()
        
        // Also delete from Firestore
        firestoreService.deleteNutritionEntry(entry) { result in
            switch result {
            case .success:
                print("Successfully deleted nutrition entry from Firestore")
            case .failure(let error):
                print("Error deleting nutrition entry from Firestore: \(error)")
            }
        }
    }
    
    func clearNutritionDataFromTime(_ time: Date) {
        let calendar = Calendar.current
        let targetHour = calendar.component(.hour, from: time)
        let targetMinute = calendar.component(.minute, from: time)
        
        // Find entries that match the time (within 1 minute tolerance)
        let entriesToDelete = nutritionEntries.filter { entry in
            let entryHour = calendar.component(.hour, from: entry.date)
            let entryMinute = calendar.component(.minute, from: entry.date)
            return entryHour == targetHour && abs(entryMinute - targetMinute) <= 1
        }
        
        // Delete each matching entry
        for entry in entriesToDelete {
            deleteNutritionEntry(entry)
        }
        
        print("Cleared \(entriesToDelete.count) nutrition entries from \(targetHour):\(String(format: "%02d", targetMinute))")
    }
    
    func clearAllNutritionData() {
        let allEntries = nutritionEntries
        nutritionEntries.removeAll()
        saveNutritionEntries()
        
        // Also clear from Firestore
        for entry in allEntries {
            firestoreService.deleteNutritionEntry(entry) { result in
                switch result {
                case .success:
                    print("Successfully deleted nutrition entry from Firestore")
                case .failure(let error):
                    print("Error deleting nutrition entry from Firestore: \(error)")
                }
            }
        }
        
        print("Cleared all nutrition data (\(allEntries.count) entries)")
    }
    
    // MARK: - Custom Nutrition Template Management
    
    func addCustomNutritionTemplate(_ template: CustomNutritionTemplate) {
        print("🔍 DEBUG: BPDataManager.addCustomNutritionTemplate called with: \(template.name)")
        customNutritionTemplates.append(template)
        print("🔍 DEBUG: Template added. Total templates now: \(customNutritionTemplates.count)")
        saveCustomNutritionTemplates()
        print("🔍 DEBUG: saveCustomNutritionTemplates called")
    }
    
    func updateCustomNutritionTemplate(_ template: CustomNutritionTemplate) {
        if let index = customNutritionTemplates.firstIndex(where: { $0.id == template.id }) {
            customNutritionTemplates[index] = template
            saveCustomNutritionTemplates()
        }
    }
    
    func deleteCustomNutritionTemplate(_ template: CustomNutritionTemplate) {
        customNutritionTemplates.removeAll { $0.id == template.id }
        saveCustomNutritionTemplates()
    }
    
    func useCustomNutritionTemplate(_ template: CustomNutritionTemplate) {
        // Update last used date
        if let index = customNutritionTemplates.firstIndex(where: { $0.id == template.id }) {
            var updatedTemplate = template
            updatedTemplate = CustomNutritionTemplate(
                name: template.name,
                calories: template.calories,
                protein: template.protein,
                carbohydrates: template.carbohydrates,
                fat: template.fat,
                sodium: template.sodium,
                sugar: template.sugar,
                addedSugar: template.addedSugar,
                fiber: template.fiber,
                cholesterol: template.cholesterol,
                water: template.water,
                servingSize: template.servingSize,
                category: template.category,
                notes: template.notes
            )
            customNutritionTemplates[index] = updatedTemplate
            saveCustomNutritionTemplates()
        }
        
        // Add as nutrition entry
        let entry = template.toNutritionEntry()
        addNutritionEntry(entry)
    }
    
    func getCustomNutritionTemplates(for category: String? = nil) -> [CustomNutritionTemplate] {
        if let category = category {
            return customNutritionTemplates.filter { $0.category == category }
        }
        return customNutritionTemplates
    }
    
    func searchCustomNutritionTemplates(_ searchText: String) -> [CustomNutritionTemplate] {
        if searchText.isEmpty {
            return customNutritionTemplates
        }
        return customNutritionTemplates.filter { template in
            template.name.localizedCaseInsensitiveContains(searchText) ||
            template.category.localizedCaseInsensitiveContains(searchText) ||
            (template.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private func saveCustomNutritionTemplates() {
        print("🔍 DEBUG: saveCustomNutritionTemplates called with \(customNutritionTemplates.count) templates")
        // Save to UserDefaults for offline access
        if let encoded = try? JSONEncoder().encode(customNutritionTemplates) {
            UserDefaults.standard.set(encoded, forKey: "custom_nutrition_templates")
            print("🔍 DEBUG: Templates saved to UserDefaults")
            
            // Verify the save worked
            if let savedData = UserDefaults.standard.data(forKey: "custom_nutrition_templates"),
               let savedTemplates = try? JSONDecoder().decode([CustomNutritionTemplate].self, from: savedData) {
                print("🔍 DEBUG: Verification - \(savedTemplates.count) templates saved to UserDefaults")
            } else {
                print("🔍 DEBUG: Verification failed - could not read back saved templates")
            }
        } else {
            print("🔍 DEBUG: Failed to encode templates for UserDefaults")
        }
        
        // Save to Firestore for sync across devices
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        let templatesRef = db.collection("users").document(userId).collection("customNutritionTemplates")
        
        // Delete all existing templates first
        templatesRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error getting templates: \(error)")
                return
            }
            
            let batch = db.batch()
            for document in snapshot?.documents ?? [] {
                batch.deleteDocument(document.reference)
            }
            
            // Add all current templates
            for template in self.customNutritionTemplates {
                let templateData: [String: Any] = [
                    "name": template.name,
                    "calories": template.calories,
                    "protein": template.protein,
                    "carbohydrates": template.carbohydrates,
                    "fat": template.fat,
                    "sodium": template.sodium,
                    "sugar": template.sugar,
                    "addedSugar": template.addedSugar,
                    "fiber": template.fiber,
                    "cholesterol": template.cholesterol,
                    "water": template.water,
                    "servingSize": template.servingSize,
                    "category": template.category,
                    "notes": template.notes ?? "",
                    "dateCreated": Timestamp(date: template.dateCreated),
                    "lastUsed": template.lastUsed != nil ? Timestamp(date: template.lastUsed!) : NSNull()
                ]
                
                let docRef = templatesRef.document(template.id.uuidString)
                batch.setData(templateData, forDocument: docRef)
            }
            
            batch.commit { error in
                if let error = error {
                    print("Error saving custom nutrition templates: \(error)")
                } else {
                    print("Custom nutrition templates saved to Firestore")
                }
            }
        }
    }
    
    private func loadCustomNutritionTemplates() {
        print("=== LOAD CUSTOM NUTRITION TEMPLATES CALLED ===")
        
        // Load from UserDefaults first (for offline access)
        if let data = UserDefaults.standard.data(forKey: "custom_nutrition_templates"),
           let decoded = try? JSONDecoder().decode([CustomNutritionTemplate].self, from: data) {
            customNutritionTemplates = decoded
            print("Loaded \(customNutritionTemplates.count) templates from UserDefaults")
            for template in customNutritionTemplates {
                print("  - Template: \(template.name) (\(template.servingSize))")
            }
        } else {
            print("No templates found in UserDefaults")
        }
        
        // Load from Firestore for sync across devices
        guard let userId = Auth.auth().currentUser?.uid else { 
            print("No authenticated user, skipping Firestore load")
            return 
        }
        
        print("Loading templates from Firestore for user: \(userId)")
        
        let db = Firestore.firestore()
        let templatesRef = db.collection("users").document(userId).collection("customNutritionTemplates")
        
        templatesRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error loading custom nutrition templates: \(error)")
                return
            }
            
            print("Firestore returned \(snapshot?.documents.count ?? 0) template documents")
            
            var firestoreTemplates: [CustomNutritionTemplate] = []
            
            for document in snapshot?.documents ?? [] {
                let data = document.data()
                
                guard let name = data["name"] as? String,
                      let calories = data["calories"] as? Double,
                      let protein = data["protein"] as? Double,
                      let carbohydrates = data["carbohydrates"] as? Double,
                      let fat = data["fat"] as? Double,
                      let sodium = data["sodium"] as? Double,
                      let sugar = data["sugar"] as? Double,
                      let fiber = data["fiber"] as? Double,
                      let cholesterol = data["cholesterol"] as? Double,
                      let water = data["water"] as? Double,
                      let servingSize = data["servingSize"] as? String,
                      let category = data["category"] as? String else {
                    continue
                }
                
                let addedSugar = data["addedSugar"] as? Double ?? 0
                let notes = data["notes"] as? String
                let dateCreated = (data["dateCreated"] as? Timestamp)?.dateValue() ?? Date()
                let lastUsed = (data["lastUsed"] as? Timestamp)?.dateValue()
                
                let template = CustomNutritionTemplate(
                    name: name,
                    calories: calories,
                    protein: protein,
                    carbohydrates: carbohydrates,
                    fat: fat,
                    sodium: sodium,
                    sugar: sugar,
                    addedSugar: addedSugar,
                    fiber: fiber,
                    cholesterol: cholesterol,
                    water: water,
                    servingSize: servingSize,
                    category: category,
                    notes: notes
                )
                
                firestoreTemplates.append(template)
            }
            
            // Update the templates if we got data from Firestore
            if !firestoreTemplates.isEmpty {
                print("Successfully loaded \(firestoreTemplates.count) templates from Firestore")
                DispatchQueue.main.async {
                    self.customNutritionTemplates = firestoreTemplates
                    // Save to UserDefaults for offline access
                    self.saveCustomNutritionTemplates()
                    print("Updated customNutritionTemplates to \(self.customNutritionTemplates.count) templates")
                }
            } else {
                print("No templates found in Firestore")
            }
        }
    }
    
    func updateNutritionGoals(_ goals: NutritionGoals) {
        nutritionGoals = goals
        saveNutritionGoals()
        
        // Also save to Firestore
        firestoreService.saveNutritionGoals(goals) { result in
            switch result {
            case .success:
                print("Successfully saved nutrition goals to Firestore")
            case .failure(let error):
                print("Error saving nutrition goals to Firestore: \(error)")
            }
        }
    }
    
    func loadNutritionGoalsFromFirestore() {
        firestoreService.loadNutritionGoals { result in
            switch result {
            case .success(let goals):
                DispatchQueue.main.async {
                    self.nutritionGoals = goals
                    self.saveNutritionGoals() // Save to UserDefaults as backup
                    print("Successfully loaded nutrition goals from Firestore")
                }
            case .failure(let error):
                print("Error loading nutrition goals from Firestore: \(error)")
            }
        }
    }
    
    private func checkAndResetDailyProgress() {
        let calendar = Calendar.current
        let today = Date()
        let todayString = calendar.dateInterval(of: .day, for: today)?.start ?? today
        
        if let lastResetDate = userDefaults.object(forKey: lastResetDateKey) as? Date {
            let lastResetString = calendar.dateInterval(of: .day, for: lastResetDate)?.start ?? lastResetDate
            
            // If it's a new day, reset progress
            if !calendar.isDate(todayString, inSameDayAs: lastResetString) {
                print("New day detected - nutrition progress will reset at midnight")
                // The progress bars will automatically reset because they calculate based on today's entries
                userDefaults.set(today, forKey: lastResetDateKey)
            }
        } else {
            // First time running - set today as the reset date
            userDefaults.set(today, forKey: lastResetDateKey)
        }
    }
    
    func loadCustomNutritionTemplatesFromFirestore(completion: @escaping (Result<[CustomNutritionTemplate], Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "BPDataManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])))
            return
        }
        
        let db = Firestore.firestore()
        let templatesRef = db.collection("users").document(userId).collection("customNutritionTemplates")
        
        templatesRef.getDocuments { (snapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            var templates: [CustomNutritionTemplate] = []
            
            for document in snapshot?.documents ?? [] {
                let data = document.data()
                
                guard let name = data["name"] as? String,
                      let calories = data["calories"] as? Double,
                      let protein = data["protein"] as? Double,
                      let carbohydrates = data["carbohydrates"] as? Double,
                      let fat = data["fat"] as? Double,
                      let sodium = data["sodium"] as? Double,
                      let sugar = data["sugar"] as? Double,
                      let fiber = data["fiber"] as? Double,
                      let cholesterol = data["cholesterol"] as? Double,
                      let water = data["water"] as? Double,
                      let servingSize = data["servingSize"] as? String,
                      let category = data["category"] as? String else {
                    continue
                }
                
                let addedSugar = data["addedSugar"] as? Double ?? 0
                let notes = data["notes"] as? String
                let dateCreated = (data["dateCreated"] as? Timestamp)?.dateValue() ?? Date()
                let lastUsed = (data["lastUsed"] as? Timestamp)?.dateValue()
                
                let template = CustomNutritionTemplate(
                    name: name,
                    calories: calories,
                    protein: protein,
                    carbohydrates: carbohydrates,
                    fat: fat,
                    sodium: sodium,
                    sugar: sugar,
                    addedSugar: addedSugar,
                    fiber: fiber,
                    cholesterol: cholesterol,
                    water: water,
                    servingSize: servingSize,
                    category: category,
                    notes: notes
                )
                
                templates.append(template)
            }
            
            completion(.success(templates))
        }
    }
    
    func loadNutritionEntriesFromFirestore() {
        firestoreService.loadNutritionEntries { result in
            switch result {
            case .success(let entries):
                DispatchQueue.main.async {
                    self.nutritionEntries = entries
                    self.saveNutritionEntries() // Save to UserDefaults as backup
                    print("Successfully loaded \(entries.count) nutrition entries from Firestore")
                }
            case .failure(let error):
                print("Error loading nutrition entries from Firestore: \(error)")
                // Fall back to local data
                self.loadNutritionEntries()
            }
        }
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
        print("=== LOAD NUTRITION ENTRIES CALLED ===")
        
        guard let data = userDefaults.data(forKey: nutritionEntriesKey) else { 
            print("No nutrition entries data found in UserDefaults")
            return 
        }
        
        print("Found nutrition entries data in UserDefaults, attempting to decode...")
        
        do {
            nutritionEntries = try JSONDecoder().decode([NutritionEntry].self, from: data)
            print("Successfully loaded \(nutritionEntries.count) nutrition entries with new structure")
        } catch {
            print("Error loading nutrition entries with new structure: \(error)")
            print("Attempting to migrate old nutrition entries...")
            
            // Try to decode with a custom decoder that handles missing addedSugar field
            do {
                let oldEntries = try JSONDecoder().decode([OldNutritionEntry].self, from: data)
                nutritionEntries = oldEntries.map { oldEntry in
                    NutritionEntry(
                        date: oldEntry.date,
                        calories: oldEntry.calories,
                        protein: oldEntry.protein,
                        carbohydrates: oldEntry.carbohydrates,
                        fat: oldEntry.fat,
                        sodium: oldEntry.sodium,
                        sugar: oldEntry.sugar,
                        addedSugar: 0, // Default value for migrated entries
                        fiber: oldEntry.fiber,
                        cholesterol: oldEntry.cholesterol,
                        water: oldEntry.water,
                        notes: oldEntry.notes,
                        label: oldEntry.label
                    )
                }
                print("Successfully migrated \(nutritionEntries.count) nutrition entries")
                saveNutritionEntries() // Save the migrated entries
            } catch {
                print("Migration failed: \(error)")
                nutritionEntries = []
            }
        }
        
        print("Final nutrition entries count: \(nutritionEntries.count)")
        if !nutritionEntries.isEmpty {
            print("Sample entry: \(nutritionEntries.first?.label ?? "No label") - \(nutritionEntries.first?.calories ?? 0) calories")
        }
        print("=== END LOAD NUTRITION ENTRIES ===")
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
    
    // MARK: - Custom Exercise Management
    
    func addCustomExercise(_ exercise: CustomExercise) {
        customExercises.append(exercise)
        saveCustomExercises()
        
        // Also save to Firestore
        firestoreService.saveCustomExercise(exercise) { result in
            switch result {
            case .success:
                print("Successfully saved custom exercise to Firestore")
            case .failure(let error):
                print("Error saving custom exercise to Firestore: \(error)")
            }
        }
    }
    
    func updateCustomExercise(_ exercise: CustomExercise) {
        if let index = customExercises.firstIndex(where: { $0.id == exercise.id }) {
            customExercises[index] = exercise
            saveCustomExercises()
            
            // Also update in Firestore
            firestoreService.saveCustomExercise(exercise) { result in
                switch result {
                case .success:
                    print("Successfully updated custom exercise in Firestore")
                case .failure(let error):
                    print("Error updating custom exercise in Firestore: \(error)")
                }
            }
        }
    }
    
    func deleteCustomExercise(_ exercise: CustomExercise) {
        customExercises.removeAll { $0.id == exercise.id }
        saveCustomExercises()
        
        // Also delete from Firestore
        firestoreService.deleteCustomExercise(exercise) { result in
            switch result {
            case .success:
                print("Successfully deleted custom exercise from Firestore")
            case .failure(let error):
                print("Error deleting custom exercise from Firestore: \(error)")
            }
        }
    }
    
    private func saveCustomExercises() {
        do {
            let data = try JSONEncoder().encode(customExercises)
            userDefaults.set(data, forKey: customExercisesKey)
        } catch {
            print("Error saving custom exercises: \(error)")
        }
    }
    
    private func loadCustomExercises() {
        guard let data = userDefaults.data(forKey: customExercisesKey) else { return }
        
        do {
            customExercises = try JSONDecoder().decode([CustomExercise].self, from: data)
        } catch {
            print("Error loading custom exercises: \(error)")
        }
    }
    
    func loadCustomExercisesFromFirestore() {
        firestoreService.loadCustomExercises { result in
            switch result {
            case .success(let exercises):
                DispatchQueue.main.async {
                    self.customExercises = exercises
                    self.saveCustomExercises() // Save to UserDefaults as backup
                    print("Successfully loaded \(exercises.count) custom exercises from Firestore")
                }
            case .failure(let error):
                print("Error loading custom exercises from Firestore: \(error)")
                // Fallback to local data if Firestore fails
                self.loadCustomExercises()
            }
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
                print("  Exercise \(exIndex) (\(exercise.exerciseName)): \(exercise.sets.count) sets")
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
    
    func loadFitnessSessions() {
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
        print("Firebase app configured: \(FirebaseApp.app() != nil)")
        
        guard authService.isAuthenticated else { 
            print("Cannot sync to Firebase: No authenticated user")
            print("Auth service state - isAuthenticated: \(authService.isAuthenticated), currentUser: \(authService.currentUser?.uid ?? "nil")")
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
                case .bodyFat: dataType = .bodyFat
                case .leanBodyMass: dataType = .leanBodyMass
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
        
        print("=== LOAD FROM FIREBASE CALLED ===")
        print("Auth service is authenticated: \(authService.isAuthenticated)")
        print("Current user: \(authService.currentUser?.uid ?? "nil")")
        
        isSyncing = true
        syncError = nil
        
        // Use the unified health data loading method to find data in the correct location
        let dispatchGroup = DispatchGroup()
        var bpSessions: [BPSession] = []
        var fitnessSessions: [FitnessSession] = []
        var healthMetrics: [HealthMetric] = []
        var hasError = false
        var lastError: Error?
        
        // Load BP Sessions directly
        dispatchGroup.enter()
        firestoreService.loadBPSessions { result in
            switch result {
            case .success(let sessions):
                bpSessions = sessions
                print("Loaded \(sessions.count) BP sessions from Firebase")
            case .failure(let error):
                print("Error loading BP sessions: \(error)")
                hasError = true
                lastError = error
            }
            dispatchGroup.leave()
        }
        
        // Load Fitness Sessions directly
        dispatchGroup.enter()
        firestoreService.loadFitnessSessions { result in
            switch result {
            case .success(let sessions):
                fitnessSessions = sessions
                print("Loaded \(sessions.count) fitness sessions from Firebase")
            case .failure(let error):
                print("Error loading fitness sessions: \(error)")
                hasError = true
                lastError = error
            }
            dispatchGroup.leave()
        }
        
        // Load Health Metrics directly
        dispatchGroup.enter()
        firestoreService.loadHealthMetrics { result in
            switch result {
            case .success(let metrics):
                healthMetrics = metrics
                print("Loaded \(metrics.count) health metrics from Firebase")
            case .failure(let error):
                print("Error loading health metrics: \(error)")
                hasError = true
                lastError = error
            }
            dispatchGroup.leave()
        }
        
        // Load User Profile
        dispatchGroup.enter()
        firestoreService.loadUserProfile { [weak self] result in
            switch result {
            case .success(let profile):
                self?.userProfile = profile
                print("Loaded user profile from Firebase")
            case .failure(let error):
                print("Error loading user profile: \(error)")
            }
            dispatchGroup.leave()
        }
        
        // Load Custom Nutrition Templates
        dispatchGroup.enter()
        loadCustomNutritionTemplatesFromFirestore { [weak self] result in
            switch result {
            case .success(let templates):
                self?.customNutritionTemplates = templates
                print("Loaded \(templates.count) custom nutrition templates from Firebase")
            case .failure(let error):
                print("Error loading custom nutrition templates: \(error)")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            
            self.isSyncing = false
            
            if hasError, let error = lastError {
                self.syncError = error.localizedDescription
                print("Error loading from Firebase: \(error)")
                
                // Fallback to local data if Firebase fails
                print("Falling back to local data...")
                self.loadSessions()
                self.loadFitnessSessions()
                self.loadHealthMetrics()
            } else {
                // Update local data
                self.sessions = bpSessions
                self.fitnessSessions = fitnessSessions
                self.healthMetrics = healthMetrics
                
                // Save to local storage
                self.saveSessions()
                self.saveFitnessSessions()
                self.saveHealthMetrics()
                
                print("Successfully loaded all data from Firebase")
                print("- BP Sessions: \(bpSessions.count)")
                print("- Fitness Sessions: \(fitnessSessions.count)")
                print("- Health Metrics: \(healthMetrics.count)")
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
    
    // MARK: - Manual Data Loading
    
    func loadDataFromFirebase() {
        print("=== MANUAL LOAD FROM FIREBASE CALLED ===")
        print("Auth service is authenticated: \(authService.isAuthenticated)")
        print("Current user: \(authService.currentUser?.uid ?? "nil")")
        
        if authService.isAuthenticated {
            loadFromFirebase()
        } else {
            print("User is not authenticated, cannot load from Firebase")
        }
    }
    
    func forceReloadFromFirebase() {
        print("=== FORCE RELOAD FROM FIREBASE ===")
        hasSyncedForCurrentSession = false
        loadFromFirebase()
    }
    
    func forceReloadCustomNutritionTemplates() {
        print("=== FORCE RELOAD CUSTOM NUTRITION TEMPLATES ===")
        loadCustomNutritionTemplates()
    }
    
    func forceReloadNutritionGoals() {
        print("=== FORCE RELOAD NUTRITION GOALS ===")
        loadNutritionGoalsFromFirestore()
    }
    
    func forceReloadNutritionEntries() {
        print("=== FORCE RELOAD NUTRITION ENTRIES ===")
        loadNutritionEntriesFromFirestore()
    }
    
    func loadNutritionEntriesForDate(_ date: Date) {
        print("=== LOAD NUTRITION ENTRIES FOR DATE ===")
        print("Date: \(date)")
        
        firestoreService.loadNutritionEntriesForDate(date) { result in
            switch result {
            case .success(let entries):
                DispatchQueue.main.async {
                    // Filter out any existing entries for this date and add new ones
                    let calendar = Calendar.current
                    self.nutritionEntries.removeAll { entry in
                        calendar.isDate(entry.date, inSameDayAs: date)
                    }
                    self.nutritionEntries.append(contentsOf: entries)
                    self.saveNutritionEntries() // Save to UserDefaults as backup
                    print("Successfully loaded \(entries.count) nutrition entries for date from Firestore")
                }
            case .failure(let error):
                print("Error loading nutrition entries for date from Firestore: \(error)")
                // Fall back to local data filtering
                self.loadNutritionEntries()
            }
        }
    }
    
    func forceReloadBPSessions() {
        guard authService.isAuthenticated else { 
            print("User not authenticated, cannot load BP sessions")
            return 
        }
        
        // Try direct collection access first
        let db = Firestore.firestore()
        let userID = authService.currentUser?.uid ?? ""
        let collection = db.collection("users").document(userID).collection("health_data").document("bp_session").collection("data")
        
        collection.getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error loading BP sessions: \(error)")
                // Fallback to unified method
                self.loadBPSessionsViaUnifiedMethod()
            } else if let documents = snapshot?.documents {
                var bpSessions: [BPSession] = []
                
                for document in documents {
                    do {
                        let documentData = document.data()
                        let session = try self.decodeBPSessionFromDocument(documentData)
                        bpSessions.append(session)
                    } catch {
                        print("Error decoding BP session: \(error)")
                    }
                }
                
                DispatchQueue.main.async {
                    self.sessions = bpSessions
                    self.saveSessions()
                    print("Successfully loaded \(bpSessions.count) BP sessions from Firebase")
                }
            } else {
                // Fallback to unified method
                self.loadBPSessionsViaUnifiedMethod()
            }
        }
    }
    
    private func decodeBPSessionFromDocument(_ documentData: [String: Any]) throws -> BPSession {
        // Extract basic fields
        guard let idString = documentData["id"] as? String,
              let id = UUID(uuidString: idString) else {
            throw NSError(domain: "BPSessionDecoding", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing or invalid ID"])
        }
        
        // Handle startTime - can be string, double, or Firestore Timestamp
        let startTime: Date
        if let startTimeString = documentData["startTime"] as? String {
            let formatter = ISO8601DateFormatter()
            startTime = formatter.date(from: startTimeString) ?? Date()
        } else if let startTimeDouble = documentData["startTime"] as? Double {
            startTime = Date(timeIntervalSince1970: startTimeDouble)
        } else if let startTimeTimestamp = documentData["startTime"] as? Timestamp {
            startTime = startTimeTimestamp.dateValue()
        } else {
            startTime = Date()
        }
        
        // Handle endTime
        let endTime: Date?
        if let endTimeString = documentData["endTime"] as? String {
            let formatter = ISO8601DateFormatter()
            endTime = formatter.date(from: endTimeString)
        } else if let endTimeDouble = documentData["endTime"] as? Double {
            endTime = Date(timeIntervalSince1970: endTimeDouble)
        } else if let endTimeTimestamp = documentData["endTime"] as? Timestamp {
            endTime = endTimeTimestamp.dateValue()
        } else {
            endTime = nil
        }
        
        // Handle isActive
        let isActive = documentData["isActive"] as? Bool ?? false
        
        // Create BP session with basic fields
        var session = BPSession(id: id, startTime: startTime, endTime: endTime, isActive: isActive)
        
        // Try to decode readings if they exist
        if let readingsData = documentData["readings"] as? [[String: Any]] {
            print("Found \(readingsData.count) readings in document")
            var readings: [BloodPressureReading] = []
            
            for readingData in readingsData {
                if let systolic = readingData["systolic"] as? Int,
                   let diastolic = readingData["diastolic"] as? Int {
                    let heartRate = readingData["heartRate"] as? Int
                    let readingTimestamp: Date
                    
                    if let timestampString = readingData["timestamp"] as? String {
                        let formatter = ISO8601DateFormatter()
                        readingTimestamp = formatter.date(from: timestampString) ?? startTime
                    } else if let timestampDouble = readingData["timestamp"] as? Double {
                        readingTimestamp = Date(timeIntervalSince1970: timestampDouble)
                    } else if let timestampTimestamp = readingData["timestamp"] as? Timestamp {
                        readingTimestamp = timestampTimestamp.dateValue()
                    } else {
                        readingTimestamp = startTime
                    }
                    
                    let reading = BloodPressureReading(systolic: systolic, diastolic: diastolic, heartRate: heartRate, timestamp: readingTimestamp)
                    readings.append(reading)
                }
            }
            session.readings = readings
        } else {
            print("No readings found in document, creating empty readings array")
            session.readings = []
        }
        
        // Try to decode health metrics if they exist
        if let healthMetricsData = documentData["healthMetrics"] as? [[String: Any]] {
            var healthMetrics: [HealthMetric] = []
            for metricData in healthMetricsData {
                do {
                    let metric = try Firestore.Decoder().decode(HealthMetric.self, from: metricData)
                    healthMetrics.append(metric)
                } catch {
                    print("Error decoding health metric: \(error)")
                }
            }
            session.healthMetrics = healthMetrics
        }
        
        return session
    }
    
    private func loadBPSessionsViaUnifiedMethod() {
        // Use the unified loading method specifically for BP sessions
        firestoreService.loadHealthData(dataType: .bloodPressureSession) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let allHealthData):
                var bpSessions: [BPSession] = []
                
                for data in allHealthData {
                    if data.dataType == .bloodPressureSession, let bpSession = data.bpSession {
                        bpSessions.append(bpSession)
                    }
                }
                
                // Update local data
                DispatchQueue.main.async {
                    self.sessions = bpSessions
                    self.saveSessions()
                    print("Successfully loaded \(bpSessions.count) BP sessions from Firebase")
                }
                
            case .failure(let error):
                print("Error loading BP sessions from Firebase: \(error)")
            }
        }
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
    
    // MARK: - Health Notes Management
    
    func saveHealthNote(_ note: HealthNote) {
        guard let userId = userProfile?.id else { return }
        
        let noteWithUserId = HealthNote(
            id: note.id ?? "",
            userId: userId,
            metricType: note.metricType,
            date: note.date,
            note: note.note,
            createdAt: note.createdAt,
            updatedAt: Date()
        )
        
        // Add to local array
        if let index = healthNotes.firstIndex(where: { $0.id == note.id }) {
            healthNotes[index] = noteWithUserId
        } else {
            healthNotes.append(noteWithUserId)
        }
        
        // Save to Firestore
        saveHealthNoteToFirestore(noteWithUserId)
    }
    
    func deleteHealthNote(_ note: HealthNote) {
        guard let noteId = note.id else { return }
        
        // Remove from local array
        healthNotes.removeAll { $0.id == noteId }
        
        // Delete from Firestore
        deleteHealthNoteFromFirestore(noteId)
    }
    
    func getHealthNotes(for metricType: String, on date: Date) -> [HealthNote] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return healthNotes.filter { note in
            note.metricType == metricType &&
            note.date >= startOfDay &&
            note.date < endOfDay
        }
    }
    
    func getHealthNotes(for metricType: String) -> [HealthNote] {
        return healthNotes.filter { $0.metricType == metricType }
    }
    
    private func saveHealthNoteToFirestore(_ note: HealthNote) {
        guard let userId = userProfile?.id else { return }
        
        let db = Firestore.firestore()
        let collection = db.collection("healthNotes")
        
        if let noteId = note.id {
            // Update existing note
            collection.document(noteId).setData(note.toDictionary()) { error in
                if let error = error {
                    print("Error updating health note: \(error.localizedDescription)")
                }
            }
        } else {
            // Create new note
            var newNote = note
            let docRef = collection.addDocument(data: note.toDictionary()) { error in
                if let error = error {
                    print("Error saving health note: \(error.localizedDescription)")
                } else {
                    print("Health note saved successfully")
                }
            }
            newNote.id = docRef.documentID
        }
    }
    
    private func deleteHealthNoteFromFirestore(_ noteId: String) {
        let db = Firestore.firestore()
        let collection = db.collection("healthNotes")
        
        collection.document(noteId).delete { error in
            if let error = error {
                print("Error deleting health note: \(error.localizedDescription)")
            } else {
                print("Health note deleted successfully")
            }
        }
    }
    
    private func loadHealthNotesFromFirestore() {
        guard let userId = userProfile?.id else { return }
        
        let db = Firestore.firestore()
        let collection = db.collection("healthNotes")
        
        collection.whereField("userId", isEqualTo: userId)
            .order(by: "date", descending: true)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("Error loading health notes: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let notes = documents.compactMap { doc in
                    HealthNote.fromDictionary(doc.data(), documentId: doc.documentID)
                }
                
                DispatchQueue.main.async {
                    self?.healthNotes = notes
                }
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
