import SwiftUI

struct EditOneRepMaxRecordView: View {
    @ObservedObject var oneRepMaxManager: OneRepMaxManager
    let record: OneRepMax
    
    @State private var liftName: String
    @State private var recordType: PersonalBestType
    @State private var value: String
    @State private var minutes: String
    @State private var seconds: String
    @State private var date: Date
    @State private var notes: String
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.presentationMode) var presentationMode
    
    init(oneRepMaxManager: OneRepMaxManager, record: OneRepMax) {
        self.oneRepMaxManager = oneRepMaxManager
        self.record = record
        self._liftName = State(initialValue: record.liftName)
        self._recordType = State(initialValue: record.recordType)
        
        // Convert stored seconds back to minutes:seconds format for display
        let displayValue: String
        let minutesValue: String
        let secondsValue: String
        if record.recordType == .time {
            let minutesInt = Int(record.value) / 60
            let secondsInt = Int(record.value) % 60
            displayValue = String(format: "%d:%02d", minutesInt, secondsInt)
            minutesValue = String(minutesInt)
            secondsValue = String(secondsInt) // Don't pre-format to avoid "00" issue
        } else {
            displayValue = String(format: "%.1f", record.value)
            minutesValue = ""
            secondsValue = ""
        }
        self._value = State(initialValue: displayValue)
        self._minutes = State(initialValue: minutesValue)
        self._seconds = State(initialValue: secondsValue)
        
        self._date = State(initialValue: record.date)
        self._notes = State(initialValue: record.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Record Details")) {
                    TextField("Lift Name", text: $liftName)
                        .disabled(true) // Don't allow changing lift name
                    
                    Picker("Record Type", selection: $recordType) {
                        ForEach(PersonalBestType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }.tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if recordType == .time {
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
                            Text(recordType.unit)
                                .foregroundColor(.secondary)
                        }
                    }
                    
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
    
    private var placeholderText: String {
        switch recordType {
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
        switch recordType {
        case .weight, .volume, .distance, .time:
            return .decimalPad
        case .reps:
            return .numberPad
        }
    }
    
    private var isValidInput: Bool {
        let liftValid = !liftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let valueValid: Bool
        if recordType == .time {
            let minutesInt = Int(minutes) ?? 0
            let secondsInt = Int(seconds) ?? 0
            valueValid = !minutes.isEmpty && !seconds.isEmpty && 
                        minutesInt >= 0 && secondsInt >= 0 && secondsInt < 60
        } else {
            valueValid = !value.isEmpty && Double(value) != nil && Double(value)! > 0
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
        let valueDouble: Double
        if recordType == .time {
            let minutesInt = Int(minutes) ?? 0
            let secondsInt = Int(seconds) ?? 0
            guard minutesInt >= 0 && secondsInt >= 0 && secondsInt < 60 else {
                alertMessage = "Please enter valid time values (seconds must be 0-59)."
                showingAlert = true
                return
            }
            valueDouble = Double(minutesInt * 60 + secondsInt)
        } else {
            guard let doubleValue = Double(value), doubleValue > 0 else {
                alertMessage = "Please enter a valid value."
                showingAlert = true
                return
            }
            valueDouble = doubleValue
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
            recordType: recordType,
            value: valueDouble,
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
            recordType: .weight,
            value: 225.0,
            date: Date(),
            notes: "Felt strong today"
        )
    )
}
