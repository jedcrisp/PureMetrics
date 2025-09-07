import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @StateObject private var authService = AuthService()
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.9),
                    Color.orange.opacity(0.7),
                    Color.red.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Text("PureMetrics")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            
                            Text("Track your health journey")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Auth Form
                        VStack(spacing: 24) {
                            // Toggle Sign Up/Sign In
                            Picker("Auth Mode", selection: $isSignUp) {
                                Text("Sign In").tag(false)
                                Text("Sign Up").tag(true)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .padding(.horizontal, 20)
                            .onChange(of: isSignUp) { newValue in
                                print("Picker changed to: \(newValue ? "Sign Up" : "Sign In")")
                            }
                            
                            // Form Fields
                            VStack(spacing: 16) {
                                // Display Name (Sign Up only)
                                if isSignUp {
                                    CustomTextField(
                                        text: $displayName,
                                        placeholder: "Display Name",
                                        icon: "person.fill"
                                    )
                                }
                                
                                // Email
                                CustomTextField(
                                    text: $email,
                                    placeholder: "Email",
                                    icon: "envelope.fill",
                                    keyboardType: .emailAddress
                                )
                                
                                // Password
                                CustomTextField(
                                    text: $password,
                                    placeholder: "Password",
                                    icon: "lock.fill",
                                    isSecure: true
                                )
                                
                                // Confirm Password (Sign Up only)
                                if isSignUp {
                                    CustomTextField(
                                        text: $confirmPassword,
                                        placeholder: "Confirm Password",
                                        icon: "lock.fill",
                                        isSecure: true
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Auth Button
                            Button(action: handleAuth) {
                                HStack {
                                    if authService.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    
                                    Text(isSignUp ? "Sign Up" : "Sign In")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                                .foregroundColor(.orange)
                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                            }
                            .disabled(authService.isLoading || !isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            .padding(.horizontal, 20)
                            
                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("OR")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal, 12)
                                
                                Rectangle()
                                    .fill(Color.white.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 20)
                            
                            // Google Sign In Button
                            Button(action: handleGoogleSignIn) {
                                HStack(spacing: 16) {
                                    // Google Logo
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 24, height: 24)
                                        
                                        Text("G")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.red)
                                    }
                                    
                                    Text("Continue with Google")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                )
                            }
                            .disabled(authService.isLoading)
                            .opacity(authService.isLoading ? 0.6 : 1.0)
                            .padding(.horizontal, 20)
                            
                            // Forgot Password (Sign In only)
                            if !isSignUp {
                                Button(action: handleForgotPassword) {
                                    Text("Forgot Password?")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                        .underline()
                                }
                            }
                        }
                        .padding(.vertical, 32)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white.opacity(0.1))
                                .backdrop(radius: 10)
                        )
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .alert("Authentication", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onChange(of: authService.errorMessage) { errorMessage in
                if let error = errorMessage {
                    alertMessage = error
                    showingAlert = true
                }
            }
        }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        if isSignUp {
            return !email.isEmpty && 
                   !password.isEmpty && 
                   !displayName.isEmpty && 
                   password == confirmPassword &&
                   password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
    
    // MARK: - Actions
    
    private func handleAuth() {
        print("Auth button tapped - isSignUp: \(isSignUp)")
        if isSignUp {
            handleSignUp()
        } else {
            handleSignIn()
        }
    }
    
    private func handleSignUp() {
        authService.signUp(email: email, password: password) { result in
            switch result {
            case .success(let user):
                // Update display name
                authService.updateProfile(displayName: displayName, photoURL: nil) { _ in
                    // Profile update is optional, don't show error if it fails
                }
                print("Sign up successful: \(user.uid)")
            case .failure(let error):
                print("Sign up failed: \(error.localizedDescription)")
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    private func handleSignIn() {
        authService.signIn(email: email, password: password) { result in
            switch result {
            case .success(let user):
                print("Sign in successful: \(user.uid)")
            case .failure(let error):
                print("Sign in failed: \(error.localizedDescription)")
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    private func handleGoogleSignIn() {
        print("Google Sign-In button tapped")
        authService.signInWithGoogle { result in
            switch result {
            case .success(let user):
                print("Google Sign-In successful: \(user.uid)")
            case .failure(let error):
                print("Google Sign-In failed: \(error.localizedDescription)")
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    private func handleForgotPassword() {
        guard !email.isEmpty else {
            alertMessage = "Please enter your email address first"
            showingAlert = true
            return
        }
        
        authService.resetPassword(email: email) { result in
            switch result {
            case .success:
                alertMessage = "Password reset email sent to \(email)"
                showingAlert = true
            case .failure(let error):
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
}

// MARK: - Custom Text Field

struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.2))
        )
    }
}

// MARK: - Backdrop Modifier

struct BackdropModifier: ViewModifier {
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.white.opacity(0.1))
                    .blur(radius: 10)
            )
    }
}

extension View {
    func backdrop(radius: CGFloat = 10) -> some View {
        self.modifier(BackdropModifier(radius: radius))
    }
}

#Preview {
    AuthView()
}
