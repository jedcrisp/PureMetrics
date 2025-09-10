import Foundation

// MARK: - One Rep Max Model

struct OneRepMax: Codable, Identifiable, Hashable {
    let id: UUID
    let liftName: String
    let weight: Double
    let date: Date
    let notes: String?
    let isCustom: Bool
    
    init(liftName: String, weight: Double, date: Date = Date(), notes: String? = nil, isCustom: Bool = false) {
        self.id = UUID()
        self.liftName = liftName
        self.weight = weight
        self.date = date
        self.notes = notes
        self.isCustom = isCustom
    }
    
    init(id: UUID, liftName: String, weight: Double, date: Date = Date(), notes: String? = nil, isCustom: Bool = false) {
        self.id = id
        self.liftName = liftName
        self.weight = weight
        self.date = date
        self.notes = notes
        self.isCustom = isCustom
    }
    
    var formattedWeight: String {
        return String(format: "%.1f lbs", weight)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - One Rep Max Manager

class OneRepMaxManager: ObservableObject {
    @Published var personalRecords: [OneRepMax] = []
    @Published var customLifts: [String] = []
    
    private let userDefaults = UserDefaults.standard
    private let oneRepMaxKey = "OneRepMaxRecords"
    private let customLiftsKey = "CustomLifts"
    
    // Predefined major lifts
    let majorLifts = [
        "Bench Press",
        "Deadlift", 
        "Back Squat",
        "Front Squat",
        "Overhead Press",
        "Barbell Row",
        "Power Clean",
        "Snatch",
        "Clean & Jerk",
        "Incline Bench Press",
        "Sumo Deadlift",
        "Romanian Deadlift"
    ]
    
    init() {
        loadData()
    }
    
    // MARK: - Data Management
    
    private func loadData() {
        loadPersonalRecords()
        loadCustomLifts()
    }
    
    private func loadPersonalRecords() {
        guard let data = userDefaults.data(forKey: oneRepMaxKey) else { return }
        
        do {
            personalRecords = try JSONDecoder().decode([OneRepMax].self, from: data)
            personalRecords.sort { $0.date > $1.date }
        } catch {
            print("Error loading personal records: \(error)")
            personalRecords = []
        }
    }
    
    private func loadCustomLifts() {
        guard let data = userDefaults.data(forKey: customLiftsKey) else { return }
        
        do {
            customLifts = try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("Error loading custom lifts: \(error)")
            customLifts = []
        }
    }
    
    private func savePersonalRecords() {
        do {
            let data = try JSONEncoder().encode(personalRecords)
            userDefaults.set(data, forKey: oneRepMaxKey)
        } catch {
            print("Error saving personal records: \(error)")
        }
    }
    
    private func saveCustomLifts() {
        do {
            let data = try JSONEncoder().encode(customLifts)
            userDefaults.set(data, forKey: customLiftsKey)
        } catch {
            print("Error saving custom lifts: \(error)")
        }
    }
    
    // MARK: - Public Methods
    
    func addPersonalRecord(_ record: OneRepMax) {
        // Remove any existing record for this lift if the new one is heavier
        personalRecords.removeAll { $0.liftName == record.liftName && $0.weight < record.weight }
        
        // Add the new record
        personalRecords.append(record)
        personalRecords.sort { $0.date > $1.date }
        
        savePersonalRecords()
    }
    
    func updatePersonalRecord(_ record: OneRepMax) {
        if let index = personalRecords.firstIndex(where: { $0.id == record.id }) {
            personalRecords[index] = record
            personalRecords.sort { $0.date > $1.date }
            savePersonalRecords()
        }
    }
    
    func deletePersonalRecord(_ record: OneRepMax) {
        personalRecords.removeAll { $0.id == record.id }
        savePersonalRecords()
    }
    
    func addCustomLift(_ liftName: String) {
        if !customLifts.contains(liftName) && !majorLifts.contains(liftName) {
            customLifts.append(liftName)
            saveCustomLifts()
        }
    }
    
    func removeCustomLift(_ liftName: String) {
        customLifts.removeAll { $0 == liftName }
        // Also remove any personal records for this custom lift
        personalRecords.removeAll { $0.liftName == liftName && $0.isCustom }
        saveCustomLifts()
        savePersonalRecords()
    }
    
    func getPersonalRecord(for liftName: String) -> OneRepMax? {
        return personalRecords.first { $0.liftName == liftName }
    }
    
    func getAllLifts() -> [String] {
        return majorLifts + customLifts
    }
    
    func getRecentRecords(limit: Int = 5) -> [OneRepMax] {
        return Array(personalRecords.prefix(limit))
    }
    
    func getRecordsForLift(_ liftName: String) -> [OneRepMax] {
        return personalRecords.filter { $0.liftName == liftName }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Statistics
    
    func getTotalLifts() -> Int {
        return personalRecords.count
    }
    
    func getTotalWeight() -> Double {
        return personalRecords.reduce(0) { $0 + $1.weight }
    }
    
    func getAverageWeight() -> Double {
        guard !personalRecords.isEmpty else { return 0 }
        return getTotalWeight() / Double(personalRecords.count)
    }
    
    func getHeaviestLift() -> OneRepMax? {
        return personalRecords.max { $0.weight < $1.weight }
    }
    
    func getMostRecentRecord() -> OneRepMax? {
        return personalRecords.first
    }
}

// MARK: - One Rep Max Calculator

class OneRepMaxCalculator {
    // Epley Formula: 1RM = weight * (1 + reps/30)
    static func calculateOneRepMax(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        return weight * (1 + Double(reps) / 30.0)
    }
    
    // Brzycki Formula: 1RM = weight / (1.0278 - 0.0278 * reps)
    static func calculateOneRepMaxBrzycki(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        return weight / (1.0278 - 0.0278 * Double(reps))
    }
    
    // Calculate what weight to use for a given rep range
    static func calculateWeightForReps(oneRepMax: Double, targetReps: Int) -> Double {
        guard targetReps > 0 else { return 0 }
        return oneRepMax / (1 + Double(targetReps) / 30.0)
    }
    
    // Calculate percentage of 1RM
    static func calculatePercentage(weight: Double, oneRepMax: Double) -> Double {
        guard oneRepMax > 0 else { return 0 }
        return (weight / oneRepMax) * 100
    }
}
