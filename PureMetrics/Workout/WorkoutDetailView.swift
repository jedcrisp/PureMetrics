import SwiftUI

struct WorkoutDetailView: View {
    let workout: FitnessSession
    @EnvironmentObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingReuseWorkout = false
    @State private var isEditing = false
    @State private var showingDeleteSetAlert = false
    @State private var setToDelete: (exerciseIndex: Int, setIndex: Int)?
    
    // Get the current workout data from the data manager
    private var currentWorkout: FitnessSession {
        // Use the passed workout directly to avoid potential infinite loops
        workout
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerSection
                
                // Stats Overview
                statsSection
                
                // Exercises
                exercisesSection
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        isEditing.toggle()
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            dataManager.toggleWorkoutFavorite(currentWorkout)
                        }) {
                            Image(systemName: currentWorkout.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(currentWorkout.isFavorite ? .red : .primary)
                        }
                    }
                }
            }
        .sheet(isPresented: $showingReuseWorkout) {
            ReuseWorkoutView(workout: currentWorkout)
        }
        .alert("Delete Set", isPresented: $showingDeleteSetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let setToDelete = setToDelete {
                    dataManager.deleteSetFromWorkout(
                        workoutId: currentWorkout.id,
                        exerciseIndex: setToDelete.exerciseIndex,
                        setIndex: setToDelete.setIndex
                    )
                }
            }
        } message: {
            Text("Are you sure you want to delete this set? This action cannot be undone.")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentWorkout.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(currentWorkout.startTime.formatted(date: .complete, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatDuration(currentWorkout.duration))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if currentWorkout.isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Completed")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    icon: "figure.strengthtraining.traditional",
                    title: "Exercises",
                    value: "\(currentWorkout.exerciseSessions.count)",
                    color: .blue
                )
                
                StatCard(
                    icon: "repeat",
                    title: "Total Sets",
                    value: "\(currentWorkout.totalSets)",
                    color: .green
                )
                
                StatCard(
                    icon: "arrow.up.arrow.down",
                    title: "Total Reps",
                    value: "\(currentWorkout.totalReps)",
                    color: .orange
                )
                
                StatCard(
                    icon: "clock",
                    title: "Duration",
                    value: formatDuration(currentWorkout.duration),
                    color: .purple
                )
            }
        }
    }
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if currentWorkout.exerciseSessions.isEmpty {
                Text("No exercises recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(currentWorkout.exerciseSessions.enumerated()), id: \.offset) { index, exercise in
                    ExerciseDetailCard(
                        exercise: exercise, 
                        index: index + 1,
                        isEditing: isEditing,
                        dataManager: dataManager,
                        workoutId: currentWorkout.id,
                        exerciseIndex: index,
                        onDeleteSet: { setIndex in
                            setToDelete = (exerciseIndex: index, setIndex: setIndex)
                            showingDeleteSetAlert = true
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingReuseWorkout = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title3)
                    Text("Reuse This Workout")
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
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Exercise Detail Card

struct ExerciseDetailCard: View {
    let exercise: ExerciseSession
    let index: Int
    let isEditing: Bool
    let dataManager: BPDataManager
    let workoutId: UUID
    let exerciseIndex: Int
    let onDeleteSet: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header
            HStack {
                Text("\(index). \(exercise.exerciseType.rawValue)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let maxWeight = exercise.maxWeight, maxWeight > 0 {
                    Text("Max: \(Int(maxWeight)) lbs")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            // Sets
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Sets (\(exercise.sets.count))")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if isEditing && !exercise.sets.isEmpty {
                        Button("Remove All") {
                            dataManager.clearAllSetsFromExercise(
                                workoutId: workoutId,
                                exerciseIndex: exerciseIndex
                            )
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.1))
                        )
                    }
                }
                
                if isEditing && !exercise.sets.isEmpty {
                    Text("Tap 'Remove' or swipe left on any set to delete it")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIndex, set in
                    HStack {
                        Text("Set \(setIndex + 1)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .frame(width: 50, alignment: .leading)
                        
                        if let reps = set.reps {
                            Text("\(reps) reps")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        if let weight = set.weight, weight > 0 {
                            Text("@ \(Int(weight)) lbs")
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        
                        if let time = set.time, time > 0 {
                            Text("(\(Int(time))s)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if isEditing {
                            Button(action: {
                                onDeleteSet(setIndex)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "trash")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text("Remove")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.red)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.1))
                                )
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if isEditing {
                            Button("Remove Set") {
                                onDeleteSet(setIndex)
                            }
                            .tint(.red)
                        }
                    }
                }
            }
            
            // Summary
            HStack {
                Text("Total: \(exercise.totalReps) reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if exercise.totalTime > 0 {
                    Text("Time: \(Int(exercise.totalTime))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
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

#Preview {
    WorkoutDetailView(workout: FitnessSession())
        .environmentObject(BPDataManager())
}
