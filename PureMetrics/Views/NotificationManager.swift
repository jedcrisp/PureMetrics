import Foundation
import UserNotifications
import SwiftUI

// MARK: - Notification Types

enum ReminderType: String, CaseIterable, Codable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case bloodPressure = "blood_pressure"
    case weight = "weight"
    case water = "water"
    
    var title: String {
        switch self {
        case .breakfast: return "Breakfast Time! 🍳"
        case .lunch: return "Lunch Time! 🥗"
        case .dinner: return "Dinner Time! 🍽️"
        case .bloodPressure: return "Blood Pressure Check! ❤️"
        case .weight: return "Weight Check! ⚖️"
        case .water: return "Stay Hydrated! 💧"
        }
    }
    
    var body: String {
        switch self {
        case .breakfast: return "Don't forget to log your breakfast nutrition facts!"
        case .lunch: return "Time to track your lunch nutrition!"
        case .dinner: return "Log your dinner nutrition to stay on track!"
        case .bloodPressure: return "Time for your daily blood pressure reading!"
        case .weight: return "Log your weight to track your progress!"
        case .water: return "Remember to log your water intake!"
        }
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .bloodPressure: return "heart.fill"
        case .weight: return "scalemass.fill"
        case .water: return "drop.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .blue
        case .dinner: return .purple
        case .bloodPressure: return .red
        case .weight: return .green
        case .water: return .cyan
        }
    }
}

// MARK: - Reminder Settings

struct ReminderSettings: Codable {
    var isEnabled: Bool = true
    var breakfastTime: Date = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    var lunchTime: Date = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    var dinnerTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    var bloodPressureTime: Date = Calendar.current.date(bySettingHour: 19, minute: 0, second: 0, of: Date()) ?? Date()
    var weightTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    var waterTime: Date = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
    
    // Individual reminder toggles
    var breakfastEnabled: Bool = true
    var lunchEnabled: Bool = true
    var dinnerEnabled: Bool = true
    var bloodPressureEnabled: Bool = true
    var weightEnabled: Bool = true
    var waterEnabled: Bool = true
}

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var reminderSettings = ReminderSettings()
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    private let userDefaults = UserDefaults.standard
    private let settingsKey = "ReminderSettings"
    
    private init() {
        loadSettings()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("Notification permission granted")
                    self.scheduleAllReminders()
                } else {
                    print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
                }
                self.checkAuthorizationStatus()
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Settings Management
    
    func updateSettings(_ newSettings: ReminderSettings) {
        reminderSettings = newSettings
        saveSettings()
        scheduleAllReminders()
    }
    
    private func saveSettings() {
        do {
            let data = try JSONEncoder().encode(reminderSettings)
            userDefaults.set(data, forKey: settingsKey)
        } catch {
            print("Error saving reminder settings: \(error)")
        }
    }
    
    private func loadSettings() {
        guard let data = userDefaults.data(forKey: settingsKey) else { return }
        
        do {
            reminderSettings = try JSONDecoder().decode(ReminderSettings.self, from: data)
        } catch {
            print("Error loading reminder settings: \(error)")
        }
    }
    
    // MARK: - Reminder Scheduling
    
    func scheduleAllReminders() {
        guard reminderSettings.isEnabled else {
            cancelAllReminders()
            return
        }
        
        if reminderSettings.breakfastEnabled {
            scheduleReminder(type: .breakfast, time: reminderSettings.breakfastTime)
        }
        
        if reminderSettings.lunchEnabled {
            scheduleReminder(type: .lunch, time: reminderSettings.lunchTime)
        }
        
        if reminderSettings.dinnerEnabled {
            scheduleReminder(type: .dinner, time: reminderSettings.dinnerTime)
        }
        
        if reminderSettings.bloodPressureEnabled {
            scheduleReminder(type: .bloodPressure, time: reminderSettings.bloodPressureTime)
        }
        
        if reminderSettings.weightEnabled {
            scheduleReminder(type: .weight, time: reminderSettings.weightTime)
        }
        
        if reminderSettings.waterEnabled {
            scheduleReminder(type: .water, time: reminderSettings.waterTime)
        }
    }
    
    private func scheduleReminder(type: ReminderType, time: Date) {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = type.body
        content.sound = .default
        content.badge = 1
        
        // Add custom data
        content.userInfo = [
            "reminderType": type.rawValue,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Create date components for the reminder time
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        // Create trigger for daily repetition
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "\(type.rawValue)_reminder",
            content: content,
            trigger: trigger
        )
        
        // Add notification request
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling \(type.rawValue) reminder: \(error)")
            } else {
                print("Successfully scheduled \(type.rawValue) reminder for \(time)")
            }
        }
    }
    
    func cancelAllReminders() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        print("Cancelled all reminders")
    }
    
    func cancelReminder(type: ReminderType) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(type.rawValue)_reminder"])
        print("Cancelled \(type.rawValue) reminder")
    }
    
    // MARK: - Quick Actions
    
    func scheduleQuickReminder(type: ReminderType, in minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = type.body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
        let request = UNNotificationRequest(
            identifier: "quick_\(type.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling quick reminder: \(error)")
            } else {
                print("Quick reminder scheduled for \(minutes) minutes")
            }
        }
    }
    
    // MARK: - Debug
    
    func listScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("Scheduled notifications: \(requests.count)")
            for request in requests {
                print("- \(request.identifier): \(request.content.title)")
            }
        }
    }
}

