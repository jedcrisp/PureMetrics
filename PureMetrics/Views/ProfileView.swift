import SwiftUI

struct ProfileView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var userName = ""
    @State private var age = ""
    @State private var showingEditProfile = false
    @State private var showingDeleteAllConfirmation = false
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile Header
                    profileHeaderSection
                    
                    // Statistics Overview
                    statisticsSection
                    
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
                StatCard(
                    icon: "heart.text.square",
                    title: "Total Sessions",
                    value: "\(dataManager.sessions.count)",
                    color: .blue
                )
                
                StatCard(
                    icon: "waveform.path.ecg",
                    title: "Total Readings",
                    value: "\(totalReadings)",
                    color: .green
                )
                
                StatCard(
                    icon: "arrow.up",
                    title: "Avg Systolic",
                    value: overallAverageSystolic,
                    color: .red
                )
                
                StatCard(
                    icon: "arrow.down",
                    title: "Avg Diastolic",
                    value: overallAverageDiastolic,
                    color: .orange
                )
            }
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
                    ForEach(Array(dataManager.sessions.prefix(5))) { session in
                        RecentSessionRow(session: session)
                    }
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
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

// MARK: - Preview

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView(dataManager: BPDataManager())
    }
}
