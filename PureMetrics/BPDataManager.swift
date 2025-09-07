import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

extension Notification.Name {
    static let userDidSignIn = Notification.Name("userDidSignIn")
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
    
    private let maxReadingsPerSession = Int.max
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "BPSessions"
    private let fitnessSessionsKey = "FitnessSessions"
    
    // Firebase services
    private let firestoreService = FirestoreService()
    private let storageService = StorageService()
    private let authService = AuthService()
    
    init() {
        self.currentSession = BPSession()
        self.currentFitnessSession = FitnessSession()
        loadSessions()
        loadFitnessSessions()
        
        // Listen for authentication changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDidSignIn),
            name: .userDidSignIn,
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func userDidSignIn() {
        print("User signed in, syncing data to Firebase...")
        loadFromFirebase()
    }
    
    // MARK: - Session Management
    
    func addReading(systolic: Int, diastolic: Int, heartRate: Int? = nil, timestamp: Date? = nil) -> Bool {
        // Auto-start session if not active and we have room for readings
        if !currentSession.isActive && currentSession.readings.count < maxReadingsPerSession {
            currentSession = BPSession(startTime: Date())
        }
        
        guard currentSession.readings.count < maxReadingsPerSession else {
            return false
        }
        
        let reading = BloodPressureReading(systolic: systolic, diastolic: diastolic, heartRate: heartRate, timestamp: timestamp)
        guard reading.isValid else {
            return false
        }
        
        currentSession.addReading(reading)
        return true
    }
    
    func addHealthMetric(type: MetricType, value: Double, timestamp: Date? = nil) -> Bool {
        // Auto-start session if not active
        if !currentSession.isActive {
            currentSession = BPSession(startTime: Date())
        }
        
        let metric = HealthMetric(type: type, value: value, timestamp: timestamp)
        guard metric.isValid else {
            return false
        }
        
        currentSession.addHealthMetric(metric)
        return true
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
        // Auto-start fitness session if not active
        if !currentFitnessSession.isActive {
            currentFitnessSession = FitnessSession()
        }
        
        let exerciseSession = ExerciseSession(exerciseType: exerciseType)
        currentFitnessSession.addExerciseSession(exerciseSession)
        return true
    }
    
    func loadPreBuiltWorkout(_ workout: PreBuiltWorkout) -> Bool {
        // Clear current session and start new one
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
        currentFitnessSession = FitnessSession()
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
        guard !currentFitnessSession.exerciseSessions.isEmpty else { return }
        
        currentFitnessSession.complete()
        fitnessSessions.insert(currentFitnessSession, at: 0)
        saveFitnessSessions()
        currentFitnessSession = FitnessSession()
    }
    
    func clearCurrentFitnessSession() {
        currentFitnessSession = FitnessSession()
    }
    
    func clearWorkoutTemplate() {
        // Clear all exercises from current session
        currentFitnessSession.exerciseSessions.removeAll()
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
        do {
            let data = try JSONEncoder().encode(fitnessSessions)
            userDefaults.set(data, forKey: fitnessSessionsKey)
            
            // Auto-sync to Firebase if user is authenticated
            if authService.isAuthenticated {
                syncToFirebase()
            }
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
        guard authService.isAuthenticated else { 
            print("Cannot sync to Firebase: No authenticated user")
            return 
        }
        
        isSyncing = true
        syncError = nil
        
        // Create or update user profile
        let profile = UserProfile(
            id: authService.currentUser?.uid ?? "",
            email: authService.currentUser?.email ?? "",
            displayName: authService.currentUser?.displayName,
            photoURL: authService.currentUser?.photoURL?.absoluteString
        )
        
        firestoreService.syncAllData(
            bpSessions: sessions,
            fitnessSessions: fitnessSessions,
            userProfile: profile
        ) { [weak self] result in
            DispatchQueue.main.async {
                self?.isSyncing = false
                
                switch result {
                case .success:
                    print("Successfully synced all data to Firebase")
                    self?.syncError = nil
                case .failure(let error):
                    print("Error syncing to Firebase: \(error)")
                    self?.syncError = error.localizedDescription
                }
            }
        }
    }
    
    func loadFromFirebase() {
        guard authService.isAuthenticated else { return }
        
        isSyncing = true
        syncError = nil
        
        firestoreService.loadAllData { [weak self] result in
            DispatchQueue.main.async {
                self?.isSyncing = false
                
                switch result {
                case .success(let data):
                    self?.sessions = data.bpSessions
                    self?.fitnessSessions = data.fitnessSessions
                    self?.userProfile = data.userProfile
                    self?.saveSessions() // Update local storage
                    self?.saveFitnessSessions()
                case .failure(let error):
                    self?.syncError = error.localizedDescription
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
