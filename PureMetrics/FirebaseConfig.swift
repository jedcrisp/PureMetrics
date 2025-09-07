import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()
    
    @Published var isInitialized = false
    @Published var currentUser: User?
    
    private init() {
        configureFirebase()
    }
    
    private func configureFirebase() {
        // Check if Firebase is already configured
        guard FirebaseApp.app() == nil else {
            self.isInitialized = true
            setupAuthStateListener()
            return
        }
        
        // Configure Firebase
        FirebaseApp.configure()
        self.isInitialized = true
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.currentUser = user
            }
        }
    }
    
    var isSignedIn: Bool {
        return currentUser != nil
    }
    
    var userID: String? {
        return currentUser?.uid
    }
    
    var userEmail: String? {
        return currentUser?.email
    }
}
