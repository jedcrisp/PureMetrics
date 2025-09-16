import Foundation
import SwiftUI

// MARK: - Daily Goals Model

struct DailyGoals: Codable, Identifiable {
    var id: String
    var date: Date
    var nutritionGoals: NutritionGoals
    var fitnessGoals: FitnessGoals
    var isCompleted: Bool = false
    var createdAt: Date
    var updatedAt: Date
    
    init(date: Date = Date(), nutritionGoals: NutritionGoals = NutritionGoals(), fitnessGoals: FitnessGoals = FitnessGoals()) {
        let calendar = Calendar.current
        let dayStart = calendar.dateInterval(of: .day, for: date)?.start ?? date
        
        self.id = Self.generateID(for: dayStart)
        self.date = dayStart
        self.nutritionGoals = nutritionGoals
        self.fitnessGoals = fitnessGoals
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    static func generateID(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "daily_goals_\(formatter.string(from: date))"
    }
    
    mutating func updateNutritionGoals(_ goals: NutritionGoals) {
        self.nutritionGoals = goals
        self.updatedAt = Date()
    }
    
    mutating func updateFitnessGoals(_ goals: FitnessGoals) {
        self.fitnessGoals = goals
        self.updatedAt = Date()
    }
    
    mutating func markCompleted() {
        self.isCompleted = true
        self.updatedAt = Date()
    }
    
    var isToday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(date)
    }
    
    var isYesterday: Bool {
        let calendar = Calendar.current
        return calendar.isDateInYesterday(date)
    }
    
    var isTomorrow: Bool {
        let calendar = Calendar.current
        return calendar.isDateInTomorrow(date)
    }
}

// MARK: - Fitness Goals Model

struct FitnessGoals: Codable {
    var dailyWorkoutMinutes: Int = 30
    var dailySteps: Int = 10000
    var dailyCaloriesBurned: Int = 500
    var weeklyWorkouts: Int = 5
    var dailyWaterIntake: Double = 64 // ounces
    var dailySleepHours: Double = 8
    var dailyStretchingMinutes: Int = 10
    var dailyCardioMinutes: Int = 20
    var dailyStrengthMinutes: Int = 30
    
    // Custom fitness goals
    var customGoals: [CustomFitnessGoal] = []
    
    enum CodingKeys: String, CodingKey {
        case dailyWorkoutMinutes, dailySteps, dailyCaloriesBurned, weeklyWorkouts
        case dailyWaterIntake, dailySleepHours, dailyStretchingMinutes
        case dailyCardioMinutes, dailyStrengthMinutes, customGoals
    }
}

// MARK: - Custom Fitness Goal

struct CustomFitnessGoal: Codable, Identifiable {
    var id: UUID
    var name: String
    var targetValue: Double
    var unit: String
    var category: FitnessGoalCategory
    var isActive: Bool = true
    var createdAt: Date
    
    init(name: String, targetValue: Double, unit: String, category: FitnessGoalCategory) {
        self.id = UUID()
        self.name = name
        self.targetValue = targetValue
        self.unit = unit
        self.category = category
        self.createdAt = Date()
    }
}

// MARK: - Fitness Goal Category

enum FitnessGoalCategory: String, CaseIterable, Codable {
    case cardio = "Cardio"
    case strength = "Strength"
    case flexibility = "Flexibility"
    case endurance = "Endurance"
    case balance = "Balance"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .cardio: return "heart.fill"
        case .strength: return "dumbbell.fill"
        case .flexibility: return "figure.flexibility"
        case .endurance: return "timer"
        case .balance: return "figure.balance"
        case .custom: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .cardio: return .red
        case .strength: return .blue
        case .flexibility: return .green
        case .endurance: return .orange
        case .balance: return .purple
        case .custom: return .gray
        }
    }
}

// MARK: - Daily Goals Manager

class DailyGoalsManager: ObservableObject {
    @Published var currentDailyGoals: DailyGoals?
    @Published var historicalGoals: [DailyGoals] = []
    @Published var isSyncing = false
    @Published var syncError: String?
    
    private let userDefaults = UserDefaults.standard
    private let firestoreService = FirestoreService()
    private let authService = AuthService()
    
    // UserDefaults keys
    private let currentGoalsKey = "CurrentDailyGoals"
    private let historicalGoalsKey = "HistoricalDailyGoals"
    private let lastResetDateKey = "LastDailyGoalsResetDate"
    
    init() {
        loadCurrentGoals()
        setupAuthStateMonitoring()
    }
    
    private func setupAuthStateMonitoring() {
        NotificationCenter.default.addObserver(
            forName: .authStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAuthStateChange()
        }
    }
    
    private func handleAuthStateChange() {
        if authService.isAuthenticated {
            syncFromFirestore()
        } else {
            // User signed out, keep local data but clear sync status
            isSyncing = false
            syncError = nil
        }
    }
    
    // MARK: - Current Goals Management
    
    func loadCurrentGoals() {
        // Load from UserDefaults first
        if let data = userDefaults.data(forKey: currentGoalsKey),
           let goals = try? JSONDecoder().decode(DailyGoals.self, from: data) {
            currentDailyGoals = goals
        } else {
            // Create new goals for today
            createNewDailyGoals()
        }
        
        // Check if we need to reset for a new day
        checkAndResetForNewDay()
        
        // Load historical goals
        loadHistoricalGoals()
        
        // Sync from Firestore if authenticated
        if authService.isAuthenticated {
            syncFromFirestore()
        }
    }
    
    private func createNewDailyGoals() {
        let today = Date()
        currentDailyGoals = DailyGoals(date: today)
        saveCurrentGoals()
    }
    
    private func checkAndResetForNewDay() {
        guard let currentGoals = currentDailyGoals else {
            createNewDailyGoals()
            return
        }
        
        let calendar = Calendar.current
        let today = Date()
        let todayStart = calendar.dateInterval(of: .day, for: today)?.start ?? today
        
        // If current goals are not for today, create new ones
        if !calendar.isDate(currentGoals.date, inSameDayAs: todayStart) {
            // Save current goals to historical if they exist
            if !currentGoals.isCompleted {
                saveToHistorical(currentGoals)
            }
            
            // Create new goals for today
            createNewDailyGoals()
        }
    }
    
    func updateNutritionGoals(_ goals: NutritionGoals) {
        guard var currentGoals = currentDailyGoals else {
            createNewDailyGoals()
            updateNutritionGoals(goals)
            return
        }
        
        currentGoals.updateNutritionGoals(goals)
        currentDailyGoals = currentGoals
        saveCurrentGoals()
        
        // Sync to Firestore
        if authService.isAuthenticated {
            syncCurrentGoalsToFirestore()
        }
    }
    
    func updateFitnessGoals(_ goals: FitnessGoals) {
        guard var currentGoals = currentDailyGoals else {
            createNewDailyGoals()
            updateFitnessGoals(goals)
            return
        }
        
        currentGoals.updateFitnessGoals(goals)
        currentDailyGoals = currentGoals
        saveCurrentGoals()
        
        // Sync to Firestore
        if authService.isAuthenticated {
            syncCurrentGoalsToFirestore()
        }
    }
    
    func markGoalsCompleted() {
        guard var currentGoals = currentDailyGoals else { return }
        
        currentGoals.markCompleted()
        currentDailyGoals = currentGoals
        saveCurrentGoals()
        
        // Sync to Firestore
        if authService.isAuthenticated {
            syncCurrentGoalsToFirestore()
        }
    }
    
    // MARK: - Data Persistence
    
    private func saveCurrentGoals() {
        guard let goals = currentDailyGoals else { return }
        
        do {
            let data = try JSONEncoder().encode(goals)
            userDefaults.set(data, forKey: currentGoalsKey)
            userDefaults.set(Date(), forKey: lastResetDateKey)
        } catch {
            print("Error saving current daily goals: \(error)")
        }
    }
    
    private func loadHistoricalGoals() {
        guard let data = userDefaults.data(forKey: historicalGoalsKey) else { return }
        
        do {
            historicalGoals = try JSONDecoder().decode([DailyGoals].self, from: data)
            historicalGoals.sort { $0.date > $1.date }
        } catch {
            print("Error loading historical goals: \(error)")
            historicalGoals = []
        }
    }
    
    private func saveHistoricalGoals() {
        do {
            let data = try JSONEncoder().encode(historicalGoals)
            userDefaults.set(data, forKey: historicalGoalsKey)
        } catch {
            print("Error saving historical goals: \(error)")
        }
    }
    
    private func saveToHistorical(_ goals: DailyGoals) {
        historicalGoals.append(goals)
        // Keep only last 30 days of historical data
        if historicalGoals.count > 30 {
            historicalGoals = Array(historicalGoals.prefix(30))
        }
        saveHistoricalGoals()
    }
    
    // MARK: - Firestore Sync
    
    private func syncFromFirestore() {
        guard authService.isAuthenticated else { return }
        
        isSyncing = true
        syncError = nil
        
        firestoreService.loadDailyGoals { [weak self] result in
            DispatchQueue.main.async {
                self?.isSyncing = false
                
                switch result {
                case .success(let goals):
                    if let goals = goals {
                        self?.currentDailyGoals = goals
                        self?.saveCurrentGoals()
                    }
                case .failure(let error):
                    self?.syncError = error.localizedDescription
                    print("Error loading daily goals from Firestore: \(error)")
                }
            }
        }
    }
    
    private func syncCurrentGoalsToFirestore() {
        guard authService.isAuthenticated, let goals = currentDailyGoals else { return }
        
        firestoreService.saveDailyGoals(goals) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Successfully saved daily goals to Firestore")
                case .failure(let error):
                    self?.syncError = error.localizedDescription
                    print("Error saving daily goals to Firestore: \(error)")
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func getGoalsForDate(_ date: Date) -> DailyGoals? {
        let calendar = Calendar.current
        let dateStart = calendar.dateInterval(of: .day, for: date)?.start ?? date
        
        // Check if it's today's goals
        if let current = currentDailyGoals, calendar.isDate(current.date, inSameDayAs: dateStart) {
            return current
        }
        
        // Check historical goals
        return historicalGoals.first { calendar.isDate($0.date, inSameDayAs: dateStart) }
    }
    
    func getGoalsForDateRange(_ startDate: Date, _ endDate: Date) -> [DailyGoals] {
        let calendar = Calendar.current
        let start = calendar.dateInterval(of: .day, for: startDate)?.start ?? startDate
        let end = calendar.dateInterval(of: .day, for: endDate)?.start ?? endDate
        
        var goals: [DailyGoals] = []
        
        // Add current goals if in range
        if let current = currentDailyGoals,
           current.date >= start && current.date <= end {
            goals.append(current)
        }
        
        // Add historical goals in range
        let historicalInRange = historicalGoals.filter { goal in
            goal.date >= start && goal.date <= end
        }
        goals.append(contentsOf: historicalInRange)
        
        return goals.sorted { $0.date > $1.date }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let dailyGoalsUpdated = Notification.Name("dailyGoalsUpdated")
    static let dailyGoalsReset = Notification.Name("dailyGoalsReset")
}
