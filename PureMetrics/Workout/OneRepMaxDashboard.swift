import SwiftUI

struct OneRepMaxDashboard: View {
    @ObservedObject var oneRepMaxManager: OneRepMaxManager
    @State private var showingAddRecord = false
    @State private var showingAddCustomLift = false
    @State private var selectedLift: String?
    @State private var newCustomLiftName = ""
    @State private var editingRecord: OneRepMax?
    @State private var showingDeleteConfirmation = false
    @State private var recordToDelete: OneRepMax?
    
    init(oneRepMaxManager: OneRepMaxManager) {
        self.oneRepMaxManager = oneRepMaxManager
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Header with stats
                    headerSection
                    
                    // All lifts grid (major + custom)
                    allLiftsSection
                }
                .padding()
            }
            .navigationTitle("One Rep Max")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if oneRepMaxManager.isSyncing {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Syncing...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else if let lastSync = oneRepMaxManager.lastSyncDate {
                        Button(action: {
                            oneRepMaxManager.forceSync()
                        }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Personal Record") {
                            selectedLift = "" // Clear selection so user can choose any lift
                            showingAddRecord = true
                        }
                        Button("Add Custom Lift") {
                            showingAddCustomLift = true
                        }
                        Button("Sync Now") {
                            oneRepMaxManager.forceSync()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            AddOneRepMaxRecordView(
                oneRepMaxManager: oneRepMaxManager,
                preselectedLift: selectedLift
            )
        }
        .sheet(isPresented: $showingAddCustomLift) {
            AddCustomLiftView(
                customLiftName: $newCustomLiftName,
                oneRepMaxManager: oneRepMaxManager,
                isPresented: $showingAddCustomLift
            )
        }
        .sheet(isPresented: Binding<Bool>(
            get: { editingRecord != nil },
            set: { if !$0 { editingRecord = nil } }
        )) {
            if let record = editingRecord {
                EditOneRepMaxRecordView(oneRepMaxManager: oneRepMaxManager, record: record)
            }
        }
        .alert("Delete Personal Record", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let record = recordToDelete {
                    oneRepMaxManager.deletePersonalRecord(record)
                }
            }
        } message: {
            if let record = recordToDelete {
                Text("Are you sure you want to delete your \(record.liftName) \(record.recordType.rawValue.lowercased()) personal record of \(record.formattedValue)? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Personal Records")
                        .font(.headline)
                    Text("\(oneRepMaxManager.getTotalLifts()) lifts tracked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if let heaviest = oneRepMaxManager.getHeaviestLift() {
                        Text(heaviest.formattedValue)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Best \(heaviest.recordType.rawValue): \(heaviest.liftName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - All Lifts Section
    
    private var allLiftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Personal Records")
                    .font(.headline)
                Spacer()
                NavigationLink(destination: ManageCustomLiftsView(oneRepMaxManager: oneRepMaxManager)) {
                    Text("Manage Custom")
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(oneRepMaxManager.getAllLifts(), id: \.self) { lift in
                    LiftCard(
                        liftName: lift,
                        personalRecord: oneRepMaxManager.getPersonalRecord(for: lift),
                        isCustom: oneRepMaxManager.customLifts.contains(lift),
                        onTap: {
                            selectedLift = lift
                            showingAddRecord = true
                        }
                    )
                }
            }
        }
    }
    
}

// MARK: - Lift Card

struct LiftCard: View {
    let liftName: String
    let personalRecord: OneRepMax?
    let isCustom: Bool
    let onTap: () -> Void
    
    init(liftName: String, personalRecord: OneRepMax?, isCustom: Bool = false, onTap: @escaping () -> Void) {
        self.liftName = liftName
        self.personalRecord = personalRecord
        self.isCustom = isCustom
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(liftName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    if isCustom {
                        Image(systemName: "person.crop.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                if let record = personalRecord {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: record.recordType.icon)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(record.formattedValue)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }
                        
                        Text(record.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("No PR yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Tap to add")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Recent Record Row

struct RecentRecordRow: View {
    let record: OneRepMax
    let onEdit: (OneRepMax) -> Void
    let onDelete: (OneRepMax) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.liftName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let notes = record.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Image(systemName: record.recordType.icon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(record.formattedValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Text(record.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Edit and Delete buttons
            HStack(spacing: 8) {
                Button(action: { onEdit(record) }) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Button(action: { onDelete(record) }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Add One Rep Max Record View

struct AddOneRepMaxRecordView: View {
    @ObservedObject var oneRepMaxManager: OneRepMaxManager
    @Environment(\.dismiss) private var dismiss
    
    let preselectedLift: String?
    
    @State private var selectedLift = ""
    @State private var selectedRecordType = PersonalBestType.weight
    @State private var value = ""
    @State private var minutes = ""
    @State private var seconds = ""
    @State private var selectedDate = Date()
    @State private var notes = ""
    @State private var isCustomLift = false
    @State private var newLiftName = ""
    
    init(oneRepMaxManager: OneRepMaxManager, preselectedLift: String? = nil) {
        self.oneRepMaxManager = oneRepMaxManager
        self.preselectedLift = preselectedLift
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Lift") {
                    if isCustomLift {
                        TextField("Custom Lift Name", text: $newLiftName)
                    } else {
                        Picker("Select Lift", selection: $selectedLift) {
                            ForEach(oneRepMaxManager.getAllLifts(), id: \.self) { lift in
                                Text(lift).tag(lift)
                            }
                        }
                    }
                    
                    Toggle("Custom Lift", isOn: $isCustomLift)
                }
                
                Section("Record Details") {
                    Picker("Record Type", selection: $selectedRecordType) {
                        ForEach(PersonalBestType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }.tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if selectedRecordType == .time {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Minutes")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("0", text: $minutes)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                            
                            Text(":")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                            
                            VStack(alignment: .leading) {
                                Text("Seconds")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                TextField("0", text: $seconds)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: seconds) { newValue in
                                        // Only format to 2 digits when user finishes typing
                                        if let secondsInt = Int(newValue), secondsInt >= 10 {
                                            seconds = String(format: "%02d", secondsInt)
                                        }
                                    }
                            }
                            
                            Spacer()
                        }
                    } else {
                        HStack {
                            TextField(placeholderText, text: $value)
                                .keyboardType(keyboardType)
                            Text(selectedRecordType.unit)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Personal Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRecord()
                    }
                    .disabled(!isValidInput)
                }
            }
        }
        .onAppear {
            // Use preselected lift if available, otherwise use first available lift
            if let preselected = preselectedLift, !preselected.isEmpty {
                selectedLift = preselected
                print("Preselected lift: \(preselected)")
            } else if selectedLift.isEmpty {
                selectedLift = oneRepMaxManager.getAllLifts().first ?? ""
            }
            // Set default record type based on the selected lift
            selectedRecordType = oneRepMaxManager.getDefaultRecordType(for: selectedLift)
            print("Set record type to: \(selectedRecordType) for lift: \(selectedLift)")
        }
        .onChange(of: selectedLift) { newLift in
            // Update record type when lift changes
            selectedRecordType = oneRepMaxManager.getDefaultRecordType(for: newLift)
            print("Changed record type to: \(selectedRecordType) for lift: \(newLift)")
        }
    }
    
    private var placeholderText: String {
        switch selectedRecordType {
        case .weight, .volume:
            return "Weight"
        case .time:
            return "Time (min:sec)"
        case .distance:
            return "Distance"
        case .reps:
            return "Reps"
        }
    }
    
    private var keyboardType: UIKeyboardType {
        switch selectedRecordType {
        case .weight, .volume, .distance, .time:
            return .decimalPad
        case .reps:
            return .numberPad
        }
    }
    
    private var isValidInput: Bool {
        let liftValid = isCustomLift ? !newLiftName.isEmpty : !selectedLift.isEmpty
        let valueValid: Bool
        if selectedRecordType == .time {
            let minutesInt = Int(minutes) ?? 0
            let secondsInt = Int(seconds) ?? 0
            valueValid = !minutes.isEmpty && !seconds.isEmpty && 
                        minutesInt >= 0 && secondsInt >= 0 && secondsInt < 60
        } else {
            valueValid = !value.isEmpty && Double(value) != nil
        }
        return liftValid && valueValid
    }
    
    private func isValidTimeFormat(_ timeString: String) -> Bool {
        // Check if format is MM:SS or M:SS
        let timePattern = "^\\d{1,2}:\\d{2}$"
        let regex = try? NSRegularExpression(pattern: timePattern)
        let range = NSRange(location: 0, length: timeString.utf16.count)
        return regex?.firstMatch(in: timeString, options: [], range: range) != nil
    }
    
    private func convertTimeToSeconds(_ timeString: String) -> Double? {
        let components = timeString.split(separator: ":")
        guard components.count == 2,
              let minutes = Int(components[0]),
              let seconds = Int(components[1]) else {
            return nil
        }
        return Double(minutes * 60 + seconds)
    }
    
    private func saveRecord() {
        let liftName = isCustomLift ? newLiftName : selectedLift
        
        let valueDouble: Double
        if selectedRecordType == .time {
            let minutesInt = Int(minutes) ?? 0
            let secondsInt = Int(seconds) ?? 0
            valueDouble = Double(minutesInt * 60 + secondsInt)
        } else {
            guard let doubleValue = Double(value) else { return }
            valueDouble = doubleValue
        }
        
        let record = OneRepMax(
            liftName: liftName,
            recordType: selectedRecordType,
            value: valueDouble,
            date: selectedDate,
            notes: notes.isEmpty ? nil : notes,
            isCustom: isCustomLift
        )
        
        oneRepMaxManager.addPersonalRecord(record)
        
        if isCustomLift {
            oneRepMaxManager.addCustomLift(newLiftName)
        }
        
        dismiss()
    }
}

// MARK: - Add Custom Lift View

struct AddCustomLiftView: View {
    @Binding var customLiftName: String
    @ObservedObject var oneRepMaxManager: OneRepMaxManager
    @Binding var isPresented: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Custom Lift") {
                    TextField("Lift Name", text: $customLiftName)
                }
                
                Section("Available Lifts") {
                    Text("Major lifts are already available. Add custom lifts for exercises not in the standard list.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Custom Lift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addCustomLift()
                    }
                    .disabled(customLiftName.isEmpty)
                }
            }
        }
    }
    
    private func addCustomLift() {
        oneRepMaxManager.addCustomLift(customLiftName)
        customLiftName = ""
        dismiss()
    }
}

// MARK: - All Records View

struct AllRecordsView: View {
    @ObservedObject var oneRepMaxManager: OneRepMaxManager
    
    var body: some View {
        List {
            ForEach(oneRepMaxManager.personalRecords) { record in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(record.liftName)
                            .font(.headline)
                        Spacer()
                        HStack {
                            Image(systemName: record.recordType.icon)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(record.formattedValue)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    
                    HStack {
                        Text(record.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if record.isCustom {
                            Spacer()
                            Text("Custom")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    if let notes = record.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("All Records")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Manage Custom Lifts View

struct ManageCustomLiftsView: View {
    @ObservedObject var oneRepMaxManager: OneRepMaxManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCustomLift = false
    @State private var newCustomLiftName = ""
    @State private var showingDeleteConfirmation = false
    @State private var liftToDelete: String?
    
    var body: some View {
        NavigationView {
            List {
                if oneRepMaxManager.customLifts.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange.opacity(0.6))
                        
                        Text("No Custom Lifts")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Add custom lifts for exercises not in the standard list.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add Your First Custom Lift") {
                            showingAddCustomLift = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(oneRepMaxManager.customLifts, id: \.self) { liftName in
                        CustomLiftRow(
                            liftName: liftName,
                            personalRecord: oneRepMaxManager.getPersonalRecord(for: liftName),
                            onDelete: {
                                liftToDelete = liftName
                                showingDeleteConfirmation = true
                            }
                        )
                    }
                    .onDelete(perform: deleteCustomLifts)
                }
            }
            .navigationTitle("Custom Lifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddCustomLift = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCustomLift) {
            AddCustomLiftView(
                customLiftName: $newCustomLiftName,
                oneRepMaxManager: oneRepMaxManager,
                isPresented: $showingAddCustomLift
            )
        }
        .alert("Delete Custom Lift", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let liftName = liftToDelete {
                    oneRepMaxManager.removeCustomLift(liftName)
                }
            }
        } message: {
            if let liftName = liftToDelete {
                Text("Are you sure you want to delete '\(liftName)'? This will also delete any personal records for this lift.")
            }
        }
    }
    
    private func deleteCustomLifts(offsets: IndexSet) {
        for index in offsets {
            let liftName = oneRepMaxManager.customLifts[index]
            oneRepMaxManager.removeCustomLift(liftName)
        }
    }
}

// MARK: - Custom Lift Row

struct CustomLiftRow: View {
    let liftName: String
    let personalRecord: OneRepMax?
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(liftName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let record = personalRecord {
                    HStack {
                        Image(systemName: record.recordType.icon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(record.formattedValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No personal record yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    OneRepMaxDashboard(oneRepMaxManager: OneRepMaxManager())
}
