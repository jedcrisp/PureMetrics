import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirestoreService: ObservableObject {
    let db = Firestore.firestore()
    private let authService = AuthService()
    private let encryptionService = EncryptionService.shared
    
    // MARK: - Collection References
    
    private var userID: String? {
        return authService.currentUser?.uid
    }
    
    // MARK: - Custom Decoding
    
    private func decodeUnifiedHealthData(from documentData: [String: Any]) throws -> UnifiedHealthData {
        // Extract basic fields
        guard let idString = documentData["id"] as? String,
              let id = UUID(uuidString: idString),
              let dataTypeString = documentData["dataType"] as? String,
              let dataType = HealthDataType(rawValue: dataTypeString) else {
            throw FirestoreError.decodingError("Missing required fields")
        }
        
        // Handle timestamp - can be string, double, or Firestore Timestamp
        let timestamp: Date
        if let timestampString = documentData["timestamp"] as? String {
            // Try to parse as ISO8601 string
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: timestampString) {
                timestamp = date
            } else {
                // Try to parse as double (Unix timestamp)
                if let timestampDouble = Double(timestampString) {
                    timestamp = Date(timeIntervalSince1970: timestampDouble)
                } else {
                    throw FirestoreError.decodingError("Invalid timestamp format: \(timestampString)")
                }
            }
        } else if let timestampDouble = documentData["timestamp"] as? Double {
            timestamp = Date(timeIntervalSince1970: timestampDouble)
        } else if let firestoreTimestamp = documentData["timestamp"] as? Timestamp {
            timestamp = firestoreTimestamp.dateValue()
        } else {
            throw FirestoreError.decodingError("Timestamp field not found or invalid type")
        }
        
        // Decode based on data type
        switch dataType {
        case .bloodPressureSession:
            let bpSession = try decodeBPSession(from: documentData)
            return UnifiedHealthData(id: id, dataType: dataType, bpSession: bpSession, timestamp: timestamp)
            
        case .fitnessSession:
            let fitnessSession = try decodeFitnessSession(from: documentData)
            return UnifiedHealthData(id: id, dataType: dataType, fitnessSession: fitnessSession, timestamp: timestamp)
            
        case .weight, .bloodSugar, .heartRate:
            guard let metricTypeString = documentData["metricType"] as? String,
                  let metricType = MetricType(rawValue: metricTypeString),
                  let value = documentData["value"] as? Double,
                  let unit = documentData["unit"] as? String else {
                throw FirestoreError.decodingError("Missing metric fields")
            }
            return UnifiedHealthData(id: id, dataType: dataType, metricType: metricType, value: value, unit: unit, timestamp: timestamp)
            
        case .nutritionEntry:
            let nutritionEntry = try decodeNutritionEntry(from: documentData)
            return UnifiedHealthData(id: id, dataType: dataType, nutritionEntry: nutritionEntry, timestamp: timestamp)
            
        default:
            throw FirestoreError.decodingError("Unsupported data type: \(dataType)")
        }
    }
    
    private func decodeBPSession(from documentData: [String: Any]) throws -> BPSession {
        // This is a simplified version - you might need to handle nested data
        guard let startTimeString = documentData["startTime"] as? String else {
            throw FirestoreError.decodingError("Missing startTime")
        }
        
        let formatter = ISO8601DateFormatter()
        guard let startTime = formatter.date(from: startTimeString) else {
            throw FirestoreError.decodingError("Invalid startTime format")
        }
        
        // Create a basic BPSession - you might need to decode readings separately
        var session = BPSession(startTime: startTime)
        
        // Try to decode readings if they exist
        if let readingsData = documentData["readings"] as? [[String: Any]] {
            var readings: [BloodPressureReading] = []
            for readingData in readingsData {
                if let systolic = readingData["systolic"] as? Int,
                   let diastolic = readingData["diastolic"] as? Int {
                    let heartRate = readingData["heartRate"] as? Int
                    let readingTimestamp: Date
                    if let timestampString = readingData["timestamp"] as? String {
                        readingTimestamp = formatter.date(from: timestampString) ?? Date()
                    } else {
                        readingTimestamp = Date()
                    }
                    let reading = BloodPressureReading(systolic: systolic, diastolic: diastolic, heartRate: heartRate, timestamp: readingTimestamp)
                    readings.append(reading)
                }
            }
            session.readings = readings
        }
        
        return session
    }
    
    private func decodeFitnessSession(from documentData: [String: Any]) throws -> FitnessSession {
        // This is a simplified version - you might need to handle nested data
        guard let startTimeString = documentData["startTime"] as? String else {
            throw FirestoreError.decodingError("Missing startTime")
        }
        
        let formatter = ISO8601DateFormatter()
        guard let startTime = formatter.date(from: startTimeString) else {
            throw FirestoreError.decodingError("Invalid startTime format")
        }
        
        // Create a basic FitnessSession
        var session = FitnessSession()
        session.startTime = startTime
        
        // You might need to decode exercise sessions separately
        // This is a placeholder implementation
        
        return session
    }
    
    private func decodeNutritionEntry(from documentData: [String: Any]) throws -> NutritionEntry {
        // Extract nutrition entry fields
        guard let dateString = documentData["date"] as? String,
              let date = ISO8601DateFormatter().date(from: dateString),
              let calories = documentData["calories"] as? Double,
              let protein = documentData["protein"] as? Double,
              let carbohydrates = documentData["carbohydrates"] as? Double,
              let fat = documentData["fat"] as? Double,
              let sodium = documentData["sodium"] as? Double,
              let sugar = documentData["sugar"] as? Double,
              let fiber = documentData["fiber"] as? Double,
              let cholesterol = documentData["cholesterol"] as? Double,
              let water = documentData["water"] as? Double else {
            throw FirestoreError.decodingError("Missing required nutrition entry fields")
        }
        
        let addedSugar = documentData["addedSugar"] as? Double ?? 0
        let notes = documentData["notes"] as? String
        let label = documentData["label"] as? String
        
        return NutritionEntry(
            date: date,
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
            notes: notes,
            label: label
        )
    }
    
    private func userCollection() -> CollectionReference? {
        guard let userID = userID else { return nil }
        return db.collection("users").document(userID).collection("health_data")
    }
    
    private func dataTypeCollection(_ dataType: HealthDataType) -> CollectionReference? {
        guard let userID = userID else { return nil }
        return db.collection("users").document(userID).collection("health_data").document(dataType.rawValue).collection("data")
    }
    
    // New method for date-based nutrition entries - using a simpler structure
    private func nutritionEntryCollection(for date: Date) -> CollectionReference? {
        guard let userID = userID else { return nil }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        // Create the path: users/{userId}/health_data/nutrition_entries_by_date/{date}
        return db.collection("users").document(userID).collection("health_data").document("nutrition_entries_by_date").collection(dateString)
    }
    
    // Fallback method to check root-level collections (for existing data)
    private func rootDataTypeCollection(_ dataType: HealthDataType) -> CollectionReference? {
        return db.collection("health_data").document(dataType.rawValue).collection("data")
    }
    
    // Fallback method for root-level date-based nutrition entries
    private func rootNutritionEntryCollection(for date: Date) -> CollectionReference? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        // Create the path: health_data/nutrition_entries_by_date/{date}
        return db.collection("health_data").document("nutrition_entries_by_date").collection(dateString)
    }
    
    // MARK: - Unified Health Data Management
    
    func saveHealthData(_ data: [UnifiedHealthData], completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        print("=== FIRESTORE SAVE HEALTH DATA CALLED ===")
        print("Data count: \(data.count)")
        print("User ID: \(userID ?? "nil")")
        print("Auth service authenticated: \(authService.isAuthenticated)")
        
        // Group data by type for organized storage
        let groupedData = Dictionary(grouping: data) { $0.dataType }
        
        let batch = db.batch()
        var totalDocuments = 0
        
        for (dataType, dataItems) in groupedData {
            guard let collection = dataTypeCollection(dataType) else {
                print("Error: No authenticated user for saving \(dataType.rawValue) data")
                continue
            }
            
            for (index, healthData) in dataItems.enumerated() {
                do {
                    var dataDict = try Firestore.Encoder().encode(healthData)
                    dataDict["createdAt"] = Timestamp(date: healthData.timestamp)
                    dataDict["updatedAt"] = Timestamp(date: Date())
                    
                    // Encrypt sensitive data
                    if let encryptedData = try? self.encryptionService.encryptHealthData(healthData) {
                        dataDict["encryptedData"] = encryptedData
                        dataDict["isEncrypted"] = true
                    }
                    
                    let docRef = collection.document(healthData.id.uuidString)
                    batch.setData(dataDict, forDocument: docRef)
                    totalDocuments += 1
                } catch {
                    print("Error encoding \(dataType.rawValue) data \(index): \(error)")
                }
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("Error saving health data: \(error)")
                completion(.failure(error))
            } else {
                print("Successfully saved \(totalDocuments) health data entries across \(groupedData.count) data types")
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Deduplication Methods
    
    func clearDuplicateData(completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        print("Clearing duplicate data...")
        
        // For now, just log the current data counts
        // In a production app, you'd want to implement proper deduplication logic
        loadHealthData { result in
            switch result {
            case .success(let data):
                let groupedData = Dictionary(grouping: data) { $0.dataType }
                for (dataType, items) in groupedData {
                    print("\(dataType.rawValue): \(items.count) entries")
                }
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func loadHealthData(dataType: HealthDataType? = nil, completion: @escaping (Result<[UnifiedHealthData], Error>) -> Void) {
        if let dataType = dataType {
            // Load specific data type
            loadSpecificDataType(dataType, completion: completion)
        } else {
            // Load all data types
            loadAllDataTypes(completion: completion)
        }
    }
    
    private func loadSpecificDataType(_ dataType: HealthDataType, completion: @escaping (Result<[UnifiedHealthData], Error>) -> Void) {
        // For nutrition entries, only use user-specific collections to prevent data leakage
        if dataType == .nutritionEntry {
            guard let userCollection = dataTypeCollection(dataType) else {
                print("Error: No user collection available for loading \(dataType.rawValue) data")
                completion(.failure(FirestoreError.noUser))
                return
            }
            
            print("Loading \(dataType.rawValue) from user-specific collection only: \(userCollection.path)")
            tryLoadFromCollections([userCollection], dataType: dataType, completion: completion)
            return
        }
        
        // For other data types, try user-specific collection first, then fallback to root collection
        let userCollection = dataTypeCollection(dataType)
        let rootCollection = rootDataTypeCollection(dataType)
        
        // Prioritize user-specific collection
        var collections: [CollectionReference] = []
        if let userCol = userCollection {
            collections.append(userCol)
            print("Will try user-specific collection: \(userCol.path)")
        }
        if let rootCol = rootCollection {
            collections.append(rootCol)
            print("Will try root collection: \(rootCol.path)")
        }
        
        guard !collections.isEmpty else {
            print("Error: No collections available for loading \(dataType.rawValue) data")
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        print("Trying \(collections.count) collections for \(dataType.rawValue)")
        
        // Try each collection until we find data
        tryLoadFromCollections(collections, dataType: dataType, completion: completion)
    }
    
    private func tryLoadFromCollections(_ collections: [CollectionReference], dataType: HealthDataType, completion: @escaping (Result<[UnifiedHealthData], Error>) -> Void) {
        guard !collections.isEmpty else {
            print("No more collections to try for \(dataType.rawValue)")
            completion(.success([]))
            return
        }
        
        let collection = collections[0]
        let remainingCollections = Array(collections.dropFirst())
        
        print("Trying to load \(dataType.rawValue) from collection: \(collection.path)")
        
        var isCompleted = false
        
        // Add timeout for individual requests
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            guard !isCompleted else { return }
            isCompleted = true
            print("Timeout loading \(dataType.rawValue) data from \(collection.path)")
            // Try next collection if available
            if !remainingCollections.isEmpty {
                self.tryLoadFromCollections(remainingCollections, dataType: dataType, completion: completion)
            } else {
                completion(.success([]))
            }
        }
        
        // Try without ordering first, in case createdAt field doesn't exist
        collection.getDocuments { snapshot, error in
            guard !isCompleted else { return }
            isCompleted = true
            
            if let error = error {
                print("Error loading \(dataType.rawValue) data from \(collection.path): \(error)")
                
                // Check if it's a permission error
                if let firestoreError = error as NSError?, firestoreError.code == 7 {
                    print("Permission denied for \(collection.path) - this is likely due to Firestore security rules")
                    print("Please update your Firestore rules to allow access to root-level health_data collections")
                }
                
                // Try next collection if available
                if !remainingCollections.isEmpty {
                    self.tryLoadFromCollections(remainingCollections, dataType: dataType, completion: completion)
                } else {
                    completion(.failure(error))
                }
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No \(dataType.rawValue) data found in \(collection.path)")
                // Try next collection if available
                if !remainingCollections.isEmpty {
                    self.tryLoadFromCollections(remainingCollections, dataType: dataType, completion: completion)
                } else {
                    completion(.success([]))
                }
                return
            }
            
            print("Found \(documents.count) documents in \(collection.path)")
            
            // Debug: Print document IDs and basic info
            for (index, document) in documents.enumerated() {
                print("  Document \(index): \(document.documentID)")
                let data = document.data()
                print("    Data keys: \(Array(data.keys))")
                if let dataType = data["dataType"] as? String {
                    print("    Data type: \(dataType)")
                }
                if let timestamp = data["timestamp"] {
                    print("    Timestamp: \(timestamp)")
                }
            }
            
            var healthData: [UnifiedHealthData] = []
            
            for document in documents {
                do {
                    let documentData = document.data()
                    
                    // Check if data is encrypted
                    if let isEncrypted = documentData["isEncrypted"] as? Bool, isEncrypted,
                       let encryptedString = documentData["encryptedData"] as? String {
                        print("Decrypting encrypted data for document \(document.documentID)")
                        // Decrypt the data
                        let decryptedData = try self.encryptionService.decryptHealthData(encryptedString, as: UnifiedHealthData.self)
                        healthData.append(decryptedData)
                    } else {
                        print("Decoding unencrypted data for document \(document.documentID)")
                        // Custom decoding to handle string timestamps
                        let data = try self.decodeUnifiedHealthData(from: documentData)
                        healthData.append(data)
                    }
                } catch {
                    print("Error decoding \(dataType.rawValue) data from document \(document.documentID): \(error)")
                    print("Document data: \(document.data())")
                }
            }
            
            if healthData.isEmpty {
                print("No valid \(dataType.rawValue) data found in \(collection.path), trying next collection...")
                // Try next collection if available
                if !remainingCollections.isEmpty {
                    self.tryLoadFromCollections(remainingCollections, dataType: dataType, completion: completion)
                } else {
                    completion(.success([]))
                }
            } else {
                print("Successfully loaded \(healthData.count) \(dataType.rawValue) entries from \(collection.path)")
                completion(.success(healthData))
            }
        }
    }
    
    private func loadAllDataTypes(completion: @escaping (Result<[UnifiedHealthData], Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var allHealthData: [UnifiedHealthData] = []
        var hasError = false
        var lastError: Error?
        var isCompleted = false
        
        print("=== LOADING ALL DATA TYPES ===")
        print("Available data types: \(HealthDataType.allCases.map { $0.rawValue })")
        
        for dataType in HealthDataType.allCases {
            dispatchGroup.enter()
            
            print("Loading data type: \(dataType.rawValue)")
            loadSpecificDataType(dataType) { result in
                guard !isCompleted else { return }
                
                switch result {
                case .success(let data):
                    print("Successfully loaded \(data.count) items for \(dataType.rawValue)")
                    allHealthData.append(contentsOf: data)
                case .failure(let error):
                    print("Failed to load \(dataType.rawValue): \(error)")
                    hasError = true
                    lastError = error
                }
                dispatchGroup.leave()
            }
        }
        
        // Add timeout to prevent hanging
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            guard !isCompleted else { return }
            isCompleted = true
            
            print("=== LOAD TIMEOUT REACHED ===")
            print("Total data loaded: \(allHealthData.count)")
            
            if allHealthData.isEmpty {
                completion(.failure(lastError ?? FirestoreError.timeout))
            } else {
                // Sort by timestamp (newest first)
                allHealthData.sort { $0.timestamp > $1.timestamp }
                print("Successfully loaded \(allHealthData.count) total health data entries across all types (with timeout)")
                completion(.success(allHealthData))
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            guard !isCompleted else { return }
            isCompleted = true
            
            print("=== ALL DATA TYPES LOADED ===")
            print("Total data loaded: \(allHealthData.count)")
            print("Has error: \(hasError)")
            
            if hasError, let error = lastError {
                print("Completing with error: \(error)")
                completion(.failure(error))
            } else {
                // Sort by timestamp (newest first)
                allHealthData.sort { $0.timestamp > $1.timestamp }
                print("Successfully loaded \(allHealthData.count) total health data entries across all types")
                completion(.success(allHealthData))
            }
        }
    }
    
    // MARK: - Legacy Health Metrics (for backward compatibility)
    
    func saveHealthMetrics(_ metrics: [HealthMetric], completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        // Group metrics by type for better organization
        let groupedMetrics = Dictionary(grouping: metrics) { $0.type }
        
        let batch = db.batch()
        var totalDocuments = 0
        
        for (metricType, metricList) in groupedMetrics {
            let dataType: HealthDataType
            switch metricType {
            case .weight: dataType = .weight
            case .bloodPressure: dataType = .bloodPressureSession
            case .bloodSugar: dataType = .bloodSugar
            case .heartRate: dataType = .heartRate
            case .bodyFat: dataType = .bodyFat
            case .leanBodyMass: dataType = .leanBodyMass
            }
            
            guard let collection = dataTypeCollection(dataType) else {
                print("Error: No authenticated user for saving \(dataType.rawValue) data")
                continue
            }
            
            for metric in metricList {
                do {
                    var metricData = try Firestore.Encoder().encode(metric)
                    metricData["dataType"] = dataType.rawValue
                    metricData["createdAt"] = Timestamp(date: metric.timestamp)
                    metricData["updatedAt"] = Timestamp(date: Date())
                    
                    let docRef = collection.document(metric.id.uuidString)
                    batch.setData(metricData, forDocument: docRef)
                    totalDocuments += 1
                } catch {
                    print("Error encoding \(metricType.rawValue) metric: \(error)")
                }
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("Error saving health metrics: \(error)")
                completion(.failure(error))
            } else {
                print("Successfully saved \(totalDocuments) health metrics across \(groupedMetrics.count) types")
                completion(.success(()))
            }
        }
    }
    
    func loadHealthMetrics(completion: @escaping (Result<[HealthMetric], Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var allMetrics: [HealthMetric] = []
        var hasError = false
        var lastError: Error?
        
        // Load from all metric-specific collections
        let metricTypes: [HealthDataType] = [.weight, .bloodSugar, .heartRate]
        
        for dataType in metricTypes {
            dispatchGroup.enter()
            
            guard let collection = dataTypeCollection(dataType) else {
                print("Error: No authenticated user for loading \(dataType.rawValue) data")
                hasError = true
                lastError = FirestoreError.noUser
                dispatchGroup.leave()
                continue
            }
            
            print("Loading \(dataType.rawValue) metrics from Firestore...")
            collection.order(by: "timestamp", descending: true).getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading \(dataType.rawValue) metrics: \(error)")
                    hasError = true
                    lastError = error
                } else if let documents = snapshot?.documents {
                    print("Found \(documents.count) \(dataType.rawValue) metric documents in Firestore")
                    
                    for document in documents {
                        do {
                            var documentData = document.data()
                            
                            // Remove the extra fields we added for Firestore
                            documentData.removeValue(forKey: "dataType")
                            documentData.removeValue(forKey: "createdAt")
                            documentData.removeValue(forKey: "updatedAt")
                            documentData.removeValue(forKey: "isEncrypted")
                            documentData.removeValue(forKey: "encryptedData")
                            
                            let metric = try Firestore.Decoder().decode(HealthMetric.self, from: documentData)
                            allMetrics.append(metric)
                        } catch {
                            print("Error decoding \(dataType.rawValue) metric: \(error)")
                        }
                    }
                } else {
                    print("No \(dataType.rawValue) metrics found in Firestore")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if hasError, let error = lastError {
                completion(.failure(error))
            } else {
                // Sort by timestamp (newest first)
                allMetrics.sort { $0.timestamp > $1.timestamp }
                print("Successfully loaded \(allMetrics.count) health metrics across all types")
                completion(.success(allMetrics))
            }
        }
    }
    
    // MARK: - Blood Pressure Sessions (using unified structure)
    
    func saveBPSessions(_ sessions: [BPSession], completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let collection = dataTypeCollection(.bloodPressureSession) else {
            print("Error: No authenticated user for saving BP sessions")
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let batch = db.batch()
        
        for (index, session) in sessions.enumerated() {
            do {
                var sessionData = try Firestore.Encoder().encode(session)
                sessionData["dataType"] = "bp_session"
                sessionData["createdAt"] = Timestamp(date: session.startTime)
                sessionData["updatedAt"] = Timestamp(date: Date())
                
                let docRef = collection.document(session.id.uuidString)
                batch.setData(sessionData, forDocument: docRef)
            } catch {
                print("Error encoding BP session \(index): \(error)")
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("Error saving BP sessions: \(error)")
                completion(.failure(error))
            } else {
                print("Successfully saved \(sessions.count) BP sessions to organized structure")
                completion(.success(()))
            }
        }
    }
    
    func loadBPSessions(completion: @escaping (Result<[BPSession], Error>) -> Void) {
        guard let collection = dataTypeCollection(.bloodPressureSession) else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        print("Loading BP sessions from Firestore...")
        collection.order(by: "startTime", descending: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error loading BP sessions: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No BP sessions found in Firestore")
                completion(.success([]))
                return
            }
            
            print("Found \(documents.count) BP session documents in Firestore")
            
            var sessions: [BPSession] = []
            
            for document in documents {
                do {
                    var documentData = document.data()
                    
                    // Remove the extra fields we added for Firestore
                    documentData.removeValue(forKey: "dataType")
                    documentData.removeValue(forKey: "createdAt")
                    documentData.removeValue(forKey: "updatedAt")
                    documentData.removeValue(forKey: "isEncrypted")
                    documentData.removeValue(forKey: "encryptedData")
                    
                    let session = try Firestore.Decoder().decode(BPSession.self, from: documentData)
                    sessions.append(session)
                } catch {
                    print("Error decoding BP session: \(error)")
                }
            }
            
            print("Successfully loaded \(sessions.count) BP sessions from Firestore")
            completion(.success(sessions))
        }
    }
    
    // MARK: - Fitness Sessions (using unified structure)
    
    func saveFitnessSessions(_ sessions: [FitnessSession], completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let collection = dataTypeCollection(.fitnessSession) else {
            print("Error: No authenticated user for saving fitness sessions")
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let batch = db.batch()
        
        for (index, session) in sessions.enumerated() {
            do {
                var sessionData = try Firestore.Encoder().encode(session)
                sessionData["dataType"] = "fitness_session"
                sessionData["createdAt"] = Timestamp(date: session.startTime)
                sessionData["updatedAt"] = Timestamp(date: Date())
                
                let docRef = collection.document(session.id.uuidString)
                batch.setData(sessionData, forDocument: docRef)
            } catch {
                print("Error encoding fitness session \(index): \(error)")
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("Error saving fitness sessions: \(error)")
                completion(.failure(error))
            } else {
                print("Successfully saved \(sessions.count) fitness sessions to organized structure")
                completion(.success(()))
            }
        }
    }
    
    func loadFitnessSessions(completion: @escaping (Result<[FitnessSession], Error>) -> Void) {
        guard let collection = userCollection() else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let sessionsCollection = collection.document("fitness_sessions").collection("sessions")
        sessionsCollection.whereField("type", isEqualTo: "fitness_session").order(by: "startTime", descending: true).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var sessions: [FitnessSession] = []
            let sessionsQueue = DispatchQueue(label: "sessions.queue", attributes: .concurrent)
            
            for document in documents {
                dispatchGroup.enter()
                
                let data = document.data()
                guard let idString = data["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let startTimeTimestamp = data["startTime"] as? Timestamp,
                      let isActive = data["isActive"] as? Bool,
                      let isPaused = data["isPaused"] as? Bool,
                      let isCompleted = data["isCompleted"] as? Bool else {
                    print("Error: Missing required fields in fitness session data")
                    dispatchGroup.leave()
                    continue
                }
                
                let startTime = startTimeTimestamp.dateValue()
                let endTime = (data["endTime"] as? Timestamp)?.dateValue()
                
                // Load exercises for this session
                let exerciseCollection = document.reference.collection("exercises")
                exerciseCollection.getDocuments { exerciseSnapshot, exerciseError in
                    if let exerciseError = exerciseError {
                        print("Error loading exercises: \(exerciseError)")
                        dispatchGroup.leave()
                        return
                    }
                    
                    var exerciseSessions: [ExerciseSession] = []
                    let exerciseDispatchGroup = DispatchGroup()
                    
                    for exerciseDoc in exerciseSnapshot?.documents ?? [] {
                        exerciseDispatchGroup.enter()
                        
                        let exerciseData = exerciseDoc.data()
                        guard let exerciseIdString = exerciseData["id"] as? String,
                              let exerciseId = UUID(uuidString: exerciseIdString),
                              let exerciseTypeString = exerciseData["exerciseType"] as? String,
                              let exerciseType = ExerciseType(rawValue: exerciseTypeString),
                              let exerciseStartTimeTimestamp = exerciseData["startTime"] as? Timestamp,
                              let exerciseIsCompleted = exerciseData["isCompleted"] as? Bool else {
                            print("Error: Missing required fields in exercise session data")
                            exerciseDispatchGroup.leave()
                            continue
                        }
                        
                        let exerciseStartTime = exerciseStartTimeTimestamp.dateValue()
                        let exerciseEndTime = (exerciseData["endTime"] as? Timestamp)?.dateValue()
                        
                        // Load sets from the exercise document
                        var sets: [ExerciseSet] = []
                        
                        // First try to load sets from the exercise document itself
                        if let setsData = exerciseData["sets"] as? [[String: Any]] {
                            print("    - Loading sets from exercise document: \(setsData.count) sets")
                            for setData in setsData {
                                guard let setIdString = setData["id"] as? String,
                                      let setId = UUID(uuidString: setIdString),
                                      let timestampTimestamp = setData["timestamp"] as? Timestamp else {
                                    print("Error: Missing required fields in set data from exercise document")
                                    continue
                                }
                                
                                let reps = setData["reps"] as? Int
                                let weight = setData["weight"] as? Double
                                let time = setData["time"] as? TimeInterval
                                let timestamp = timestampTimestamp.dateValue()
                                
                                print("    - Parsed set from exercise doc: ID=\(setId), reps=\(reps ?? 0), weight=\(weight ?? 0), time=\(time ?? 0)")
                                
                                let set = ExerciseSet(id: setId, reps: reps, weight: weight, time: time, timestamp: timestamp)
                                sets.append(set)
                            }
                        } else {
                            // Fallback: Load sets from subcollection if not in exercise document
                            print("    - No sets found in exercise document, trying subcollection...")
                            let setsCollection = exerciseDoc.reference.collection("sets")
                            setsCollection.getDocuments { setsSnapshot, setsError in
                                if let setsError = setsError {
                                    print("Error loading sets from subcollection: \(setsError)")
                                } else {
                                    for setDoc in setsSnapshot?.documents ?? [] {
                                        let setData = setDoc.data()
                                        print("    - Loading set data from subcollection: \(setData)")
                                        
                                        guard let setIdString = setData["id"] as? String,
                                              let setId = UUID(uuidString: setIdString),
                                              let timestampTimestamp = setData["timestamp"] as? Timestamp else {
                                            print("Error: Missing required fields in set data from subcollection")
                                            continue
                                        }
                                        
                                        let reps = setData["reps"] as? Int
                                        let weight = setData["weight"] as? Double
                                        let time = setData["time"] as? TimeInterval
                                        let timestamp = timestampTimestamp.dateValue()
                                        
                                        print("    - Parsed set from subcollection: ID=\(setId), reps=\(reps ?? 0), weight=\(weight ?? 0), time=\(time ?? 0)")
                                        
                                        let set = ExerciseSet(id: setId, reps: reps, weight: weight, time: time, timestamp: timestamp)
                                        sets.append(set)
                                    }
                                }
                                
                                var exerciseSession = ExerciseSession(exerciseType: exerciseType, startTime: exerciseStartTime)
                                exerciseSession.id = exerciseId
                                exerciseSession.sets = sets
                                exerciseSession.endTime = exerciseEndTime
                                exerciseSession.isCompleted = exerciseIsCompleted
                                exerciseSessions.append(exerciseSession)
                                
                                exerciseDispatchGroup.leave()
                            }
                            return
                        }
                        
                        var exerciseSession = ExerciseSession(exerciseType: exerciseType, startTime: exerciseStartTime)
                        exerciseSession.id = exerciseId
                        exerciseSession.sets = sets
                        exerciseSession.endTime = exerciseEndTime
                        exerciseSession.isCompleted = exerciseIsCompleted
                        exerciseSessions.append(exerciseSession)
                        
                        exerciseDispatchGroup.leave()
                    }
                    
                    exerciseDispatchGroup.notify(queue: .main) {
                        var fitnessSession = FitnessSession(startTime: startTime)
                        fitnessSession.id = id
                        fitnessSession.exerciseSessions = exerciseSessions
                        fitnessSession.endTime = endTime
                        fitnessSession.isActive = isActive
                        fitnessSession.isPaused = isPaused
                        fitnessSession.isCompleted = isCompleted
                        
                        sessionsQueue.async(flags: .barrier) {
                            sessions.append(fitnessSession)
                        }
                        
                        dispatchGroup.leave()
                    }
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(.success(sessions))
            }
        }
    }
    
    func updateFitnessSession(_ session: FitnessSession, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let collection = userCollection() else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let sessionsCollection = collection.document("fitness_sessions").collection("sessions")
        let sessionDoc = sessionsCollection.document(session.id.uuidString)
        
        do {
            var sessionData = try Firestore.Encoder().encode(session)
            sessionData["type"] = "fitness_session"
            sessionData["updatedAt"] = Timestamp(date: Date())
            
            // Save the main session document
            sessionDoc.setData(sessionData) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                // Update exercises subcollection
                let exerciseCollection = sessionDoc.collection("exercises")
                
                // First, delete all existing exercises
                exerciseCollection.getDocuments { snapshot, error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }
                    
                    let batch = self.db.batch()
                    
                    // Delete existing exercises
                    if let documents = snapshot?.documents {
                        for document in documents {
                            batch.deleteDocument(document.reference)
                        }
                    }
                    
                    // Add new exercises
                    for exercise in session.exerciseSessions {
                        let exerciseDoc = exerciseCollection.document(exercise.id.uuidString)
                        
                        do {
                            var exerciseData = try Firestore.Encoder().encode(exercise)
                            exerciseData["type"] = "exercise_session"
                            batch.setData(exerciseData, forDocument: exerciseDoc)
                            
                            // Add sets subcollection
                            let setsCollection = exerciseDoc.collection("sets")
                            for set in exercise.sets {
                                let setDoc = setsCollection.document(set.id.uuidString)
                                
                                do {
                                    var setData = try Firestore.Encoder().encode(set)
                                    setData["type"] = "exercise_set"
                                    batch.setData(setData, forDocument: setDoc)
                                } catch {
                                    print("Error encoding set: \(error)")
                                }
                            }
                        } catch {
                            print("Error encoding exercise: \(error)")
                        }
                    }
                    
                    // Commit the batch
                    batch.commit { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - User Profile
    
    func saveUserProfile(_ profile: UserProfile) {
        guard let userID = userID else { return }
        
        let userDoc = db.collection("users").document(userID)
        
        do {
            let data = try Firestore.Encoder().encode(profile)
            userDoc.setData(data, merge: true) { error in
                if let error = error {
                    print("Error saving user profile: \(error)")
                }
            }
        } catch {
            print("Error encoding user profile: \(error)")
        }
    }
    
    func loadUserProfile(completion: @escaping (Result<UserProfile?, Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let userDoc = db.collection("users").document(userID)
        userDoc.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                completion(.success(nil))
                return
            }
            
            do {
                let profile = try Firestore.Decoder().decode(UserProfile.self, from: document.data() ?? [:])
                completion(.success(profile))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Sync All Data
    
    func syncAllData(bpSessions: [BPSession], fitnessSessions: [FitnessSession], userProfile: UserProfile?, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        let group = DispatchGroup()
        var hasError = false
        var lastError: Error?
        
        group.enter()
        saveBPSessions(bpSessions) { result in
            switch result {
            case .success:
                print("BP sessions synced successfully")
            case .failure(let error):
                print("Error syncing BP sessions: \(error)")
                hasError = true
                lastError = error
            }
            group.leave()
        }
        
        group.enter()
        saveFitnessSessions(fitnessSessions) { result in
            switch result {
            case .success:
                print("Fitness sessions synced successfully")
            case .failure(let error):
                print("Error syncing fitness sessions: \(error)")
                hasError = true
                lastError = error
            }
            group.leave()
        }
        
        if let profile = userProfile {
            group.enter()
            saveUserProfile(profile)
            group.leave()
        }
        
        group.notify(queue: .main) {
            if hasError, let error = lastError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func loadAllData(completion: @escaping (Result<(bpSessions: [BPSession], fitnessSessions: [FitnessSession], userProfile: UserProfile?), Error>) -> Void) {
        let group = DispatchGroup()
        var bpSessions: [BPSession] = []
        var fitnessSessions: [FitnessSession] = []
        var userProfile: UserProfile?
        var error: Error?
        
        group.enter()
        loadBPSessions { result in
            switch result {
            case .success(let sessions):
                bpSessions = sessions
            case .failure(let err):
                error = err
            }
            group.leave()
        }
        
        group.enter()
        loadFitnessSessions { result in
            switch result {
            case .success(let sessions):
                fitnessSessions = sessions
            case .failure(let err):
                error = err
            }
            group.leave()
        }
        
        group.enter()
        loadUserProfile { result in
            switch result {
            case .success(let profile):
                userProfile = profile
            case .failure(let err):
                error = err
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success((bpSessions: bpSessions, fitnessSessions: fitnessSessions, userProfile: userProfile)))
            }
        }
    }
    
    // MARK: - Personal Records (One Rep Max) Management
    
    func savePersonalRecords(_ records: [OneRepMax], completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let collection = dataTypeCollection(.personalRecords) else {
            print("Error: No authenticated user for saving personal records")
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let batch = db.batch()
        
        for (index, record) in records.enumerated() {
            do {
                var recordData = try Firestore.Encoder().encode(record)
                recordData["dataType"] = "personal_record"
                recordData["createdAt"] = Timestamp(date: record.date)
                recordData["updatedAt"] = Timestamp(date: Date())
                
                // Store OneRepMax data directly (personal records are not as sensitive as health data)
                // We can add encryption later if needed, but for now store directly for better compatibility
                
                let docRef = collection.document(record.id.uuidString)
                batch.setData(recordData, forDocument: docRef)
            } catch {
                print("Error encoding personal record \(index): \(error)")
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("Error saving personal records: \(error)")
                completion(.failure(error))
            } else {
                print("Successfully saved \(records.count) personal records to Firestore")
                completion(.success(()))
            }
        }
    }
    
    func loadPersonalRecords(completion: @escaping (Result<[OneRepMax], Error>) -> Void) {
        guard let collection = dataTypeCollection(.personalRecords) else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        print("Loading personal records from Firestore...")
        collection.order(by: "createdAt", descending: true).getDocuments { snapshot, error in
            if let error = error {
                print("Error loading personal records: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No personal records found in Firestore")
                completion(.success([]))
                return
            }
            
            print("Found \(documents.count) personal record documents in Firestore")
            
            var records: [OneRepMax] = []
            
            for document in documents {
                do {
                    var documentData = document.data()
                    
                    // Remove the extra fields we added for Firestore
                    documentData.removeValue(forKey: "dataType")
                    documentData.removeValue(forKey: "createdAt")
                    documentData.removeValue(forKey: "updatedAt")
                    documentData.removeValue(forKey: "isEncrypted")
                    documentData.removeValue(forKey: "encryptedData")
                    
                    let record = try Firestore.Decoder().decode(OneRepMax.self, from: documentData)
                    records.append(record)
                } catch {
                    print("Error decoding personal record: \(error)")
                }
            }
            
            print("Successfully loaded \(records.count) personal records from Firestore")
            completion(.success(records))
        }
    }
    
    func updatePersonalRecord(_ record: OneRepMax, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let collection = dataTypeCollection(.personalRecords) else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let docRef = collection.document(record.id.uuidString)
        
        do {
            var recordData = try Firestore.Encoder().encode(record)
            recordData["dataType"] = "personal_record"
            recordData["updatedAt"] = Timestamp(date: Date())
            
            // Store OneRepMax data directly (personal records are not as sensitive as health data)
            // We can add encryption later if needed, but for now store directly for better compatibility
            
            docRef.setData(recordData, merge: true) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func deletePersonalRecord(_ record: OneRepMax, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let collection = dataTypeCollection(.personalRecords) else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let docRef = collection.document(record.id.uuidString)
        
        docRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func saveCustomLifts(_ customLifts: [String], completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let customLiftsRef = db.collection("users").document(userID).collection("custom_lifts").document("lifts")
        
        let data: [String: Any] = [
            "customLifts": customLifts,
            "updatedAt": Timestamp(date: Date())
        ]
        
        customLiftsRef.setData(data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func loadCustomLifts(completion: @escaping (Result<[String], Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let customLiftsRef = db.collection("users").document(userID).collection("custom_lifts").document("lifts")
        
        customLiftsRef.getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let customLifts = data["customLifts"] as? [String] else {
                completion(.success([]))
                return
            }
            
            completion(.success(customLifts))
        }
    }
    

    // MARK: - Custom Workout Management
    
    func saveCustomWorkout(_ workout: CustomWorkout, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let workoutRef = db.collection("users").document(userID).collection("custom_workouts").document(workout.id.uuidString)
        
        do {
            var workoutData = try Firestore.Encoder().encode(workout)
            workoutData["createdAt"] = Timestamp(date: workout.createdDate)
            workoutData["updatedAt"] = Timestamp(date: Date())
            
            workoutRef.setData(workoutData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func loadCustomWorkouts(completion: @escaping (Result<[CustomWorkout], Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let workoutsRef = db.collection("users").document(userID).collection("custom_workouts")
            .order(by: "createdAt", descending: true)
        
        workoutsRef.getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            var workouts: [CustomWorkout] = []
            for document in documents {
                do {
                    var workoutData = document.data()
                    // Convert Firestore timestamps back to Date
                    if let createdAt = workoutData["createdAt"] as? Timestamp {
                        workoutData["createdDate"] = createdAt.dateValue()
                    }
                    if let lastUsed = workoutData["lastUsed"] as? Timestamp {
                        workoutData["lastUsed"] = lastUsed.dateValue()
                    }
                    
                    let workout = try Firestore.Decoder().decode(CustomWorkout.self, from: workoutData)
                    workouts.append(workout)
                } catch {
                    print("Error decoding custom workout: \(error)")
                }
            }
            
            completion(.success(workouts))
        }
    }
    
    func updateCustomWorkout(_ workout: CustomWorkout, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let workoutRef = db.collection("users").document(userID).collection("custom_workouts").document(workout.id.uuidString)
        
        do {
            var workoutData = try Firestore.Encoder().encode(workout)
            workoutData["updatedAt"] = Timestamp(date: Date())
            
            workoutRef.updateData(workoutData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteCustomWorkout(_ workout: CustomWorkout, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let workoutRef = db.collection("users").document(userID).collection("custom_workouts").document(workout.id.uuidString)
        
        workoutRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Nutrition Data Management
    
    func saveNutritionEntry(_ entry: NutritionEntry, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        print("=== FIRESTORE SAVE NUTRITION ENTRY CALLED ===")
        print("Entry ID: \(entry.id)")
        print("User ID: \(userID ?? "nil")")
        print("Entry Date: \(entry.date)")
        
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        // Convert NutritionEntry to UnifiedHealthData
        let unifiedData = UnifiedHealthData(
            id: entry.id,
            dataType: .nutritionEntry,
            nutritionEntry: entry,
            timestamp: entry.date
        )
        
        // Use new date-based collections ONLY
        let userCollection = nutritionEntryCollection(for: entry.date)
        let rootCollection = rootNutritionEntryCollection(for: entry.date)
        
        print("=== COLLECTION PATHS ===")
        print("Date-based user collection: \(userCollection?.path ?? "nil")")
        print("Date-based root collection: \(rootCollection?.path ?? "nil")")
        
        let dispatchGroup = DispatchGroup()
        var hasError = false
        var lastError: Error?
        
        // Save to new date-based user collection
        if let userCollection = userCollection {
            dispatchGroup.enter()
            do {
                let data = try JSONEncoder().encode(unifiedData)
                let documentData = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                
                userCollection.document(entry.id.uuidString).setData(documentData) { error in
                    if let error = error {
                        print("Error saving nutrition entry to date-based user collection: \(error)")
                        hasError = true
                        lastError = error
                    } else {
                        print("Successfully saved nutrition entry to date-based user collection")
                    }
                    dispatchGroup.leave()
                }
            } catch {
                print("Error encoding nutrition entry: \(error)")
                hasError = true
                lastError = error
                dispatchGroup.leave()
            }
        }
        
        // Save to new date-based root collection
        if let rootCollection = rootCollection {
            dispatchGroup.enter()
            do {
                let data = try JSONEncoder().encode(unifiedData)
                let documentData = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
                
                rootCollection.document(entry.id.uuidString).setData(documentData) { error in
                    if let error = error {
                        print("Error saving nutrition entry to date-based root collection: \(error)")
                        hasError = true
                        lastError = error
                    } else {
                        print("Successfully saved nutrition entry to date-based root collection")
                    }
                    dispatchGroup.leave()
                }
            } catch {
                print("Error encoding nutrition entry: \(error)")
                hasError = true
                lastError = error
                dispatchGroup.leave()
            }
        }
        
        
        dispatchGroup.notify(queue: .main) {
            if hasError {
                completion(.failure(lastError ?? FirestoreError.unknown))
            } else {
                print("Successfully saved nutrition entry to Firestore")
                completion(.success(()))
            }
        }
    }
    
    func loadNutritionEntries(completion: @escaping (Result<[NutritionEntry], Error>) -> Void) {
        print("=== FIRESTORE LOAD NUTRITION ENTRIES CALLED ===")
        print("User ID: \(userID ?? "nil")")
        
        loadHealthData(dataType: .nutritionEntry) { result in
            switch result {
            case .success(let healthData):
                let nutritionEntries = healthData.compactMap { data -> NutritionEntry? in
                    return data.nutritionEntry
                }
                print("Successfully loaded \(nutritionEntries.count) nutrition entries from Firestore")
                completion(.success(nutritionEntries))
                
            case .failure(let error):
                print("Error loading nutrition entries: \(error)")
                completion(.failure(error))
            }
        }
    }
    
    func loadNutritionEntriesForDate(_ date: Date, completion: @escaping (Result<[NutritionEntry], Error>) -> Void) {
        print("=== FIRESTORE LOAD NUTRITION ENTRIES FOR DATE CALLED ===")
        print("Date: \(date)")
        print("User ID: \(userID ?? "nil")")
        
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        // Use user-specific date-based collections ONLY to prevent data leakage
        guard let userCollection = nutritionEntryCollection(for: date) else {
            print("Error: No user collection available for loading nutrition entries for date")
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        print("Loading nutrition entries from user-specific date-based collection only: \(userCollection.path)")
        tryLoadNutritionEntriesFromDateBasedCollections([userCollection], completion: completion)
    }
    
    // New method specifically for loading from date-based collections
    private func tryLoadNutritionEntriesFromDateBasedCollections(_ collections: [CollectionReference], completion: @escaping (Result<[NutritionEntry], Error>) -> Void) {
        var remainingCollections = collections
        var isCompleted = false
        
        func tryNextCollection() {
            guard !remainingCollections.isEmpty else {
                if !isCompleted {
                    isCompleted = true
                    completion(.success([]))
                }
                return
            }
            
            let collection = remainingCollections.removeFirst()
            print("Trying to load from collection: \(collection.path)")
            
            // For date-based collections, just get all documents (they're already filtered by date)
            collection.getDocuments { snapshot, error in
                guard !isCompleted else { return }
                
                if let error = error {
                    print("Error loading nutrition entries from \(collection.path): \(error)")
                    // Try next collection
                    tryNextCollection()
                    return
                }
                
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No documents found in \(collection.path)")
                    // Try next collection
                    tryNextCollection()
                    return
                }
                
                print("Found \(documents.count) documents in \(collection.path)")
                
                var entries: [NutritionEntry] = []
                for document in documents {
                    do {
                        let data = document.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let unifiedData = try JSONDecoder().decode(UnifiedHealthData.self, from: jsonData)
                        
                        if let nutritionEntry = unifiedData.nutritionEntry {
                            entries.append(nutritionEntry)
                        }
                    } catch {
                        print("Error decoding nutrition entry from document \(document.documentID): \(error)")
                    }
                }
                
                if !isCompleted {
                    isCompleted = true
                    print("Successfully loaded \(entries.count) nutrition entries from date-based collection")
                    completion(.success(entries))
                }
            }
        }
        
        tryNextCollection()
    }
    
    private func tryLoadNutritionEntriesFromCollections(_ collections: [CollectionReference], startDate: Date, endDate: Date, completion: @escaping (Result<[NutritionEntry], Error>) -> Void) {
        guard !collections.isEmpty else {
            print("No more collections to try for nutrition entries")
            completion(.success([]))
            return
        }
        
        let collection = collections[0]
        let remainingCollections = Array(collections.dropFirst())
        
        print("Trying to load nutrition entries from collection: \(collection.path)")
        
        var isCompleted = false
        
        // Add timeout for individual requests
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            guard !isCompleted else { return }
            isCompleted = true
            print("Timeout loading nutrition entries from \(collection.path)")
            // Try next collection if available
            if !remainingCollections.isEmpty {
                self.tryLoadNutritionEntriesFromCollections(remainingCollections, startDate: startDate, endDate: endDate, completion: completion)
            } else {
                completion(.success([]))
            }
        }
        
        // Check if this is a date-based collection (contains "entries" in path)
        let isDateBasedCollection = collection.path.contains("entries")
        
        if isDateBasedCollection {
            // For date-based collections, just get all documents (they're already filtered by date)
            collection.getDocuments { snapshot, error in
                guard !isCompleted else { return }
                isCompleted = true
                
                if let error = error {
                    print("Error loading nutrition entries from \(collection.path): \(error)")
                    
                    // Try next collection if available
                    if !remainingCollections.isEmpty {
                        self.tryLoadNutritionEntriesFromCollections(remainingCollections, startDate: startDate, endDate: endDate, completion: completion)
                    } else {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No nutrition entries found in \(collection.path) for date")
                    // Try next collection if available
                    if !remainingCollections.isEmpty {
                        self.tryLoadNutritionEntriesFromCollections(remainingCollections, startDate: startDate, endDate: endDate, completion: completion)
                    } else {
                        completion(.success([]))
                    }
                    return
                }
                
                print("Found \(documents.count) nutrition entries in \(collection.path) for date")
                
                // Parse documents
                var nutritionEntries: [NutritionEntry] = []
                for document in documents {
                    do {
                        let data = document.data()
                        let jsonData = try JSONSerialization.data(withJSONObject: data)
                        let unifiedData = try JSONDecoder().decode(UnifiedHealthData.self, from: jsonData)
                        
                        if let nutritionEntry = unifiedData.nutritionEntry {
                            nutritionEntries.append(nutritionEntry)
                        }
                    } catch {
                        print("Error parsing nutrition entry document \(document.documentID): \(error)")
                    }
                }
                
                print("Successfully parsed \(nutritionEntries.count) nutrition entries")
                completion(.success(nutritionEntries))
            }
        } else {
            // For old collections, use date range filtering
            collection
                .whereField("timestamp", isGreaterThanOrEqualTo: startDate)
                .whereField("timestamp", isLessThan: endDate)
                .getDocuments { snapshot, error in
                    guard !isCompleted else { return }
                    isCompleted = true
                    
                    if let error = error {
                        print("Error loading nutrition entries from \(collection.path): \(error)")
                        
                        // Try next collection if available
                        if !remainingCollections.isEmpty {
                            self.tryLoadNutritionEntriesFromCollections(remainingCollections, startDate: startDate, endDate: endDate, completion: completion)
                        } else {
                            completion(.failure(error))
                        }
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No nutrition entries found in \(collection.path) for date range")
                        // Try next collection if available
                        if !remainingCollections.isEmpty {
                            self.tryLoadNutritionEntriesFromCollections(remainingCollections, startDate: startDate, endDate: endDate, completion: completion)
                        } else {
                            completion(.success([]))
                        }
                        return
                    }
                    
                    print("Found \(documents.count) nutrition entries in \(collection.path) for date range")
                    
                    // Parse documents
                    var nutritionEntries: [NutritionEntry] = []
                    for document in documents {
                        do {
                            let data = document.data()
                            let jsonData = try JSONSerialization.data(withJSONObject: data)
                            let unifiedData = try JSONDecoder().decode(UnifiedHealthData.self, from: jsonData)
                            
                            if let nutritionEntry = unifiedData.nutritionEntry {
                                nutritionEntries.append(nutritionEntry)
                            }
                        } catch {
                            print("Error parsing nutrition entry document \(document.documentID): \(error)")
                        }
                    }
                    
                    print("Successfully parsed \(nutritionEntries.count) nutrition entries")
                    completion(.success(nutritionEntries))
                }
        }
    }
    
    func deleteNutritionEntry(_ entry: NutritionEntry, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        print("=== FIRESTORE DELETE NUTRITION ENTRY CALLED ===")
        print("Entry ID: \(entry.id)")
        print("User ID: \(userID ?? "nil")")
        
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let userCollection = dataTypeCollection(.nutritionEntry)
        let rootCollection = rootDataTypeCollection(.nutritionEntry)
        
        let dispatchGroup = DispatchGroup()
        var hasError = false
        var lastError: Error?
        
        // Delete from user-specific collection
        if let userCollection = userCollection {
            dispatchGroup.enter()
            userCollection.document(entry.id.uuidString).delete { error in
                if let error = error {
                    print("Error deleting nutrition entry from user collection: \(error)")
                    hasError = true
                    lastError = error
                } else {
                    print("Successfully deleted nutrition entry from user collection")
                }
                dispatchGroup.leave()
            }
        }
        
        // Delete from root collection
        if let rootCollection = rootCollection {
            dispatchGroup.enter()
            rootCollection.document(entry.id.uuidString).delete { error in
                if let error = error {
                    print("Error deleting nutrition entry from root collection: \(error)")
                    hasError = true
                    lastError = error
                } else {
                    print("Successfully deleted nutrition entry from root collection")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if hasError {
                completion(.failure(lastError ?? FirestoreError.unknown))
            } else {
                print("Successfully deleted nutrition entry from Firestore")
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Custom Exercise Management
    
    func saveCustomExercise(_ exercise: CustomExercise, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        print("=== FIRESTORE SAVE CUSTOM EXERCISE CALLED ===")
        print("Exercise ID: \(exercise.id)")
        print("Exercise Name: \(exercise.name)")
        print("Exercise Category: \(exercise.category.rawValue)")
        print("User ID: \(userID ?? "nil")")
        
        guard let userID = userID else {
            print("No authenticated user")
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        do {
            let data = try JSONEncoder().encode(exercise)
            let documentData = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
            
            let userCollection = db.collection("users").document(userID).collection("custom_exercises")
            let rootCollection = db.collection("custom_exercises")
            
            let dispatchGroup = DispatchGroup()
            var hasError = false
            var lastError: Error?
            
            // Save to user collection
            dispatchGroup.enter()
            userCollection.document(exercise.id.uuidString).setData(documentData) { error in
                if let error = error {
                    print("Error saving custom exercise to user collection: \(error)")
                    hasError = true
                    lastError = error
                } else {
                    print("Successfully saved custom exercise to user collection")
                }
                dispatchGroup.leave()
            }
            
            // Save to root collection
            dispatchGroup.enter()
            rootCollection.document(exercise.id.uuidString).setData(documentData) { error in
                if let error = error {
                    print("Error saving custom exercise to root collection: \(error)")
                    hasError = true
                    lastError = error
                } else {
                    print("Successfully saved custom exercise to root collection")
                }
                dispatchGroup.leave()
            }
            
            dispatchGroup.notify(queue: .main) {
                if hasError {
                    completion(.failure(lastError ?? FirestoreError.unknown))
                } else {
                    print("Successfully saved custom exercise to Firestore")
                    completion(.success(()))
                }
            }
            
        } catch {
            print("Error encoding custom exercise: \(error)")
            completion(.failure(error))
        }
    }
    
    func loadCustomExercises(completion: @escaping (Result<[CustomExercise], Error>) -> Void) {
        print("=== FIRESTORE LOAD CUSTOM EXERCISES CALLED ===")
        print("User ID: \(userID ?? "nil")")
        
        guard let userID = userID else {
            print("No authenticated user")
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let userCollection = db.collection("users").document(userID).collection("custom_exercises")
        let rootCollection = db.collection("custom_exercises")
        
        let collections = [userCollection, rootCollection]
        var allExercises: [CustomExercise] = []
        let dispatchGroup = DispatchGroup()
        var hasError = false
        var lastError: Error?
        
        for collection in collections {
            dispatchGroup.enter()
            collection.getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading custom exercises from collection: \(error)")
                    hasError = true
                    lastError = error
                } else if let documents = snapshot?.documents {
                    print("Found \(documents.count) custom exercise documents in collection")
                    for document in documents {
                        do {
                            let data = try JSONSerialization.data(withJSONObject: document.data())
                            let exercise = try JSONDecoder().decode(CustomExercise.self, from: data)
                            allExercises.append(exercise)
                        } catch {
                            print("Error decoding custom exercise: \(error)")
                            hasError = true
                            lastError = error
                        }
                    }
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if hasError {
                completion(.failure(lastError ?? FirestoreError.unknown))
            } else {
                // Remove duplicates based on ID
                let uniqueExercises = Array(Set(allExercises.map { $0.id })).compactMap { id in
                    allExercises.first { $0.id == id }
                }
                print("Successfully loaded \(uniqueExercises.count) custom exercises from Firestore")
                completion(.success(uniqueExercises))
            }
        }
    }
    
    func deleteCustomExercise(_ exercise: CustomExercise, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        print("=== FIRESTORE DELETE CUSTOM EXERCISE CALLED ===")
        print("Exercise ID: \(exercise.id)")
        print("User ID: \(userID ?? "nil")")
        
        guard let userID = userID else {
            print("No authenticated user")
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        let userCollection = db.collection("users").document(userID).collection("custom_exercises")
        let rootCollection = db.collection("custom_exercises")
        
        let dispatchGroup = DispatchGroup()
        var hasError = false
        var lastError: Error?
        
        // Delete from user collection
        dispatchGroup.enter()
        userCollection.document(exercise.id.uuidString).delete { error in
            if let error = error {
                print("Error deleting custom exercise from user collection: \(error)")
                hasError = true
                lastError = error
            } else {
                print("Successfully deleted custom exercise from user collection")
            }
            dispatchGroup.leave()
        }
        
        // Delete from root collection
        dispatchGroup.enter()
        rootCollection.document(exercise.id.uuidString).delete { error in
            if let error = error {
                print("Error deleting custom exercise from root collection: \(error)")
                hasError = true
                lastError = error
            } else {
                print("Successfully deleted custom exercise from root collection")
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) {
            if hasError {
                completion(.failure(lastError ?? FirestoreError.unknown))
            } else {
                print("Successfully deleted custom exercise from Firestore")
                completion(.success(()))
            }
        }
    }
}

// MARK: - User Profile Model

struct UserProfile: Codable {
    let id: String
    let email: String
    let displayName: String?
    let photoURL: String?
    let createdAt: Date
    let lastUpdated: Date
    let preferences: UserPreferences
    
    init(id: String, email: String, displayName: String? = nil, photoURL: String? = nil, preferences: UserPreferences = UserPreferences()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = Date()
        self.lastUpdated = Date()
        self.preferences = preferences
    }
}

struct UserPreferences: Codable {
    let units: String // "metric" or "imperial"
    let notificationsEnabled: Bool
    let reminderTime: String?
    let theme: String // "light", "dark", "system"
    
    init(units: String = "imperial", notificationsEnabled: Bool = true, reminderTime: String? = nil, theme: String = "system") {
        self.units = units
        self.notificationsEnabled = notificationsEnabled
        self.reminderTime = reminderTime
        self.theme = theme
    }
}

// MARK: - Unified Health Data Models

enum HealthDataType: String, CaseIterable, Codable {
    case healthMetric = "health_metric"
    case bloodPressureSession = "bp_session"
    case fitnessSession = "fitness_session"
    case weight = "weight"
    case bloodSugar = "blood_sugar"
    case heartRate = "heart_rate"
    case bodyFat = "body_fat"
    case leanBodyMass = "lean_body_mass"
    case personalRecords = "personal_records"
    case nutritionEntry = "nutrition_entry"
    case nutritionGoals = "nutrition_goals"
}

// MARK: - Nutrition Goals Firestore Methods

extension FirestoreService {
    func saveNutritionGoals(_ goals: NutritionGoals, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        print("=== FIRESTORE SAVE NUTRITION GOALS CALLED ===")
        print("User ID: \(userID ?? "nil")")
        
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        do {
            let data = try JSONEncoder().encode(goals)
            let goalsData: [String: Any] = [
                "goals": data,
                "timestamp": Date(),
                "userID": userID
            ]
            
            let userCollection = dataTypeCollection(.nutritionGoals)
            let rootCollection = rootDataTypeCollection(.nutritionGoals)
            
            let dispatchGroup = DispatchGroup()
            var hasError = false
            var lastError: Error?
            
            // Save to user-specific collection
            if let userCollection = userCollection {
                dispatchGroup.enter()
                userCollection.document("goals").setData(goalsData) { error in
                    if let error = error {
                        print("Error saving nutrition goals to user collection: \(error)")
                        hasError = true
                        lastError = error
                    } else {
                        print("Successfully saved nutrition goals to user collection")
                    }
                    dispatchGroup.leave()
                }
            }
            
            // Save to root collection
            if let rootCollection = rootCollection {
                dispatchGroup.enter()
                rootCollection.document("\(userID)_goals").setData(goalsData) { error in
                    if let error = error {
                        print("Error saving nutrition goals to root collection: \(error)")
                        hasError = true
                        lastError = error
                    } else {
                        print("Successfully saved nutrition goals to root collection")
                    }
                    dispatchGroup.leave()
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                if hasError {
                    completion(.failure(lastError ?? FirestoreError.unknown))
                } else {
                    completion(.success(()))
                }
            }
            
        } catch {
            print("Error encoding nutrition goals: \(error)")
            completion(.failure(FirestoreError.encodingError))
        }
    }
    
    func loadNutritionGoals(completion: @escaping (Result<NutritionGoals, Error>) -> Void) {
        print("=== FIRESTORE LOAD NUTRITION GOALS CALLED ===")
        print("User ID: \(userID ?? "nil")")
        
        guard let userID = userID else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        // Only use user-specific collection to prevent data leakage
        guard let userCollection = dataTypeCollection(.nutritionGoals) else {
            print("Error: No user collection available for loading nutrition goals")
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        print("Loading nutrition goals from user-specific collection only: \(userCollection.path)")
        userCollection.document("goals").getDocument { document, error in
            if let error = error {
                print("Error loading nutrition goals from user collection: \(error)")
                completion(.failure(error))
            } else if let document = document, document.exists, let data = document.data() {
                if let goalsData = data["goals"] as? Data {
                    do {
                        let goals = try JSONDecoder().decode(NutritionGoals.self, from: goalsData)
                        print("Successfully loaded nutrition goals from user collection")
                        completion(.success(goals))
                    } catch {
                        print("Error decoding nutrition goals: \(error)")
                        completion(.failure(FirestoreError.decodingError(error.localizedDescription)))
                    }
                } else {
                    print("No nutrition goals data found in user collection")
                    completion(.success(NutritionGoals()))
                }
            } else {
                print("No nutrition goals document found in user collection")
                completion(.success(NutritionGoals()))
            }
        }
    }
    
}

struct UnifiedHealthData: Codable, Identifiable {
    let id: UUID
    let dataType: HealthDataType
    let timestamp: Date
    
    // Optional fields for different data types
    let metricType: MetricType?
    let value: Double?
    let unit: String?
    let bpSession: BPSession?
    let fitnessSession: FitnessSession?
    let nutritionEntry: NutritionEntry?
    
    // Health metric constructor
    init(id: UUID, dataType: HealthDataType, metricType: MetricType, value: Double, unit: String, timestamp: Date) {
        self.id = id
        self.dataType = dataType
        self.timestamp = timestamp
        self.metricType = metricType
        self.value = value
        self.unit = unit
        self.bpSession = nil
        self.fitnessSession = nil
        self.nutritionEntry = nil
    }
    
    // BP session constructor
    init(id: UUID, dataType: HealthDataType, bpSession: BPSession, timestamp: Date) {
        self.id = id
        self.dataType = dataType
        self.timestamp = timestamp
        self.metricType = nil
        self.value = nil
        self.unit = nil
        self.bpSession = bpSession
        self.fitnessSession = nil
        self.nutritionEntry = nil
    }
    
    // Fitness session constructor
    init(id: UUID, dataType: HealthDataType, fitnessSession: FitnessSession, timestamp: Date) {
        self.id = id
        self.dataType = dataType
        self.timestamp = timestamp
        self.metricType = nil
        self.value = nil
        self.unit = nil
        self.bpSession = nil
        self.fitnessSession = fitnessSession
        self.nutritionEntry = nil
    }
    
    // Nutrition entry constructor
    init(id: UUID, dataType: HealthDataType, nutritionEntry: NutritionEntry, timestamp: Date) {
        self.id = id
        self.dataType = dataType
        self.timestamp = timestamp
        self.metricType = nil
        self.value = nil
        self.unit = nil
        self.bpSession = nil
        self.fitnessSession = nil
        self.nutritionEntry = nutritionEntry
    }
}

// MARK: - Firestore Errors

enum FirestoreError: LocalizedError {
    case noUser
    case encodingError
    case decodingError(String)
    case networkError
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No authenticated user found"
        case .encodingError:
            return "Error encoding data"
        case .decodingError(let message):
            return "Error decoding data: \(message)"
        case .networkError:
            return "Network error occurred"
        case .timeout:
            return "Request timed out"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
