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
                    
                    // Major lifts grid
                    majorLiftsSection
                    
                    // Custom lifts section
                    if !oneRepMaxManager.customLifts.isEmpty {
                        customLiftsSection
                    }
                    
                    // Recent records
                    recentRecordsSection
                }
                .padding()
            }
            .navigationTitle("One Rep Max")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Add Personal Record") {
                            showingAddRecord = true
                        }
                        Button("Add Custom Lift") {
                            showingAddCustomLift = true
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddRecord) {
            AddOneRepMaxRecordView(oneRepMaxManager: oneRepMaxManager)
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
                Text("Are you sure you want to delete your \(record.liftName) personal record of \(record.formattedWeight)? This action cannot be undone.")
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
                        Text(heaviest.formattedWeight)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Heaviest: \(heaviest.liftName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if let recent = oneRepMaxManager.getMostRecentRecord() {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text("Latest: \(recent.liftName) - \(recent.formattedWeight)")
                        .font(.caption)
                    Spacer()
                    Text(recent.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Major Lifts Section
    
    private var majorLiftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Major Lifts")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(oneRepMaxManager.majorLifts, id: \.self) { lift in
                    LiftCard(
                        liftName: lift,
                        personalRecord: oneRepMaxManager.getPersonalRecord(for: lift),
                        onTap: {
                            selectedLift = lift
                            showingAddRecord = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Custom Lifts Section
    
    private var customLiftsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Custom Lifts")
                    .font(.headline)
                Spacer()
                Button("Manage") {
                    // TODO: Add manage custom lifts view
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(oneRepMaxManager.customLifts, id: \.self) { lift in
                    LiftCard(
                        liftName: lift,
                        personalRecord: oneRepMaxManager.getPersonalRecord(for: lift),
                        isCustom: true,
                        onTap: {
                            selectedLift = lift
                            showingAddRecord = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Recent Records Section
    
    private var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Records")
                    .font(.headline)
                Spacer()
                NavigationLink("View All") {
                    AllRecordsView(oneRepMaxManager: oneRepMaxManager)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if oneRepMaxManager.getRecentRecords().isEmpty {
                Text("No personal records yet. Add your first one!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(oneRepMaxManager.getRecentRecords()) { record in
                    RecentRecordRow(
                        record: record,
                        onEdit: { editingRecord = $0 },
                        onDelete: { 
                            recordToDelete = $0
                            showingDeleteConfirmation = true
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
                        Text(record.formattedWeight)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
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
                Text(record.formattedWeight)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
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
    
    @State private var selectedLift = ""
    @State private var weight = ""
    @State private var selectedDate = Date()
    @State private var notes = ""
    @State private var isCustomLift = false
    @State private var newLiftName = ""
    
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
                    HStack {
                        TextField("Weight", text: $weight)
                            .keyboardType(.decimalPad)
                        Text("lbs")
                            .foregroundColor(.secondary)
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
            if selectedLift.isEmpty {
                selectedLift = oneRepMaxManager.getAllLifts().first ?? ""
            }
        }
    }
    
    private var isValidInput: Bool {
        if isCustomLift {
            return !newLiftName.isEmpty && !weight.isEmpty && Double(weight) != nil
        } else {
            return !selectedLift.isEmpty && !weight.isEmpty && Double(weight) != nil
        }
    }
    
    private func saveRecord() {
        guard let weightValue = Double(weight) else { return }
        
        let liftName = isCustomLift ? newLiftName : selectedLift
        
        let record = OneRepMax(
            liftName: liftName,
            weight: weightValue,
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
                        Text(record.formattedWeight)
                            .font(.title2)
                            .fontWeight(.bold)
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

#Preview {
    OneRepMaxDashboard(oneRepMaxManager: OneRepMaxManager())
}
