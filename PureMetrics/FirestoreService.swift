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
            do {
                var sessionData = try Firestore.Encoder().encode(session)
                sessionData["type"] = "fitness_session"
                sessionData["id"] = session.id.uuidString
                sessionData["createdAt"] = Timestamp(date: session.startTime)
                sessionData["updatedAt"] = Timestamp(date: Date())
                
                // Debug: Print session data to see what's being saved
                print("Saving fitness session \(index):")
                print("- ID: \(session.id)")
                print("- Exercise Sessions: \(session.exerciseSessions.count)")
                for (exerciseIndex, exerciseSession) in session.exerciseSessions.enumerated() {
                    print("  - Exercise \(exerciseIndex): \(exerciseSession.exerciseType.rawValue)")
                    print("  - Sets: \(exerciseSession.sets.count)")
                    for (setIndex, set) in exerciseSession.sets.enumerated() {
                        print("    - Set \(setIndex): reps=\(set.reps ?? 0), weight=\(set.weight ?? 0), time=\(set.time ?? 0)")
                    }
                }
                
                let docRef = collection.document("fitness_session_\(session.id.uuidString)")
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
                print("Successfully saved \(sessions.count) fitness sessions to Firestore")
                completion(.success(()))
            }
        }
    }
    
    func loadFitnessSessions(completion: @escaping (Result<[FitnessSession], Error>) -> Void) {
        guard let collection = userCollection() else {
            completion(.failure(FirestoreError.noUser))
            return
        }
        
        collection.whereField("type", isEqualTo: "fitness_session").getDocuments { snapshot, error in
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
                    return try Firestore.Decoder().decode(FitnessSession.self, from: data)
                } catch {
                    print("Error decoding fitness session: \(error)")
                    return nil
                }
            }
            
            completion(.success(sessions))
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
