import Foundation

// MARK: - Notification Names


// MARK: - Personal Best Record Types

enum PersonalBestType: String, CaseIterable, Codable {
    case weight = "Weight"
    case time = "Time"
    case distance = "Distance"
    case reps = "Reps"
    case volume = "Volume"
    
    var icon: String {
        switch self {
        case .weight: return "scalemass"
        case .time: return "clock"
        case .distance: return "location"
        case .reps: return "arrow.up.arrow.down"
        case .volume: return "scalemass.fill"
        }
    }
    
    var unit: String {
        switch self {
        case .weight: return "lbs"
        case .time: return "min:sec"
        case .distance: return "miles"
        case .reps: return "reps"
        case .volume: return "lbs"
        }
    }
}

// MARK: - One Rep Max Model

struct OneRepMax: Codable, Identifiable, Hashable {
    let id: UUID
    let liftName: String
    let recordType: PersonalBestType
    let value: Double
    let date: Date
    let notes: String?
    let isCustom: Bool
    
    // Legacy weight property for backward compatibility
    var weight: Double {
        return recordType == .weight ? value : 0
    }
    
    init(liftName: String, recordType: PersonalBestType, value: Double, date: Date = Date(), notes: String? = nil, isCustom: Bool = false) {
        self.id = UUID()
        self.liftName = liftName
        self.recordType = recordType
        self.value = value
        self.date = date
        self.notes = notes
        self.isCustom = isCustom
    }
    
    init(id: UUID, liftName: String, recordType: PersonalBestType, value: Double, date: Date = Date(), notes: String? = nil, isCustom: Bool = false) {
        self.id = id
        self.liftName = liftName
        self.recordType = recordType
        self.value = value
        self.date = date
        self.notes = notes
        self.isCustom = isCustom
    }
    
    // Legacy initializer for backward compatibility
    init(liftName: String, weight: Double, date: Date = Date(), notes: String? = nil, isCustom: Bool = false) {
        self.id = UUID()
        self.liftName = liftName
        self.recordType = .weight
        self.value = weight
        self.date = date
        self.notes = notes
        self.isCustom = isCustom
    }
    
    var formattedValue: String {
        switch recordType {
        case .weight, .volume:
            return String(format: "%.1f %@", value, recordType.unit)
        case .time:
            let minutes = Int(value) / 60
            let seconds = Int(value) % 60
            return String(format: "%d:%02d", minutes, seconds)
        case .distance:
            return String(format: "%.2f %@", value, recordType.unit)
        case .reps:
            return String(format: "%.0f %@", value, recordType.unit)
        }
    }
    
    var formattedWeight: String {
        return formattedValue
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
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    
    private let userDefaults = UserDefaults.standard
    private let oneRepMaxKey = "OneRepMaxRecords"
    private let customLiftsKey = "CustomLifts"
    private let firestoreService = FirestoreService()
    private let authService = AuthService()
    
    // Predefined major lifts and distance runs
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
        "Hex Bar Deadlift",
        "Sumo Deadlift",
        "Romanian Deadlift",
        "1 Mile Run",
        "5K Run",
        "10K Run",
        "Half Marathon",
        "Marathon"
    ]
    
    init() {
        loadData()
        // Set up authentication state monitoring
        setupAuthStateMonitoring()
    }
    
    private func setupAuthStateMonitoring() {
        // Monitor authentication state changes
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
            // User signed in, sync data from Firestore
            syncFromFirestore()
        } else {
            // User signed out, clear synced data but keep local data
            lastSyncDate = nil
        }
    }
    
    // MARK: - Data Management
    
    private func loadData() {
        loadPersonalRecords()
        loadCustomLifts()
        
        // If user is authenticated, sync from Firestore
        if authService.isAuthenticated {
            syncFromFirestore()
        }
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
        // Save locally first for offline access
        do {
            let data = try JSONEncoder().encode(personalRecords)
            userDefaults.set(data, forKey: oneRepMaxKey)
        } catch {
            print("Error saving personal records locally: \(error)")
        }
        
        // Sync to Firestore if authenticated
        if authService.isAuthenticated {
            syncPersonalRecordsToFirestore()
        }
    }
    
    private func saveCustomLifts() {
        // Save locally first for offline access
        do {
            let data = try JSONEncoder().encode(customLifts)
            userDefaults.set(data, forKey: customLiftsKey)
        } catch {
            print("Error saving custom lifts locally: \(error)")
        }
        
        // Sync to Firestore if authenticated
        if authService.isAuthenticated {
            syncCustomLiftsToFirestore()
        }
    }
    
    // MARK: - Public Methods
    
    func addPersonalRecord(_ record: OneRepMax) {
        // Remove any existing record for this lift and record type if the new one is better
        personalRecords.removeAll { existingRecord in
            existingRecord.liftName == record.liftName && 
            existingRecord.recordType == record.recordType && 
            isNewRecordBetter(existing: existingRecord, new: record)
        }
        
        // Add the new record
        personalRecords.append(record)
        personalRecords.sort { $0.date > $1.date }
        
        savePersonalRecords()
    }
    
    private func isNewRecordBetter(existing: OneRepMax, new: OneRepMax) -> Bool {
        // For weight, volume, distance, and reps, higher is better
        // For time, lower is better
        switch existing.recordType {
        case .weight, .volume, .distance, .reps:
            return new.value > existing.value
        case .time:
            return new.value < existing.value
        }
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
    
    func getDefaultRecordType(for liftName: String) -> PersonalBestType {
        let distanceRuns = ["1 Mile Run", "5K Run", "10K Run", "Half Marathon", "Marathon"]
        let isDistanceRun = distanceRuns.contains(liftName)
        let recordType = isDistanceRun ? PersonalBestType.time : PersonalBestType.weight
        print("getDefaultRecordType: '\(liftName)' -> isDistanceRun: \(isDistanceRun) -> \(recordType)")
        return recordType
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
        // Get the best record across all types (highest value for most types, lowest for time)
        return personalRecords.max { record1, record2 in
            switch (record1.recordType, record2.recordType) {
            case (.time, .time):
                return record1.value > record2.value // For time, lower is better
            case (.time, _), (_, .time):
                return record1.recordType == .time // Time records are "better" when they're lower
            default:
                return record1.value < record2.value // For other types, higher is better
            }
        }
    }
    
    func getMostRecentRecord() -> OneRepMax? {
        return personalRecords.first
    }
    
    // MARK: - Firestore Sync Methods
    
    func syncFromFirestore() {
        guard authService.isAuthenticated else { 
            print("User not authenticated, skipping Firestore sync")
            return 
        }
        
        print("Starting Firestore sync for personal records...")
        isSyncing = true
        
        // Load personal records from Firestore
        firestoreService.loadPersonalRecords { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let firestoreRecords):
                    print("Successfully loaded \(firestoreRecords.count) records from Firestore")
                    // Merge with local records, prioritizing Firestore data
                    self?.mergeRecordsFromFirestore(firestoreRecords)
                case .failure(let error):
                    print("Error loading personal records from Firestore: \(error)")
                }
            }
        }
        
        // Load custom lifts from Firestore
        firestoreService.loadCustomLifts { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let firestoreCustomLifts):
                    // Merge with local custom lifts
                    self?.mergeCustomLiftsFromFirestore(firestoreCustomLifts)
                case .failure(let error):
                    print("Error loading custom lifts from Firestore: \(error)")
                }
                
                self?.isSyncing = false
                self?.lastSyncDate = Date()
            }
        }
    }
    
    private func syncPersonalRecordsToFirestore() {
        firestoreService.savePersonalRecords(personalRecords) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Successfully synced personal records to Firestore")
                    self?.lastSyncDate = Date()
                case .failure(let error):
                    print("Error syncing personal records to Firestore: \(error)")
                }
            }
        }
    }
    
    private func syncCustomLiftsToFirestore() {
        firestoreService.saveCustomLifts(customLifts) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("Successfully synced custom lifts to Firestore")
                case .failure(let error):
                    print("Error syncing custom lifts to Firestore: \(error)")
                }
            }
        }
    }
    
    private func mergeRecordsFromFirestore(_ firestoreRecords: [OneRepMax]) {
        print("Merging \(firestoreRecords.count) Firestore records with \(personalRecords.count) local records")
        
        // Create a dictionary of local records for quick lookup
        var localRecordsDict: [UUID: OneRepMax] = [:]
        for record in personalRecords {
            localRecordsDict[record.id] = record
        }
        
        // Merge Firestore records with local records
        var mergedRecords: [OneRepMax] = []
        
        // Add all Firestore records
        for firestoreRecord in firestoreRecords {
            print("Adding Firestore record: \(firestoreRecord.liftName) - \(firestoreRecord.formattedValue)")
            mergedRecords.append(firestoreRecord)
        }
        
        // Add local records that don't exist in Firestore
        for localRecord in personalRecords {
            if !firestoreRecords.contains(where: { $0.id == localRecord.id }) {
                print("Adding local-only record: \(localRecord.liftName) - \(localRecord.formattedValue)")
                mergedRecords.append(localRecord)
            }
        }
        
        // Sort by date (newest first)
        mergedRecords.sort { $0.date > $1.date }
        
        print("Final merged records count: \(mergedRecords.count)")
        personalRecords = mergedRecords
        
        // Save the merged data locally
        do {
            let data = try JSONEncoder().encode(personalRecords)
            userDefaults.set(data, forKey: oneRepMaxKey)
            print("Successfully saved merged records to local storage")
        } catch {
            print("Error saving merged personal records: \(error)")
        }
    }
    
    private func mergeCustomLiftsFromFirestore(_ firestoreCustomLifts: [String]) {
        // Combine local and Firestore custom lifts, removing duplicates
        let combinedCustomLifts = Array(Set(customLifts + firestoreCustomLifts))
        customLifts = combinedCustomLifts
        
        // Save the merged data locally
        do {
            let data = try JSONEncoder().encode(customLifts)
            userDefaults.set(data, forKey: customLiftsKey)
        } catch {
            print("Error saving merged custom lifts: \(error)")
        }
    }
    
    func forceSync() {
        syncFromFirestore()
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
