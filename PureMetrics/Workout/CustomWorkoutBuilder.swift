import SwiftUI

struct CustomWorkoutBuilder: View {
    @EnvironmentObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    let editingWorkout: CustomWorkout?
    
    @State private var workoutName = ""
    @State private var workoutDescription = ""
    @State private var selectedExercises: [WorkoutExercise] = []
    @State private var showingExerciseSelector = false
    @State private var selectedExerciseType: ExerciseType?
    @State private var showingSaveConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var editingIndex: Int?
    @State private var exerciseSetInputs: [Int: [SetInput]] = [:]
    @FocusState private var isTextFieldFocused: Bool
    
    init(editingWorkout: CustomWorkout? = nil) {
        self.editingWorkout = editingWorkout
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Workout Info
                    workoutInfoSection
                    
                    // Exercises List
                    exercisesSection
                    
                    // Add Exercise Button
                    addExerciseSection
                    
                    // Save Button
                    saveButtonSection
                }
                .padding(.bottom, 20)
            }
            .onTapGesture {
                isTextFieldFocused = false
            }
            .onAppear {
                if let workout = editingWorkout {
                    workoutName = workout.name
                    workoutDescription = workout.description ?? ""
                    selectedExercises = workout.exercises
                    
                    // Initialize set inputs for existing exercises
                    for (index, exercise) in workout.exercises.enumerated() {
                        if let plannedSets = exercise.plannedSets, !plannedSets.isEmpty {
                            var setInputs: [SetInput] = []
                            for plannedSet in plannedSets {
                                let setInput = SetInput(
                                    reps: plannedSet.reps?.description ?? "",
                                    weight: plannedSet.weight?.description ?? "",
                                    time: plannedSet.time?.description ?? "",
                                    distance: plannedSet.distance?.description ?? ""
                                )
                                setInputs.append(setInput)
                            }
                            exerciseSetInputs[index] = setInputs
                        } else {
                            exerciseSetInputs[index] = [SetInput()]
                        }
                    }
                }
            }
            .navigationTitle(editingWorkout != nil ? "Edit Workout" : "Custom Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // Delete button (only when editing existing workout)
                        if editingWorkout != nil {
                            Button("Delete") {
                                showingDeleteConfirmation = true
                            }
                            .foregroundColor(.red)
                        }
                        
                        // Save button
                        if !selectedExercises.isEmpty {
                            Button("Save") {
                                showingSaveConfirmation = true
                            }
                            .disabled(workoutName.isEmpty)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingExerciseSelector) {
            UnifiedExerciseSelector(
                selectedExercise: $selectedExerciseType,
                onExerciseSelected: { exerciseType in
                    addExercise(exerciseType)
                },
                onCustomExerciseSelected: { customExercise in
                    addCustomExercise(customExercise)
                },
                dataManager: dataManager
            )
        }
        .alert("Save Custom Workout", isPresented: $showingSaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveCustomWorkout()
            }
        } message: {
            Text("This will save your custom workout template for future use.")
        }
        .alert("Delete Workout", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCustomWorkout()
            }
        } message: {
            if let workout = editingWorkout {
                Text("Are you sure you want to delete '\(workout.name)'? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(editingWorkout != nil ? "Edit Custom Workout" : "Create Custom Workout")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(editingWorkout != nil ? "Modify your workout template" : "Build your own workout template with exercises, sets, and reps")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Workout Info Section
    
    private var workoutInfoSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Workout Name")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                TextField("Enter workout name", text: $workoutName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                TextField("Enter workout description", text: $workoutDescription, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Exercises (\(selectedExercises.count))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !selectedExercises.isEmpty {
                    Button("Clear All") {
                        selectedExercises.removeAll()
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
                }
            }
            
            if selectedExercises.isEmpty {
                emptyExercisesView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(Array(selectedExercises.enumerated()), id: \.offset) { index, exercise in
                        VStack(spacing: 12) {
                            ExerciseBuilderCard(
                                exercise: exercise,
                                index: index,
                                isEditing: editingIndex == index,
                                onEdit: {
                                    toggleEditExercise(at: index)
                                },
                                onDelete: {
                                    deleteExercise(at: index)
                                }
                            )
                            
                            // Inline editing when selected
                            if editingIndex == index {
                                InlineExerciseEditor(
                                    exercise: exercise,
                                    exerciseIndex: index,
                                    setInputs: getSetInputs(for: index),
                                    onAddSet: {
                                        addNewSetInput(for: index)
                                    },
                                    onUpdateSet: { setIndex, reps, weight in
                                        updateSetInput(exerciseIndex: index, setIndex: setIndex, reps: reps)
                                        updateSetInput(exerciseIndex: index, setIndex: setIndex, weight: weight)
                                    },
                                    onUpdateTime: { setIndex, time in
                                        updateSetInput(exerciseIndex: index, setIndex: setIndex, time: time)
                                    },
                                    onRemoveSet: { setIndex in
                                        removeSetInput(exerciseIndex: index, setIndex: setIndex)
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Empty Exercises View
    
    private var emptyExercisesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No Exercises Added")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tap 'Add Exercise' to start building your workout")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Add Exercise Section
    
    private var addExerciseSection: some View {
        Button(action: {
            showingExerciseSelector = true
        }) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Add Exercise")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            )
            .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Save Button Section
    
    private var saveButtonSection: some View {
        VStack(spacing: 12) {
            if !selectedExercises.isEmpty {
                Button(action: {
                    showingSaveConfirmation = true
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Save Custom Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: workoutName.isEmpty ? [Color.gray, Color.gray.opacity(0.8)] : [Color.green, Color.green.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: workoutName.isEmpty ? .gray.opacity(0.3) : .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .foregroundColor(.white)
                }
                .disabled(workoutName.isEmpty)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Actions
    
    private func addExercise(_ exerciseType: ExerciseType) {
        let newExercise = WorkoutExercise(
            exerciseType: exerciseType,
            sets: 3,
            reps: 10,
            weight: nil,
            time: nil,
            restTime: 60,
            notes: ""
        )
        selectedExercises.append(newExercise)
    }
    
    private func addCustomExercise(_ customExercise: CustomExercise) {
        let newExercise = WorkoutExercise(
            customExercise: customExercise,
            sets: 3,
            reps: 10,
            weight: nil,
            time: nil,
            restTime: 60,
            notes: ""
        )
        selectedExercises.append(newExercise)
        
        // Initialize set inputs for the new exercise
        let exerciseIndex = selectedExercises.count - 1
        initializeSetInputs(for: exerciseIndex)
        
        // Automatically start editing mode for custom exercises
        editingIndex = exerciseIndex
    }
    
    private func toggleEditExercise(at index: Int) {
        if editingIndex == index {
            // Save changes and close editing
            saveExerciseChanges(at: index)
            editingIndex = nil
        } else {
            // Start editing this exercise
            editingIndex = index
            initializeSetInputs(for: index)
        }
    }
    
    private func saveExerciseChanges(at index: Int) {
        guard index < selectedExercises.count else { return }
        
        let setInputs = getSetInputs(for: index)
        let originalExercise = selectedExercises[index]
        
        // Convert set inputs to planned sets
        var plannedSets: [PlannedSet] = []
        for (setIndex, setInput) in setInputs.enumerated() {
            if let reps = Int(setInput.reps), reps > 0 {
                let weight = Double(setInput.weight) ?? 0.0
                let plannedSet = PlannedSet(
                    setNumber: setIndex + 1,
                    reps: reps,
                    weight: weight
                )
                plannedSets.append(plannedSet)
            }
        }
        
        // Create new WorkoutExercise with updated values
        let updatedExercise: WorkoutExercise
        if let exerciseType = originalExercise.exerciseType {
            updatedExercise = WorkoutExercise(
                exerciseType: exerciseType,
                sets: setInputs.count,
                reps: Int(setInputs.first?.reps ?? "10") ?? 10,
                weight: Double(setInputs.first?.weight ?? "0") ?? 0.0,
                time: originalExercise.time,
                restTime: originalExercise.restTime,
                notes: originalExercise.notes,
                plannedSets: plannedSets
            )
        } else if let customExercise = originalExercise.customExercise {
            updatedExercise = WorkoutExercise(
                customExercise: customExercise,
                sets: setInputs.count,
                reps: Int(setInputs.first?.reps ?? "10") ?? 10,
                weight: Double(setInputs.first?.weight ?? "0") ?? 0.0,
                time: originalExercise.time,
                restTime: originalExercise.restTime,
                notes: originalExercise.notes,
                plannedSets: plannedSets
            )
        } else {
            // Fallback - this shouldn't happen
            updatedExercise = originalExercise
        }
        
        selectedExercises[index] = updatedExercise
    }
    
    private func initializeSetInputs(for index: Int) {
        let exercise = selectedExercises[index]
        
        if let plannedSets = exercise.plannedSets, !plannedSets.isEmpty {
            // Convert planned sets to set inputs
            var setInputs: [SetInput] = []
            for plannedSet in plannedSets {
                let setInput = SetInput(
                    reps: String(plannedSet.reps ?? 0),
                    weight: plannedSet.weight.map { String(format: "%.0f", $0) } ?? ""
                )
                setInputs.append(setInput)
            }
            exerciseSetInputs[index] = setInputs
        } else {
            // Create default set inputs
            let defaultReps = exercise.reps ?? 10
            let defaultWeight = exercise.weight.map { String(format: "%.0f", $0) } ?? ""
            let setInputs = [SetInput(reps: String(defaultReps), weight: defaultWeight)]
            exerciseSetInputs[index] = setInputs
        }
    }
    
    private func getSetInputs(for index: Int) -> [SetInput] {
        return exerciseSetInputs[index] ?? [SetInput()]
    }
    
    private func addNewSetInput(for index: Int) {
        var setInputs = getSetInputs(for: index)
        setInputs.append(SetInput())
        exerciseSetInputs[index] = setInputs
    }
    
    private func updateSetInput(exerciseIndex: Int, setIndex: Int, reps: String) {
        guard var setInputs = exerciseSetInputs[exerciseIndex], setIndex < setInputs.count else { return }
        setInputs[setIndex].reps = reps
        exerciseSetInputs[exerciseIndex] = setInputs
    }
    
    private func updateSetInput(exerciseIndex: Int, setIndex: Int, weight: String) {
        guard var setInputs = exerciseSetInputs[exerciseIndex], setIndex < setInputs.count else { return }
        setInputs[setIndex].weight = weight
        exerciseSetInputs[exerciseIndex] = setInputs
    }
    
    private func updateSetInput(exerciseIndex: Int, setIndex: Int, time: String) {
        guard var setInputs = exerciseSetInputs[exerciseIndex], setIndex < setInputs.count else { return }
        setInputs[setIndex].time = time
        exerciseSetInputs[exerciseIndex] = setInputs
    }
    
    private func removeSetInput(exerciseIndex: Int, setIndex: Int) {
        guard var setInputs = exerciseSetInputs[exerciseIndex], setIndex < setInputs.count else { return }
        setInputs.remove(at: setIndex)
        exerciseSetInputs[exerciseIndex] = setInputs
    }
    
    private func deleteExercise(at index: Int) {
        selectedExercises.remove(at: index)
    }
    
    private func saveCustomWorkout() {
        // Validate workout name
        let trimmedName = workoutName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            // Show error or handle empty name
            return
        }
        
        // Validate that we have exercises
        guard !selectedExercises.isEmpty else {
            // Show error or handle empty exercises
            return
        }
        
        if let existingWorkout = editingWorkout {
            // Update existing workout
            let updatedWorkout = CustomWorkout(
                id: existingWorkout.id,
                name: trimmedName,
                description: workoutDescription.isEmpty ? nil : workoutDescription,
                exercises: selectedExercises,
                createdDate: existingWorkout.createdDate,
                isFavorite: existingWorkout.isFavorite,
                lastUsed: existingWorkout.lastUsed,
                useCount: existingWorkout.useCount
            )
            dataManager.updateCustomWorkout(updatedWorkout)
        } else {
            // Create new workout
            let customWorkout = CustomWorkout(
                name: trimmedName,
                description: workoutDescription.isEmpty ? nil : workoutDescription,
                exercises: selectedExercises,
                createdDate: Date(),
                isFavorite: false
            )
            dataManager.saveCustomWorkout(customWorkout)
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func deleteCustomWorkout() {
        guard let workout = editingWorkout else { return }
        
        // Delete the workout using the data manager
        dataManager.deleteCustomWorkout(workout)
        
        // Dismiss the edit view
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Inline Exercise Editor

struct InlineExerciseEditor: View {
    let exercise: WorkoutExercise
    let exerciseIndex: Int
    let setInputs: [SetInput]
    let onAddSet: () -> Void
    let onUpdateSet: (Int, String, String) -> Void
    let onUpdateTime: (Int, String) -> Void
    let onRemoveSet: (Int) -> Void
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Exercise Name Header
            HStack {
                Text(exercise.exerciseName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Set Input Boxes
            LazyVStack(spacing: 12) {
                ForEach(Array(setInputs.enumerated()), id: \.element.id) { setIndex, setInput in
                    setInputBox(exerciseCategory: exercise.exerciseCategory, setIndex: setIndex, setInput: setInput)
                }
                
                // Add new set button
                Button(action: onAddSet) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Add Another Set")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
    
    private func setInputBox(exerciseCategory: ExerciseCategory, setIndex: Int, setInput: SetInput) -> some View {
        VStack(spacing: 20) {
            // Set Header
            HStack {
                Text("Set \(setIndex + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Remove set button
                if setInputs.count > 1 {
                    Button(action: {
                        onRemoveSet(setIndex)
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Input Fields Grid - Dynamic based on exercise category
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                // Reps Input (for most exercises)
                if shouldShowReps(for: exerciseCategory) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reps")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack {
                            TextField("10", text: Binding(
                                get: { setInput.reps },
                                set: { onUpdateSet(setIndex, $0, setInput.weight) }
                            ))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .focused($isTextFieldFocused)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            )
                            
                            Text("reps")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Weight Input (for strength exercises)
                if shouldShowWeight(for: exerciseCategory) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Weight")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack {
                            TextField("0", text: Binding(
                                get: { setInput.weight },
                                set: { onUpdateSet(setIndex, setInput.reps, $0) }
                            ))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .focused($isTextFieldFocused)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            )
                            
                            Text("lbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Time Input (for cardio and time-based exercises)
                if shouldShowTime(for: exerciseCategory) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Time")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack {
                            TextField("9:15", text: Binding(
                                get: { setInput.time },
                                set: { onUpdateTime(setIndex, $0) }
                            ))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numbersAndPunctuation)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            )
                            
                            Text("min:sec")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Distance Input (for cardio exercises)
                if shouldShowDistance(for: exerciseCategory) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Distance")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack {
                            TextField("3.5", text: Binding(
                                get: { setInput.distance },
                                set: { _ in }
                            ))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            )
                            
                            Text("mi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Input Field Helpers
    
    private func shouldShowReps(for category: ExerciseCategory) -> Bool {
        // Most exercises support reps, except pure cardio
        return category != .cardio
    }
    
    private func shouldShowWeight(for category: ExerciseCategory) -> Bool {
        // Strength exercises support weight
        return [.upperBody, .lowerBody, .coreAbs, .fullBody, .machineBased, .olympic].contains(category)
    }
    
    private func shouldShowTime(for category: ExerciseCategory) -> Bool {
        // All exercises support time - users should be able to track time for any exercise
        return true
    }
    
    private func shouldShowDistance(for category: ExerciseCategory) -> Bool {
        // Only cardio exercises support distance
        return category == .cardio
    }
}

// MARK: - Exercise Builder Card

struct ExerciseBuilderCard: View {
    let exercise: WorkoutExercise
    let index: Int
    let isEditing: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("\(index + 1). \(exercise.exerciseName)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: onEdit) {
                        HStack(spacing: 4) {
                            Image(systemName: isEditing ? "checkmark" : "pencil")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(isEditing ? "Done" : "Edit")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(isEditing ? .green : .blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isEditing ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                        )
                    }
                    
                    Button(action: onDelete) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.caption)
                                .fontWeight(.medium)
                            Text("Delete")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
            }
            
            // Exercise Details
            HStack(spacing: 20) {
                DetailItem(
                    icon: "repeat",
                    value: "\(exercise.sets)",
                    label: "Sets"
                )
                
                DetailItem(
                    icon: "arrow.up.arrow.down",
                    value: "\(exercise.reps ?? 0)",
                    label: "Reps"
                )
                
                if let weight = exercise.weight {
                    DetailItem(
                        icon: "scalemass",
                        value: "\(Int(weight))",
                        label: "Weight"
                    )
                }
                
                if let time = exercise.time {
                    DetailItem(
                        icon: "clock",
                        value: formatTime(time),
                        label: "Time"
                    )
                }
            }
            
            // Rest Time
            HStack {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Rest: \(exercise.restTime ?? 0)s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Detail Item

struct DetailItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}


// MARK: - Planned Set Row

struct PlannedSetRow: View {
    @Binding var plannedSet: PlannedSet
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Set \(plannedSet.setNumber)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Button("Delete") {
                    onDelete()
                }
                .font(.caption)
                .foregroundColor(.red)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", value: Binding(
                        get: { plannedSet.reps },
                        set: { plannedSet.reps = $0 }
                    ), format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading) {
                    Text("Weight (lbs)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", value: Binding(
                        get: { plannedSet.weight },
                        set: { plannedSet.weight = $0 }
                    ), format: .number)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

private func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%d:%02d", minutes, seconds)
}

#Preview {
    CustomWorkoutBuilder()
        .environmentObject(BPDataManager())
}
