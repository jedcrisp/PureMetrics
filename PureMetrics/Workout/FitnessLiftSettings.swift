import Foundation
import SwiftUI

// MARK: - Fitness Lift Settings Manager

class FitnessLiftSettings: ObservableObject {
    @Published var selectedPRLifts: Set<String> = []
    @Published var selectedRepMaxLifts: Set<String> = []
    
    private let prLiftsKey = "selectedPRLifts"
    private let repMaxLiftsKey = "selectedRepMaxLifts"
    
    init() {
        loadSettings()
    }
    
    // MARK: - Available Lifts
    
    var availableLifts: [String] {
        return [
            "Deadlift",
            "Back Squat", 
            "Bench Press",
            "Hex Bar Deadlift",
            "Overhead Press",
            "Front Squat",
            "Romanian Deadlift",
            "Incline Bench Press",
            "Sumo Deadlift",
            "Pause Squat"
        ]
    }
    
    // MARK: - Default Selections
    
    var defaultPRLifts: Set<String> {
        return Set([
            "Deadlift",
            "Back Squat",
            "Bench Press",
            "Hex Bar Deadlift",
            "Overhead Press",
            "Front Squat"
        ])
    }
    
    var defaultRepMaxLifts: Set<String> {
        return Set([
            "Deadlift",
            "Back Squat",
            "Bench Press",
            "Hex Bar Deadlift"
        ])
    }
    
    // MARK: - Settings Management
    
    func loadSettings() {
        // Load PR lifts
        if let data = UserDefaults.standard.data(forKey: prLiftsKey),
           let lifts = try? JSONDecoder().decode(Set<String>.self, from: data) {
            selectedPRLifts = lifts
        } else {
            selectedPRLifts = defaultPRLifts
        }
        
        // Load Rep Max lifts
        if let data = UserDefaults.standard.data(forKey: repMaxLiftsKey),
           let lifts = try? JSONDecoder().decode(Set<String>.self, from: data) {
            selectedRepMaxLifts = lifts
        } else {
            selectedRepMaxLifts = defaultRepMaxLifts
        }
    }
    
    func saveSettings() {
        // Save PR lifts
        if let data = try? JSONEncoder().encode(selectedPRLifts) {
            UserDefaults.standard.set(data, forKey: prLiftsKey)
        }
        
        // Save Rep Max lifts
        if let data = try? JSONEncoder().encode(selectedRepMaxLifts) {
            UserDefaults.standard.set(data, forKey: repMaxLiftsKey)
        }
    }
    
    // MARK: - Lift Management
    
    func togglePRLift(_ lift: String) {
        if selectedPRLifts.contains(lift) {
            selectedPRLifts.remove(lift)
        } else {
            selectedPRLifts.insert(lift)
        }
        saveSettings()
    }
    
    func toggleRepMaxLift(_ lift: String) {
        if selectedRepMaxLifts.contains(lift) {
            selectedRepMaxLifts.remove(lift)
        } else {
            selectedRepMaxLifts.insert(lift)
        }
        saveSettings()
    }
    
    func resetToDefaults() {
        selectedPRLifts = defaultPRLifts
        selectedRepMaxLifts = defaultRepMaxLifts
        saveSettings()
    }
    
    // MARK: - Validation
    
    var canAddMorePRLifts: Bool {
        return selectedPRLifts.count < 6
    }
    
    var canAddMoreRepMaxLifts: Bool {
        return selectedRepMaxLifts.count < 4
    }
}

// MARK: - Fitness Lift Settings View

struct FitnessLiftSettingsView: View {
    @ObservedObject var settings: FitnessLiftSettings
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Personal Records Section
                    prLiftsSection
                    
                    // Rep Max Estimations Section
                    repMaxLiftsSection
                    
                    // Reset Button
                    resetSection
                }
                .padding()
            }
            .navigationTitle("Lift Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - PR Lifts Section
    
    private var prLiftsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Personal Records")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(settings.selectedPRLifts.count)/6")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
            
            Text("Choose up to 6 lifts to display in your Personal Records section")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(settings.availableLifts, id: \.self) { lift in
                    LiftSelectionCard(
                        lift: lift,
                        isSelected: settings.selectedPRLifts.contains(lift),
                        isDisabled: !settings.selectedPRLifts.contains(lift) && !settings.canAddMorePRLifts,
                        onTap: {
                            settings.togglePRLift(lift)
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Rep Max Lifts Section
    
    private var repMaxLiftsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rep Max Estimations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(settings.selectedRepMaxLifts.count)/4")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
            
            Text("Choose up to 4 lifts to display in your Rep Max Estimations section")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(settings.availableLifts, id: \.self) { lift in
                    LiftSelectionCard(
                        lift: lift,
                        isSelected: settings.selectedRepMaxLifts.contains(lift),
                        isDisabled: !settings.selectedRepMaxLifts.contains(lift) && !settings.canAddMoreRepMaxLifts,
                        onTap: {
                            settings.toggleRepMaxLift(lift)
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                settings.resetToDefaults()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reset to Defaults")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .foregroundColor(.primary)
            }
            
            Text("This will reset both sections to their default lift selections")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Lift Selection Card

struct LiftSelectionCard: View {
    let lift: String
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .secondary)
                
                Text(lift)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isDisabled ? .secondary : .primary)
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Personal Records Lift Selection View

struct PersonalRecordsLiftSelectionView: View {
    @ObservedObject var settings: FitnessLiftSettings
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Personal Records Section
                    prLiftsSection
                    
                    // Reset Button
                    resetSection
                }
                .padding()
            }
            .navigationTitle("Select PR Lifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - PR Lifts Section
    
    private var prLiftsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Personal Records")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(settings.selectedPRLifts.count)/6")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
            
            Text("Choose up to 6 lifts to display in your Personal Records section")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(settings.availableLifts, id: \.self) { lift in
                    LiftSelectionCard(
                        lift: lift,
                        isSelected: settings.selectedPRLifts.contains(lift),
                        isDisabled: !settings.selectedPRLifts.contains(lift) && !settings.canAddMorePRLifts,
                        onTap: {
                            settings.togglePRLift(lift)
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                settings.resetToDefaults()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reset to Defaults")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .foregroundColor(.primary)
            }
            
            Text("This will reset to the default lift selections")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Rep Max Lift Selection View

struct RepMaxLiftSelectionView: View {
    @ObservedObject var settings: FitnessLiftSettings
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Rep Max Lifts Section
                    repMaxLiftsSection
                    
                    // Reset Button
                    resetSection
                }
                .padding()
            }
            .navigationTitle("Select Rep Max Lifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Rep Max Lifts Section
    
    private var repMaxLiftsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Rep Max Estimations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(settings.selectedRepMaxLifts.count)/4")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }
            
            Text("Choose up to 4 lifts to display in your Rep Max Estimations section")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(settings.availableLifts, id: \.self) { lift in
                    LiftSelectionCard(
                        lift: lift,
                        isSelected: settings.selectedRepMaxLifts.contains(lift),
                        isDisabled: !settings.selectedRepMaxLifts.contains(lift) && !settings.canAddMoreRepMaxLifts,
                        onTap: {
                            settings.toggleRepMaxLift(lift)
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Reset Section
    
    private var resetSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                settings.resetToDefaults()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Reset to Defaults")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .foregroundColor(.primary)
            }
            
            Text("This will reset to the default lift selections")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Filtered One Rep Max Dashboard

struct FilteredOneRepMaxDashboard: View {
    @ObservedObject var oneRepMaxManager: OneRepMaxManager
    @ObservedObject var liftSettings: FitnessLiftSettings
    @ObservedObject var filterSettings: MaxFilterSettings
    @Environment(\.presentationMode) var presentationMode
    @State private var showingLiftSelection = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header with stats
                    headerSection
                    
                    // Selected lifts grid
                    selectedLiftsSection
                }
                .padding()
            }
            .navigationTitle("Selected PR Lifts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingLiftSelection = true
                    }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
        }
        .sheet(isPresented: $showingLiftSelection) {
            PersonalRecordsLiftSelectionView(settings: liftSettings)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Records")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Showing \(filteredLifts.count) selected lifts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(oneRepMaxManager.personalRecords.count)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("Total Records")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Selected Lifts Section
    
    private var selectedLiftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Lifts")
                    .font(.headline)
                Spacer()
                Text("\(filteredLifts.count) lifts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(filteredLifts, id: \.self) { lift in
                    LiftCard(
                        liftName: lift,
                        personalRecord: oneRepMaxManager.getPersonalRecord(for: lift),
                        isCustom: oneRepMaxManager.customLifts.contains(lift),
                        onTap: {
                            // Handle tap to add record
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredLifts: [String] {
        let allLifts = oneRepMaxManager.getAllLifts()
        let filteredBySettings = allLifts.filter { lift in
            liftSettings.selectedPRLifts.contains(lift)
        }
        return filterSettings.getFilteredLifts(filteredBySettings, customLifts: oneRepMaxManager.customLifts)
    }
}

#Preview {
    FitnessLiftSettingsView(settings: FitnessLiftSettings())
}
