import SwiftUI

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var tempSettings: ReminderSettings
    
    init() {
        _tempSettings = State(initialValue: NotificationManager.shared.reminderSettings)
    }
    
    var body: some View {
        NavigationView {
            List {
                // Master Toggle
                Section {
                    Toggle("Enable Reminders", isOn: $tempSettings.isEnabled)
                        .onChange(of: tempSettings.isEnabled) { enabled in
                            if enabled {
                                notificationManager.requestNotificationPermission()
                            } else {
                                notificationManager.cancelAllReminders()
                            }
                        }
                } header: {
                    Text("General")
                } footer: {
                    Text("Get reminded to log your health and nutrition data throughout the day.")
                }
                
                if tempSettings.isEnabled {
                    // Nutrition Reminders
                    Section("Nutrition Reminders") {
                        ReminderRow(
                            type: .breakfast,
                            isEnabled: $tempSettings.breakfastEnabled,
                            time: $tempSettings.breakfastTime
                        )
                        
                        ReminderRow(
                            type: .lunch,
                            isEnabled: $tempSettings.lunchEnabled,
                            time: $tempSettings.lunchTime
                        )
                        
                        ReminderRow(
                            type: .dinner,
                            isEnabled: $tempSettings.dinnerEnabled,
                            time: $tempSettings.dinnerTime
                        )
                    }
                    
                    // Health Reminders
                    Section("Health Reminders") {
                        ReminderRow(
                            type: .bloodPressure,
                            isEnabled: $tempSettings.bloodPressureEnabled,
                            time: $tempSettings.bloodPressureTime
                        )
                        
                        ReminderRow(
                            type: .weight,
                            isEnabled: $tempSettings.weightEnabled,
                            time: $tempSettings.weightTime
                        )
                        
                        ReminderRow(
                            type: .water,
                            isEnabled: $tempSettings.waterEnabled,
                            time: $tempSettings.waterTime
                        )
                    }
                    
                    // Quick Actions
                    Section("Quick Actions") {
                        Button("Test All Reminders") {
                            testAllReminders()
                        }
                        
                        Button("Cancel All Reminders") {
                            notificationManager.cancelAllReminders()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Reminders")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            if notificationManager.authorizationStatus == .notDetermined {
                notificationManager.requestNotificationPermission()
            }
        }
    }
    
    private func saveSettings() {
        notificationManager.updateSettings(tempSettings)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func testAllReminders() {
        for type in ReminderType.allCases {
            notificationManager.scheduleQuickReminder(type: type, in: 5)
        }
    }
}

struct ReminderRow: View {
    let type: ReminderType
    @Binding var isEnabled: Bool
    @Binding var time: Date
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.title)
                        .font(.headline)
                    
                    Text(type.body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
            }
            
            if isEnabled {
                HStack {
                    Text("Time:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(width: 120)
                }
                .padding(.leading, 32)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NotificationSettingsView()
}
