import SwiftUI

struct ReuseWorkoutView: View {
    let workout: FitnessSession
    @EnvironmentObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var workoutName = ""
    @State private var selectedExercises: Set<Int> = []
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Workout Name Input
                nameInputSection
                
                // Exercise Selection
                exerciseSelectionSection
                
                // Action Buttons
                actionButtonsSection
            }
            .navigationTitle("Reuse Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            setupInitialState()
        }
        .alert("Start New Workout", isPresented: $showingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Start Workout") {
                startReusedWorkout()
            }
        } message: {
            Text("This will start a new workout with the selected exercises. Any current workout will be saved.")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Based on:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(workout.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(workout.exerciseSessions.count) exercises")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(workout.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Name Input Section
    
    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workout Name")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            TextField("Enter workout name", text: $workoutName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Exercise Selection Section
    
    private var exerciseSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Select Exercises")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(selectedExercises.count == workout.exerciseSessions.count ? "Deselect All" : "Select All") {
                    if selectedExercises.count == workout.exerciseSessions.count {
                        selectedExercises.removeAll()
                    } else {
                        selectedExercises = Set(0..<workout.exerciseSessions.count)
                    }
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(workout.exerciseSessions.enumerated()), id: \.offset) { index, exercise in
                        ExerciseSelectionCard(
                            exercise: exercise,
                            index: index + 1,
                            isSelected: selectedExercises.contains(index),
                            onToggle: {
                                toggleExerciseSelection(index)
                            }
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingConfirmation = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                    Text("Start Workout")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: selectedExercises.isEmpty ? [Color.gray, Color.gray.opacity(0.8)] : [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: selectedExercises.isEmpty ? .gray.opacity(0.3) : .green.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .foregroundColor(.white)
            }
            .disabled(selectedExercises.isEmpty || workoutName.isEmpty)
            
            if !selectedExercises.isEmpty {
                Text("\(selectedExercises.count) exercises selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }
    
    // MARK: - Helper Functions
    
    private func setupInitialState() {
        workoutName = workout.displayName + " (Copy)"
        selectedExercises = Set(0..<workout.exerciseSessions.count)
    }
    
    private func toggleExerciseSelection(_ index: Int) {
        if selectedExercises.contains(index) {
            selectedExercises.remove(index)
        } else {
            selectedExercises.insert(index)
        }
    }
    
    private func startReusedWorkout() {
        // Clear current session if it has exercises
        if !dataManager.currentFitnessSession.exerciseSessions.isEmpty {
            dataManager.saveCurrentFitnessSession()
        }
        
        // Create new session with selected exercises
        dataManager.clearCurrentFitnessSession()
        
        // Add selected exercises
        for index in selectedExercises.sorted() {
            let exercise = workout.exerciseSessions[index]
            if let exerciseType = exercise.exerciseType {
                _ = dataManager.addExerciseSession(exerciseType)
            } else if let customExercise = exercise.customExercise {
                _ = dataManager.addCustomExerciseSession(customExercise)
            }
        }
        
        // Set custom name if provided
        if !workoutName.isEmpty && workoutName != workout.displayName {
            // You could add a custom name property to FitnessSession if needed
        }
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Exercise Selection Card

struct ExerciseSelectionCard: View {
    let exercise: ExerciseSession
    let index: Int
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .green : .secondary)
                
                // Exercise Info
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(index). \(exercise.exerciseName)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Text("\(exercise.sets.count) sets")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(exercise.totalReps) reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let maxWeight = exercise.maxWeight, maxWeight > 0 {
                            Text("Max: \(Int(maxWeight)) lbs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ReuseWorkoutView(workout: FitnessSession())
        .environmentObject(BPDataManager())
}
