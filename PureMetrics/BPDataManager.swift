import Foundation
import SwiftUI

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
    
    private let maxReadingsPerSession = 5
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "BPSessions"
    private let fitnessSessionsKey = "FitnessSessions"
    
    init() {
        self.currentSession = BPSession()
        self.currentFitnessSession = FitnessSession()
        loadSessions()
        loadFitnessSessions()
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
    
    func addExerciseSet(to exerciseIndex: Int, set: ExerciseSet) -> Bool {
        guard exerciseIndex >= 0 && exerciseIndex < currentFitnessSession.exerciseSessions.count else {
            return false
        }
        
        guard set.isValid else { return false }
        
        currentFitnessSession.exerciseSessions[exerciseIndex].addSet(set)
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
                totalTime: session.totalTime
            )
        }.sorted { $0.date < $1.date }
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
