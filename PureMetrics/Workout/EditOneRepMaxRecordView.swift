import SwiftUI

struct EditOneRepMaxRecordView: View {
    @ObservedObject var oneRepMaxManager: OneRepMaxManager
    let record: OneRepMax
    
    @State private var liftName: String
    @State private var weight: String
    @State private var date: Date
    @State private var notes: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    init(oneRepMaxManager: OneRepMaxManager, record: OneRepMax) {
        self.oneRepMaxManager = oneRepMaxManager
        self.record = record
        self._liftName = State(initialValue: record.liftName)
        self._weight = State(initialValue: String(format: "%.1f", record.weight))
        self._date = State(initialValue: record.date)
        self._notes = State(initialValue: record.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Lift Details")) {
                    TextField("Lift Name", text: $liftName)
                        .disabled(true) // Don't allow changing lift name
                    
                    TextField("Weight (lbs)", text: $weight)
                        .keyboardType(.decimalPad)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                Section(header: Text("Notes")) {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Personal Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
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
        .alert("Invalid Input", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isValidInput: Bool {
        guard let weightValue = Double(weight), weightValue > 0 else { return false }
        return !liftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func saveRecord() {
        guard let weightValue = Double(weight), weightValue > 0 else {
            alertMessage = "Please enter a valid weight."
            showingAlert = true
            return
        }
        
        let trimmedLiftName = liftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLiftName.isEmpty else {
            alertMessage = "Please enter a lift name."
            showingAlert = true
            return
        }
        
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let updatedRecord = OneRepMax(
            id: record.id, // Keep the same ID
            liftName: trimmedLiftName,
            weight: weightValue,
            date: date,
            notes: trimmedNotes.isEmpty ? nil : trimmedNotes,
            isCustom: record.isCustom
        )
        
        oneRepMaxManager.updatePersonalRecord(updatedRecord)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    EditOneRepMaxRecordView(
        oneRepMaxManager: OneRepMaxManager(),
        record: OneRepMax(
            liftName: "Bench Press",
            weight: 225.0,
            date: Date(),
            notes: "Felt strong today"
        )
    )
}
