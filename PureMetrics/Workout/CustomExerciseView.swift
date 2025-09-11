import SwiftUI

struct CustomExerciseView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager: BPDataManager
    
    let exercise: CustomExercise?
    let onSave: (CustomExercise) -> Void
    
    @State private var exerciseName: String = ""
    @State private var selectedCategory: ExerciseCategory = .upperBody
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(exercise: CustomExercise? = nil, dataManager: BPDataManager, onSave: @escaping (CustomExercise) -> Void) {
        self.exercise = exercise
        self.dataManager = dataManager
        self.onSave = onSave
        
        if let exercise = exercise {
            _exerciseName = State(initialValue: exercise.name)
            _selectedCategory = State(initialValue: exercise.category)
        }
    }
    
    var isEditing: Bool {
        exercise != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Exercise Details")) {
                    TextField("Exercise Name", text: $exerciseName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExerciseCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(colorForCategory(category))
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Preview")) {
                    HStack {
                        Image(systemName: selectedCategory.icon)
                            .foregroundColor(colorForCategory(selectedCategory))
                            .frame(width: 24)
                        
                        Text(exerciseName.isEmpty ? "Exercise Name" : exerciseName)
                            .foregroundColor(exerciseName.isEmpty ? .secondary : .primary)
                        
                        Spacer()
                        
                        Text(selectedCategory.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle(isEditing ? "Edit Exercise" : "Add Custom Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExercise()
                    }
                    .disabled(exerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveExercise() {
        let trimmedName = exerciseName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            alertMessage = "Please enter an exercise name"
            showingAlert = true
            return
        }
        
        // Check for duplicate names (excluding current exercise if editing)
        let existingExercises = dataManager.customExercises.filter { $0.id != exercise?.id }
        if existingExercises.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            alertMessage = "An exercise with this name already exists"
            showingAlert = true
            return
        }
        
        var customExercise: CustomExercise
        
        if let existingExercise = exercise {
            // Editing existing exercise
            customExercise = existingExercise
            customExercise.update(name: trimmedName, category: selectedCategory)
            dataManager.updateCustomExercise(customExercise)
        } else {
            // Creating new exercise
            customExercise = CustomExercise(name: trimmedName, category: selectedCategory)
            dataManager.addCustomExercise(customExercise)
        }
        
        onSave(customExercise)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func colorForCategory(_ category: ExerciseCategory) -> Color {
        switch category {
        case .upperBody:
            return .blue
        case .lowerBody:
            return .green
        case .cardio:
            return .red
        case .coreAbs:
            return .orange
        case .fullBody:
            return .purple
        case .machineBased:
            return .gray
        case .olympic:
            return .yellow
        }
    }
}

#Preview {
    CustomExerciseView(dataManager: BPDataManager()) { _ in }
}
