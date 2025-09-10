import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    private let authService = AuthService()
    private let encryptionService = EncryptionService.shared
    
    // MARK: - Collection References
    
    private var userID: String? {
        return authService.currentUser?.uid
    }
    
    private func userCollection() -> CollectionReference? {
        guard let userID = userID else { return nil }
        return db.collection("users").document(userID).collection("health_data")
    }
    
    private func dataTypeCollection(_ dataType: HealthDataType) -> CollectionReference? {
        guard let userID = userID else { return nil }
        return db.collection("users").document(userID).collection("health_data").document(dataType.rawValue).collection("data")
    }
    
    // MARK: - Unified Health Data Management
    
    func saveHealthData(_ data: [UnifiedHealthData], completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
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
        guard let collection = dataTypeCollection(dataType) else {
            print("Error: No authenticated user for loading \(dataType.rawValue) data")
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        var isCompleted = false
        
        // Add timeout for individual requests
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            guard !isCompleted else { return }
            isCompleted = true
            print("Timeout loading \(dataType.rawValue) data")
            completion(.failure(FirestoreError.timeout))
        }
        
        collection.order(by: "createdAt", descending: true).getDocuments { snapshot, error in
            guard !isCompleted else { return }
            isCompleted = true
            
            if let error = error {
                print("Error loading \(dataType.rawValue) data: \(error)")
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No \(dataType.rawValue) data found")
                completion(.success([]))
                return
            }
            
            var healthData: [UnifiedHealthData] = []
            
            for document in documents {
                do {
                    let documentData = document.data()
                    
                    // Check if data is encrypted
                    if let isEncrypted = documentData["isEncrypted"] as? Bool, isEncrypted,
                       let encryptedString = documentData["encryptedData"] as? String {
                        // Decrypt the data
                        let decryptedData = try self.encryptionService.decryptHealthData(encryptedString, as: UnifiedHealthData.self)
                        healthData.append(decryptedData)
                    } else {
                        // Fallback to regular decoding
                        let data = try Firestore.Decoder().decode(UnifiedHealthData.self, from: documentData)
                        healthData.append(data)
                    }
                } catch {
                    print("Error decoding \(dataType.rawValue) data: \(error)")
                }
            }
            
            print("Successfully loaded \(healthData.count) \(dataType.rawValue) entries")
            completion(.success(healthData))
        }
    }
    
    private func loadAllDataTypes(completion: @escaping (Result<[UnifiedHealthData], Error>) -> Void) {
        let dispatchGroup = DispatchGroup()
        var allHealthData: [UnifiedHealthData] = []
        var hasError = false
        var lastError: Error?
        var isCompleted = false
        
        for dataType in HealthDataType.allCases {
            dispatchGroup.enter()
            
            loadSpecificDataType(dataType) { result in
                guard !isCompleted else { return }
                
                switch result {
                case .success(let data):
                    allHealthData.append(contentsOf: data)
                case .failure(let error):
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
            
            if hasError, let error = lastError {
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
            
            collection.order(by: "createdAt", descending: true).getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading \(dataType.rawValue) metrics: \(error)")
                    hasError = true
                    lastError = error
                } else if let documents = snapshot?.documents {
                    for document in documents {
                        do {
                            let metric = try Firestore.Decoder().decode(HealthMetric.self, from: document.data())
                            allMetrics.append(metric)
                        } catch {
                            print("Error decoding \(dataType.rawValue) metric: \(error)")
                        }
                    }
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
        
        collection.order(by: "createdAt", descending: true).getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let sessions = documents.compactMap { document in
                do {
                    var data = document.data()
                    // Remove the extra fields we added for Firestore
                    data.removeValue(forKey: "dataType")
                    data.removeValue(forKey: "createdAt")
                    data.removeValue(forKey: "updatedAt")
                    return try Firestore.Decoder().decode(BPSession.self, from: data)
                } catch {
                    print("Error decoding BP session: \(error)")
                    return nil
                }
            }
            
            print("Successfully loaded \(sessions.count) BP sessions from organized structure")
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
        sessionsCollection.whereField("type", isEqualTo: "fitness_session").getDocuments { snapshot, error in
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
    }
}

// MARK: - Firestore Errors

enum FirestoreError: LocalizedError {
    case noUser
    case encodingError
    case decodingError
    case networkError
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noUser:
            return "No authenticated user found"
        case .encodingError:
            return "Error encoding data"
        case .decodingError:
            return "Error decoding data"
        case .networkError:
            return "Network error occurred"
        case .timeout:
            return "Request timed out"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
