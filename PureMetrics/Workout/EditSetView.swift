import SwiftUI

struct EditSetView: View {
    let set: ExerciseSet
    let onSave: (ExerciseSet) -> Void
    let onCancel: () -> Void
    
    @State private var reps: String = ""
    @State private var weight: String = ""
    @State private var time: String = ""
    
    init(set: ExerciseSet, onSave: @escaping (ExerciseSet) -> Void, onCancel: @escaping () -> Void) {
        self.set = set
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Initialize state with current set values
        _reps = State(initialValue: set.reps?.description ?? "")
        _weight = State(initialValue: set.weight?.description ?? "")
        _time = State(initialValue: set.time?.description ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Edit Set")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Modify the set details below")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Form
                VStack(spacing: 20) {
                    // Reps Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reps")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        TextField("Enter reps", text: $reps)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    // Weight Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight (lbs)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        TextField("Enter weight", text: $weight)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                    
                    // Time Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time (seconds)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        TextField("Enter time", text: $time)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: saveSet) {
                        Text("Save Changes")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                    .disabled(!isValidInput)
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationBarHidden(true)
        }
    }
    
    private var isValidInput: Bool {
        // At least one field should have a valid value
        let hasValidReps = !reps.isEmpty && Int(reps) != nil
        let hasValidWeight = !weight.isEmpty && Double(weight) != nil
        let hasValidTime = !time.isEmpty && Double(time) != nil
        
        return hasValidReps || hasValidWeight || hasValidTime
    }
    
    private func saveSet() {
        let repsValue = reps.isEmpty ? nil : Int(reps)
        let weightValue = weight.isEmpty ? nil : Double(weight)
        let timeValue = time.isEmpty ? nil : Double(time)
        
        let updatedSet = ExerciseSet(
            reps: repsValue,
            weight: weightValue,
            time: timeValue
        )
        
        onSave(updatedSet)
    }
}

#Preview {
    EditSetView(
        set: ExerciseSet(reps: 10, weight: 135.0, time: 60.0),
        onSave: { _ in },
        onCancel: { }
    )
}
