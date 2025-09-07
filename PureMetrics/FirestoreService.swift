import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    private let authService = AuthService()
    
    // MARK: - Collection References
    
    private var userID: String? {
        return authService.currentUser?.uid
    }
    
    private func userCollection() -> CollectionReference? {
        guard let userID = userID else { return nil }
        return db.collection("users").document(userID).collection("data")
    }
    
    // MARK: - Blood Pressure Sessions
    
    func saveBPSessions(_ sessions: [BPSession], completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let collection = userCollection() else { 
            print("Error: No authenticated user for saving BP sessions")
            completion(.failure(FirestoreError.noUser))
            return 
        }
        
        let batch = db.batch()
        
        for (index, session) in sessions.enumerated() {
            do {
                var sessionData = try Firestore.Encoder().encode(session)
                sessionData["type"] = "bp_session"
                sessionData["id"] = session.id.uuidString
                sessionData["createdAt"] = Timestamp(date: session.startTime)
                sessionData["updatedAt"] = Timestamp(date: Date())
                
                let docRef = collection.document("bp_session_\(session.id.uuidString)")
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
                print("Successfully saved \(sessions.count) BP sessions to Firestore")
                completion(.success(()))
            }
        }
    }
    
    func loadBPSessions(completion: @escaping (Result<[BPSession], Error>) -> Void) {
        guard let collection = userCollection() else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        collection.whereField("type", isEqualTo: "bp_session").getDocuments { snapshot, error in
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
                    data.removeValue(forKey: "type")
                    data.removeValue(forKey: "createdAt")
                    data.removeValue(forKey: "updatedAt")
                    return try Firestore.Decoder().decode(BPSession.self, from: data)
                } catch {
                    print("Error decoding BP session: \(error)")
                    return nil
                }
            }
            
            completion(.success(sessions))
        }
    }
    
    // MARK: - Fitness Sessions
    
    func saveFitnessSessions(_ sessions: [FitnessSession], completion: @escaping (Result<Void, Error>) -> Void = { _ in }) {
        guard let collection = userCollection() else { 
            print("Error: No authenticated user for saving fitness sessions")
            completion(.failure(FirestoreError.noUser))
            return 
        }
        
        let batch = db.batch()
        
        for (index, session) in sessions.enumerated() {
            // Save the main fitness session document
            let sessionDocRef = collection.document("fitness_sessions").collection("sessions").document(session.id.uuidString)
            
            var sessionData: [String: Any] = [:]
            sessionData["type"] = "fitness_session"
            sessionData["id"] = session.id.uuidString
            sessionData["startTime"] = Timestamp(date: session.startTime)
            sessionData["endTime"] = session.endTime != nil ? Timestamp(date: session.endTime!) : nil
            sessionData["isActive"] = session.isActive
            sessionData["isPaused"] = session.isPaused
            sessionData["isCompleted"] = session.isCompleted
            sessionData["createdAt"] = Timestamp(date: session.startTime)
            sessionData["updatedAt"] = Timestamp(date: Date())
            
            batch.setData(sessionData, forDocument: sessionDocRef)
            
            // Debug: Print session data to see what's being saved
            print("Saving fitness session \(index):")
            print("- Session ID: \(session.id)")
            print("- Exercise Sessions: \(session.exerciseSessions.count)")
            
            // Save each exercise as a subcollection under the fitness session
            for exerciseSession in session.exerciseSessions {
                let exerciseDocRef = sessionDocRef.collection("exercises").document(exerciseSession.id.uuidString)
                
                var exerciseData: [String: Any] = [:]
                exerciseData["id"] = exerciseSession.id.uuidString
                exerciseData["exerciseType"] = exerciseSession.exerciseType.rawValue
                exerciseData["startTime"] = Timestamp(date: exerciseSession.startTime)
                exerciseData["endTime"] = exerciseSession.endTime != nil ? Timestamp(date: exerciseSession.endTime!) : nil
                exerciseData["isCompleted"] = exerciseSession.isCompleted
                exerciseData["createdAt"] = Timestamp(date: exerciseSession.startTime)
                exerciseData["updatedAt"] = Timestamp(date: Date())
                
                // Include sets data in the exercise document for easier querying
                var setsData: [[String: Any]] = []
                for set in exerciseSession.sets {
                    var setData: [String: Any] = [:]
                    setData["id"] = set.id.uuidString
                    setData["reps"] = set.reps
                    setData["weight"] = set.weight
                    setData["time"] = set.time
                    setData["timestamp"] = Timestamp(date: set.timestamp)
                    setsData.append(setData)
                }
                exerciseData["sets"] = setsData
                
                batch.setData(exerciseData, forDocument: exerciseDocRef)
                
                print("  - Exercise: \(exerciseSession.exerciseType.rawValue)")
                print("  - Sets: \(exerciseSession.sets.count)")
                
                // Save each set as a subcollection under the exercise
                for (setIndex, set) in exerciseSession.sets.enumerated() {
                    let setDocRef = exerciseDocRef.collection("sets").document(set.id.uuidString)
                    
                    var setData: [String: Any] = [:]
                    setData["id"] = set.id.uuidString
                    setData["reps"] = set.reps
                    setData["weight"] = set.weight
                    setData["time"] = set.time
                    setData["timestamp"] = Timestamp(date: set.timestamp)
                    setData["createdAt"] = Timestamp(date: set.timestamp)
                    setData["updatedAt"] = Timestamp(date: Date())
                    
                    batch.setData(setData, forDocument: setDocRef)
                    
                    print("    - Set \(setIndex): ID=\(set.id.uuidString), reps=\(set.reps ?? 0), weight=\(set.weight ?? 0), time=\(set.time ?? 0)")
                    print("    - Set data being saved: \(setData)")
                }
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("Error saving fitness sessions: \(error)")
                completion(.failure(error))
            } else {
                print("Successfully saved \(sessions.count) fitness sessions to Firestore with hierarchical structure")
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

// MARK: - Firestore Errors

enum FirestoreError: LocalizedError {
    case noUser
    case encodingError
    case decodingError
    case networkError
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
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
