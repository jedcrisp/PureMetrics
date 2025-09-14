import SwiftUI
import FirebaseCore
import GoogleSignIn
import UserNotifications
import UIKit

@main
struct PureMetricsApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("GoogleService-Info.plist not found or CLIENT_ID missing")
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isAuthenticated {
                    ContentView()
                        .environmentObject(authService)
                        .environmentObject(firebaseManager)
                } else {
                    AuthView()
                        .environmentObject(authService)
                        .environmentObject(firebaseManager)
                }
            }
            .onAppear {
                // Initialize Firebase if not already done
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }
                
                // Clear notification badge when app becomes active
                clearNotificationBadge()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Clear notification badge when app becomes active
                clearNotificationBadge()
            }
            .onOpenURL { url in
                // Handle Google Sign-In URL
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
    
    // MARK: - Notification Badge Management
    
    private func clearNotificationBadge() {
        // Clear the app icon badge
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        // Also clear any delivered notifications
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        print("Cleared notification badge and delivered notifications")
    }
}
