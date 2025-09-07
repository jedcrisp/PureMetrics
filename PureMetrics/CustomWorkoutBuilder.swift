import SwiftUI

struct CustomWorkoutBuilder: View {
    @EnvironmentObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var workoutName = ""
    @State private var workoutDescription = ""
    @State private var selectedExercises: [WorkoutExercise] = []
    @State private var showingExerciseSelector = false
    @State private var showingSaveConfirmation = false
    @State private var isEditing = false
    @State private var editingIndex: Int?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
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
            .navigationTitle("Custom Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !selectedExercises.isEmpty {
                        Button("Save") {
                            showingSaveConfirmation = true
                        }
                        .disabled(workoutName.isEmpty)
                    }
                }
            }
        }
        .sheet(isPresented: $showingExerciseSelector) {
            ExerciseSelectorView(
                onExerciseSelected: { exerciseType in
                    addExercise(exerciseType)
                }
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
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Create Custom Workout")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Build your own workout template with exercises, sets, and reps")
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
                    .foregroundColor(.red)
                }
            }
            
            if selectedExercises.isEmpty {
                emptyExercisesView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(Array(selectedExercises.enumerated()), id: \.offset) { index, exercise in
                            ExerciseBuilderCard(
                                exercise: exercise,
                                index: index,
                                onEdit: {
                                    editExercise(at: index)
                                },
                                onDelete: {
                                    deleteExercise(at: index)
                                }
                            )
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
    
    private func editExercise(at index: Int) {
        editingIndex = index
        // You could show an edit sheet here
    }
    
    private func deleteExercise(at index: Int) {
        selectedExercises.remove(at: index)
    }
    
    private func saveCustomWorkout() {
        let customWorkout = CustomWorkout(
            name: workoutName,
            description: workoutDescription.isEmpty ? nil : workoutDescription,
            exercises: selectedExercises,
            createdDate: Date(),
            isFavorite: false
        )
        
        dataManager.saveCustomWorkout(customWorkout)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Exercise Builder Card

struct ExerciseBuilderCard: View {
    let exercise: WorkoutExercise
    let index: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("\(index + 1). \(exercise.exerciseType.rawValue)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundColor(.red)
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
                    value: "\(exercise.reps)",
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
                        value: "\(Int(time))s",
                        label: "Time"
                    )
                }
            }
            
            // Rest Time
            HStack {
                Image(systemName: "timer")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Rest: \(exercise.restTime)s")
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

// MARK: - Exercise Selector View

struct ExerciseSelectorView: View {
    let onExerciseSelected: (ExerciseType) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: ExerciseCategory?
    @State private var showingCategorySelector = true
    
    var body: some View {
        NavigationView {
            VStack {
                if showingCategorySelector {
                    ExerciseCategorySelector(
                        selectedCategory: $selectedCategory,
                        onCategorySelected: { category in
                            selectedCategory = category
                            showingCategorySelector = false
                        }
                    )
                } else if let category = selectedCategory {
                    ExerciseSelector(
                        category: category,
                        selectedExercise: .constant(nil)
                    ) { exerciseType in
                        onExerciseSelected(exerciseType)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Back") {
                                showingCategorySelector = true
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CustomWorkoutBuilder()
        .environmentObject(BPDataManager())
}
