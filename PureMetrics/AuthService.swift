import Foundation
import FirebaseAuth
import GoogleSignIn
import Combine

class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupAuthStateListener()
        configureGoogleSignIn()
    }
    
    private func configureGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("GoogleService-Info.plist not found or CLIENT_ID missing")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                let wasAuthenticated = self?.isAuthenticated ?? false
                self?.currentUser = user
                self?.isAuthenticated = user != nil
                
                // Post notification when user signs in
                if !wasAuthenticated && user != nil {
                    NotificationCenter.default.post(name: .userDidSignIn, object: nil)
                }
                
                // Post notification when user signs out
                if wasAuthenticated && user == nil {
                    NotificationCenter.default.post(name: .userDidSignOut, object: nil)
                }
            }
        }
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else if let user = result?.user {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    completion(.success(user))
                }
            }
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else if let user = result?.user {
                    self?.currentUser = user
                    self?.isAuthenticated = true
                    completion(.success(user))
                }
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Password Reset
    
    func resetPassword(email: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Update Profile
    
    func updateProfile(displayName: String?, photoURL: URL?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(AuthError.noCurrentUser))
            return
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        changeRequest.photoURL = photoURL
        
        changeRequest.commitChanges { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle(completion: @escaping (Result<User, Error>) -> Void) {
        print("Starting Google Sign-In process...")
        
        // Check if GoogleSignIn is available
        guard NSClassFromString("GIDSignIn") != nil else {
            print("GoogleSignIn module not available")
            completion(.failure(AuthError.googleSignInFailed))
            return
        }
        
        guard let presentingViewController = UIApplication.shared.windows.first?.rootViewController else {
            print("No presenting view controller found")
            completion(.failure(AuthError.noPresentingViewController))
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        print("Calling GIDSignIn.sharedInstance.signIn...")
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Google Sign-In error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    print("Failed to get Google ID token")
                    self?.errorMessage = "Failed to get Google ID token"
                    completion(.failure(AuthError.googleSignInFailed))
                    return
                }
                
                print("Got Google ID token, creating Firebase credential...")
                let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("Firebase auth error: \(error.localizedDescription)")
                        self?.errorMessage = error.localizedDescription
                        completion(.failure(error))
                    } else if let authUser = authResult?.user {
                        print("Firebase auth successful: \(authUser.uid)")
                        self?.currentUser = authUser
                        self?.isAuthenticated = true
                        completion(.success(authUser))
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Account
    
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = currentUser else {
            completion(.failure(AuthError.noCurrentUser))
            return
        }
        
        user.delete { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(.failure(error))
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                    completion(.success(()))
                }
            }
        }
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case noCurrentUser
    case invalidEmail
    case weakPassword
    case userNotFound
    case wrongPassword
    case emailAlreadyInUse
    case networkError
    case noPresentingViewController
    case googleSignInFailed
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "No current user found"
        case .invalidEmail:
            return "Invalid email address"
        case .weakPassword:
            return "Password is too weak"
        case .userNotFound:
            return "User not found"
        case .wrongPassword:
            return "Wrong password"
        case .emailAlreadyInUse:
            return "Email already in use"
        case .networkError:
            return "Network error occurred"
        case .noPresentingViewController:
            return "No presenting view controller found"
        case .googleSignInFailed:
            return "Google Sign-In failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
