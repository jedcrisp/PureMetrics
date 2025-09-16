import SwiftUI

struct ProfileView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var userName = ""
    @State private var age = ""
    @State private var showingEditProfile = false
    @State private var showingDeleteAllConfirmation = false
    @State private var showingLogoutConfirmation = false
    @State private var showingNotificationSettings = false
    @State private var showingBMRProfile = false
    @State private var showingBMRGoals = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Statistics Overview
                    statisticsSection
                    
                    // HealthKit Integration
                    healthKitSection
                    
                    // BMR Calculator Section
                    bmrSection
                    
                    // Settings Section
                    settingsSection
                    
                    // Recent Activity
                    recentActivitySection
                    
                    // Delete All Data Section
                    deleteAllDataSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditProfile = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(userName: $userName, age: $age)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView()
        }
        .sheet(isPresented: $showingBMRProfile) {
            BMRProfileInputView(bmrManager: dataManager.bmrManager)
        }
        .sheet(isPresented: $showingBMRGoals) {
            BMRGoalsView(dataManager: dataManager)
        }
        .alert(isPresented: $showingDeleteAllConfirmation) {
            Alert(
                title: Text("Delete All Data"),
                message: Text("Are you sure you want to delete all your blood pressure data? This action cannot be undone and will remove all sessions and readings."),
                primaryButton: .destructive(Text("Delete All")) {
                    dataManager.deleteAllSessions()
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
        .alert(isPresented: $showingLogoutConfirmation) {
            Alert(
                title: Text("Sign Out"),
                message: Text("Are you sure you want to sign out? You will need to sign in again to access your data."),
                primaryButton: .destructive(Text("Sign Out")) {
                    dataManager.signOut()
                },
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
        .onAppear {
            loadUserData()
        }
    }
    
    // MARK: - Profile Header Section
    
    private var profileHeaderSection: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Text(userName.isEmpty ? "U" : String(userName.prefix(1)).uppercased())
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
            
            VStack(spacing: 4) {
                Text(userName.isEmpty ? "User" : userName)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if !age.isEmpty {
                    Text("Age: \(age)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.1))
        )
    }
    
    // MARK: - Statistics Section
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ProfileStatCard(
                    icon: "heart.text.square",
                    title: "Total Sessions",
                    value: "\(dataManager.sessions.count)",
                    color: .blue
                )
                
                ProfileStatCard(
                    icon: "waveform.path.ecg",
                    title: "Total Readings",
                    value: "\(totalReadings)",
                    color: .green
                )
                
                ProfileStatCard(
                    icon: "arrow.up",
                    title: "Avg Systolic",
                    value: overallAverageSystolic,
                    color: .red
                )
                
                ProfileStatCard(
                    icon: "arrow.down",
                    title: "Avg Diastolic",
                    value: overallAverageDiastolic,
                    color: .orange
                )
            }
        }
    }
    
    
    // MARK: - HealthKit Section
    
    private var healthKitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apple Health Integration")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: dataManager.healthKitManager.isHealthKitEnabled ? "heart.fill" : "heart.slash")
                        .foregroundColor(dataManager.healthKitManager.isHealthKitEnabled ? .red : .gray)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Health Data Sync")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(healthKitStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if !dataManager.healthKitManager.isHealthKitEnabled {
                        Button("Enable") {
                            dataManager.healthKitManager.isHealthKitEnabled = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    } else if !dataManager.healthKitManager.isAuthorized {
                        Button("Grant Access") {
                            dataManager.healthKitManager.requestAuthorization()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            #if targetEnvironment(simulator)
                            Button("Add Sample Data") {
                                dataManager.healthKitManager.forceAddSampleData()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .foregroundColor(.orange)
                            #endif
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                
                if dataManager.healthKitManager.isHealthKitEnabled && dataManager.healthKitManager.isAuthorized {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Synced Data Types:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            HealthKitDataTypeView(icon: "scalemass", title: "Weight", isEnabled: true)
                            HealthKitDataTypeView(icon: "figure.walk", title: "Steps", isEnabled: true)
                            HealthKitDataTypeView(icon: "flame", title: "Active Energy", isEnabled: true)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.05))
                    )
                }
            }
        }
    }
    
    // MARK: - BMR Section
    
    private var bmrSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BMR Calculator")
                .font(.headline)
                .padding(.horizontal)
            
            if dataManager.bmrManager.profile.isValid {
                BMRProfileCard(
                    profile: dataManager.bmrManager.profile,
                    recommendations: dataManager.getBMRRecommendations(),
                    onEdit: {
                        showingBMRProfile = true
                    },
                    onSetGoals: {
                        showingBMRGoals = true
                    }
                )
                
                // Weight Sync Toggle
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Auto-Sync Weight")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Automatically update BMR when weight changes in Apple Health")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: $dataManager.bmrManager.isWeightSyncingEnabled)
                            .onChange(of: dataManager.bmrManager.isWeightSyncingEnabled) { _ in
                                dataManager.bmrManager.toggleWeightSyncing()
                            }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    if dataManager.bmrManager.isWeightSyncingEnabled {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            
                            Text("Weight syncing is active. Your BMR will update automatically when your weight changes in Apple Health.")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.horizontal)
            } else {
                BMRSetupCard {
                    showingBMRProfile = true
                }
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Notification Reminders
                Button(action: {
                    showingNotificationSettings = true
                }) {
                    HStack {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Reminders")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Set up daily reminders for health and nutrition tracking")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Daily Snapshot PDF
                Button(action: {
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Snapshot")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Text("Generate a printable PDF of today's health data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var healthKitStatusText: String {
        if !dataManager.healthKitManager.isHealthKitEnabled {
            return "Enable to sync with Apple Health"
        } else if !dataManager.healthKitManager.isAuthorized {
            return "Grant permissions to access health data"
        } else {
            return "Connected and syncing data"
        }
    }
    
    // MARK: - Recent Activity Section
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            if dataManager.sessions.isEmpty {
                Text("No sessions recorded yet")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(sortedSessions.prefix(5))) { session in
                        RecentSessionRow(session: session)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var sortedSessions: [BPSession] {
        dataManager.sessions.sorted { $0.startTime > $1.startTime }
    }
    
    private var totalReadings: Int {
        dataManager.sessions.reduce(0) { $0 + $1.readings.count }
    }
    
    private var overallAverageSystolic: String {
        guard !dataManager.sessions.isEmpty else { return "--" }
        let allReadings = dataManager.sessions.flatMap { $0.readings }
        guard !allReadings.isEmpty else { return "--" }
        let average = Double(allReadings.map { $0.systolic }.reduce(0, +)) / Double(allReadings.count)
        return String(format: "%.0f", average)
    }
    
    private var overallAverageDiastolic: String {
        guard !dataManager.sessions.isEmpty else { return "--" }
        let allReadings = dataManager.sessions.flatMap { $0.readings }
        guard !allReadings.isEmpty else { return "--" }
        let average = Double(allReadings.map { $0.diastolic }.reduce(0, +)) / Double(allReadings.count)
        return String(format: "%.0f", average)
    }
    
    // MARK: - Helper Functions
    
    private func loadUserData() {
        userName = UserDefaults.standard.string(forKey: "userName") ?? ""
        age = UserDefaults.standard.string(forKey: "userAge") ?? ""
    }
    
    
    // MARK: - Delete All Data Section
    
    private var deleteAllDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Data Management")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                
                // Logout Button
                Button(action: { showingLogoutConfirmation = true }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.blue)
                        Text("Sign Out")
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Delete All Data Button
                Button(action: { showingDeleteAllConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(.red)
                        Text("Delete All Data")
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("Sign out to switch accounts or delete all data to permanently remove your blood pressure sessions and readings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
    }
}


// MARK: - Recent Session Row Component

struct RecentSessionRow: View {
    let session: BPSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startTime, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(session.startTime, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(session.displayString)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Text("\(session.readings.count) reading\(session.readings.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// MARK: - Edit Profile View

struct EditProfileView: View {
    @Binding var userName: String
    @Binding var age: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Personal Information") {
                    TextField("Name", text: $userName)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveUserData()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveUserData() {
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(age, forKey: "userAge")
    }
}

// MARK: - Stat Card Component

struct ProfileStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - HealthKit Data Type View

struct HealthKitDataTypeView: View {
    let icon: String
    let title: String
    let isEnabled: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(isEnabled ? .green : .gray)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

// MARK: - BMR Setup Card

struct BMRSetupCard: View {
    let onSetup: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Up BMR Profile")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("Calculate your personalized nutrition goals")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: onSetup) {
                Text("Get Started")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - BMR Profile Card

struct BMRProfileCard: View {
    let profile: BMRProfile
    let recommendations: BMRRecommendations
    let onEdit: () -> Void
    let onSetGoals: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your BMR Profile")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("\(profile.age) years • \(profile.gender.displayName) • \(BMRProfileCard.formatWeight(profile))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Edit") {
                    onEdit()
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            // BMR Values
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BMR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recommendations.bmrString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("TDEE")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recommendations.tdeeString)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            
            // Macro Recommendations
            VStack(alignment: .leading, spacing: 8) {
                Text("Daily Recommendations")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Protein")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(recommendations.proteinString)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(recommendations.fatString)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.brown)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Carbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(recommendations.carbString)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.yellow)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Water")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(recommendations.waterString)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.05))
            )
            
            // Goal Setting Button
            Button(action: onSetGoals) {
                HStack {
                    Image(systemName: "target")
                        .font(.subheadline)
                    Text("Set Nutrition Goals")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    static func formatWeight(_ profile: BMRProfile) -> String {
        // Check if user prefers imperial units
        let prefersImperial = UserDefaults.standard.bool(forKey: "prefersImperialUnits")
        
        if prefersImperial {
            return "\(Int(profile.weightInPounds)) lbs"
        } else {
            return "\(Int(profile.weight)) kg"
        }
    }
}

// MARK: - BMR Goals View

struct BMRGoalsView: View {
    @ObservedObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedGoalType: BMRGoalType = .maintenance
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Goal Type Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Your Goal")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Picker("Goal Type", selection: $selectedGoalType) {
                        ForEach(BMRGoalType.allCases, id: \.self) { goalType in
                            VStack(alignment: .leading) {
                                Text(goalType.displayName)
                                    .font(.headline)
                                Text(goalType.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(goalType)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                // BMR Recommendations
                if dataManager.bmrManager.profile.isValid {
                    let recommendations = dataManager.getBMRRecommendations()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recommended Goals")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Daily Calories:")
                                Spacer()
                                Text(getCalorieGoal(for: selectedGoalType, recommendations: recommendations))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("Protein:")
                                Spacer()
                                Text(recommendations.proteinString)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                            }
                            
                            HStack {
                                Text("Fat:")
                                Spacer()
                                Text(recommendations.fatString)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.brown)
                            }
                            
                            HStack {
                                Text("Carbs:")
                                Spacer()
                                Text(recommendations.carbString)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.yellow)
                            }
                            
                            HStack {
                                Text("Water:")
                                Spacer()
                                Text(recommendations.waterString)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("BMR Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        dataManager.updateNutritionGoalsFromBMR(for: selectedGoalType)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func getCalorieGoal(for goalType: BMRGoalType, recommendations: BMRRecommendations) -> String {
        switch goalType {
        case .weightLoss:
            return recommendations.weightLossString
        case .weightGain:
            return recommendations.weightGainString
        case .maintenance:
            return recommendations.maintenanceString
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(dataManager: BPDataManager())
    }
}
