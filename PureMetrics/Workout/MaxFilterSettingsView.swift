import SwiftUI

struct MaxFilterSettingsView: View {
    @ObservedObject var filterSettings: MaxFilterSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // Record Type Filters
                Section("Record Types") {
                    FilterToggleRow(
                        title: "Weight Records",
                        icon: "scalemass",
                        isOn: $filterSettings.showWeightRecords
                    )
                    
                    FilterToggleRow(
                        title: "Time Records",
                        icon: "clock",
                        isOn: $filterSettings.showTimeRecords
                    )
                    
                    FilterToggleRow(
                        title: "Distance Records",
                        icon: "location",
                        isOn: $filterSettings.showDistanceRecords
                    )
                    
                    FilterToggleRow(
                        title: "Rep Records",
                        icon: "arrow.up.arrow.down",
                        isOn: $filterSettings.showRepRecords
                    )
                    
                    FilterToggleRow(
                        title: "Volume Records",
                        icon: "scalemass.fill",
                        isOn: $filterSettings.showVolumeRecords
                    )
                    
                    Button("Reset Record Types") {
                        filterSettings.resetRecordTypeFilters()
                    }
                    .foregroundColor(.blue)
                }
                
                // Lift Type Filters
                Section("Lift Types") {
                    FilterToggleRow(
                        title: "Major Lifts",
                        icon: "dumbbell",
                        isOn: $filterSettings.showMajorLifts
                    )
                    
                    FilterToggleRow(
                        title: "Custom Lifts",
                        icon: "person.crop.circle",
                        isOn: $filterSettings.showCustomLifts
                    )
                    
                    Button("Reset Lift Types") {
                        filterSettings.resetLiftTypeFilters()
                    }
                    .foregroundColor(.blue)
                }
                
                // Rep Estimation Filters
                Section("Rep Estimations") {
                    FilterToggleRow(
                        title: "Show Rep Estimations",
                        icon: "chart.line.uptrend.xyaxis",
                        isOn: $filterSettings.showRepEstimations
                    )
                    
                    if filterSettings.showRepEstimations {
                        FilterToggleRow(
                            title: "2 Rep Max",
                            icon: "2.circle",
                            isOn: $filterSettings.show2RM
                        )
                        
                        FilterToggleRow(
                            title: "3 Rep Max",
                            icon: "3.circle",
                            isOn: $filterSettings.show3RM
                        )
                        
                        FilterToggleRow(
                            title: "5 Rep Max",
                            icon: "5.circle",
                            isOn: $filterSettings.show5RM
                        )
                        
                        FilterToggleRow(
                            title: "10 Rep Max",
                            icon: "10.circle",
                            isOn: $filterSettings.show10RM
                        )
                    }
                    
                    Button("Reset Estimations") {
                        filterSettings.resetEstimationFilters()
                    }
                    .foregroundColor(.blue)
                }
                
                // Calculation Methods
                Section("Calculation Methods") {
                    FilterToggleRow(
                        title: "Epley Formula",
                        icon: "function",
                        isOn: $filterSettings.showEpleyFormula
                    )
                    
                    FilterToggleRow(
                        title: "Brzycki Formula",
                        icon: "function",
                        isOn: $filterSettings.showBrzyckiFormula
                    )
                }
                
                // Sorting Options
                Section("Sorting") {
                    Picker("Sort By", selection: $filterSettings.sortBy) {
                        ForEach(SortOption.allCases, id: \.self) { option in
                            HStack {
                                Image(systemName: option.icon)
                                Text(option.rawValue)
                            }.tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Order", selection: $filterSettings.sortOrder) {
                        ForEach(SortOrder.allCases, id: \.self) { order in
                            HStack {
                                Image(systemName: order.icon)
                                Text(order.rawValue)
                            }.tag(order)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Reset All
                Section {
                    Button("Reset All Filters") {
                        showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filter Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        filterSettings.saveSettings()
                        dismiss()
                    }
                }
            }
        }
        .alert("Reset All Filters", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                filterSettings.resetToDefaults()
            }
        } message: {
            Text("This will reset all filter settings to their default values. This action cannot be undone.")
        }
    }
}

// MARK: - Filter Toggle Row

struct FilterToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

// MARK: - Filter Summary View

struct FilterSummaryView: View {
    @ObservedObject var filterSettings: MaxFilterSettings
    
    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .foregroundColor(.blue)
            
            Text("Filters Active")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("\(activeFilterCount) filters")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private var activeFilterCount: Int {
        var count = 0
        
        // Count disabled record types
        if !filterSettings.showWeightRecords { count += 1 }
        if !filterSettings.showTimeRecords { count += 1 }
        if !filterSettings.showDistanceRecords { count += 1 }
        if !filterSettings.showRepRecords { count += 1 }
        if !filterSettings.showVolumeRecords { count += 1 }
        
        // Count disabled lift types
        if !filterSettings.showMajorLifts { count += 1 }
        if !filterSettings.showCustomLifts { count += 1 }
        
        // Count disabled estimations
        if !filterSettings.showRepEstimations { count += 1 }
        if !filterSettings.show2RM { count += 1 }
        if !filterSettings.show3RM { count += 1 }
        if !filterSettings.show5RM { count += 1 }
        if !filterSettings.show10RM { count += 1 }
        
        // Count disabled formulas
        if !filterSettings.showEpleyFormula { count += 1 }
        if !filterSettings.showBrzyckiFormula { count += 1 }
        
        return count
    }
}

// MARK: - Preview

#Preview {
    MaxFilterSettingsView(filterSettings: MaxFilterSettings())
}
