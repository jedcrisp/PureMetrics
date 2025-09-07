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
    
    func saveBPSessions(_ sessions: [BPSession]) {
        guard let collection = userCollection() else { return }
        
        let sessionsData = sessions.map { session in
            try? Firestore.Encoder().encode(session)
        }.compactMap { $0 }
        
        let batch = db.batch()
        
        for (index, sessionData) in sessionsData.enumerated() {
            let docRef = collection.document("bp_session_\(index)")
            batch.setData(sessionData, forDocument: docRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error saving BP sessions: \(error)")
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
                try? Firestore.Decoder().decode(BPSession.self, from: document.data())
            }
            
            completion(.success(sessions))
        }
    }
    
    // MARK: - Fitness Sessions
    
    func saveFitnessSessions(_ sessions: [FitnessSession]) {
        guard let collection = userCollection() else { return }
        
        let sessionsData = sessions.map { session in
            try? Firestore.Encoder().encode(session)
        }.compactMap { $0 }
        
        let batch = db.batch()
        
        for (index, sessionData) in sessionsData.enumerated() {
            let docRef = collection.document("fitness_session_\(index)")
            batch.setData(sessionData, forDocument: docRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error saving fitness sessions: \(error)")
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
                try? Firestore.Decoder().decode(FitnessSession.self, from: document.data())
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
    
    func syncAllData(bpSessions: [BPSession], fitnessSessions: [FitnessSession], userProfile: UserProfile?) {
        saveBPSessions(bpSessions)
        saveFitnessSessions(fitnessSessions)
        
        if let profile = userProfile {
            saveUserProfile(profile)
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
