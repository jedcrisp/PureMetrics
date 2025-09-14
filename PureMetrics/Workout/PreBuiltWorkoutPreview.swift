import SwiftUI

struct PreBuiltWorkoutPreview: View {
    let workout: PreBuiltWorkout
    let onSelect: () -> Void
    let onCancel: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Workout Details
                    detailsSection
                    
                    // Exercise List
                    exercisesSection
                    
                    // Action Buttons
                    actionButtons
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Workout Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Description
            VStack(alignment: .leading, spacing: 8) {
                Text(workout.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(workout.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Quick Stats
            HStack(spacing: 20) {
                // Category
                HStack(spacing: 6) {
                    Image(systemName: workout.category.icon)
                        .foregroundColor(colorForCategory(workout.category))
                        .font(.title3)
                    Text(workout.category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // Difficulty
                HStack(spacing: 6) {
                    Circle()
                        .fill(colorForDifficulty(workout.difficulty))
                        .frame(width: 12, height: 12)
                    Text(workout.difficulty.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                // Duration
                HStack(spacing: 6) {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("\(workout.estimatedDuration) min")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Details Section
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workout Details")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Exercise Count
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.blue)
                        .font(.title3)
                    Text("\(workout.exercises.count) exercises")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                // Total Sets
                let totalSets = workout.exercises.reduce(0) { $0 + $1.sets }
                HStack {
                    Image(systemName: "number")
                        .foregroundColor(.green)
                        .font(.title3)
                    Text("\(totalSets) total sets")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
                
                // Difficulty Level
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(colorForDifficulty(workout.difficulty))
                        .font(.title3)
                    Text("\(workout.difficulty.rawValue) level")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                    ExercisePreviewCard(
                        exercise: exercise,
                        exerciseNumber: index + 1
                    )
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Select Workout Button
            Button(action: onSelect) {
                HStack {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                    Text("Start This Workout")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .foregroundColor(.white)
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 8)
    }
    
    // MARK: - Helper Functions
    
    private func colorForCategory(_ category: WorkoutCategory) -> Color {
        switch category.color {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "pink": return .pink
        case "teal": return .teal
        default: return .blue
        }
    }
    
    private func colorForDifficulty(_ difficulty: WorkoutDifficulty) -> Color {
        switch difficulty.color {
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .green
        }
    }
}

// MARK: - Exercise Preview Card

struct ExercisePreviewCard: View {
    let exercise: WorkoutExercise
    let exerciseNumber: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Exercise Number
            Text("\(exerciseNumber)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.blue)
                )
            
            // Exercise Details
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.exerciseName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    if let reps = exercise.reps {
                        Text("\(exercise.sets) × \(reps) reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let time = exercise.time {
                        Text(formatTime(time))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let restTime = exercise.restTime {
                        Text("\(formatTime(restTime)) rest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let notes = exercise.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        )
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    PreBuiltWorkoutPreview(
        workout: PreBuiltWorkout(
            name: "Sample Workout",
            category: .upperBody,
            description: "A great workout for building upper body strength and muscle.",
            exercises: [
                WorkoutExercise(exerciseType: .benchPress, sets: 3, reps: 8, restTime: 90, notes: "Focus on form"),
                WorkoutExercise(exerciseType: .inclineBenchPress, sets: 3, reps: 10, restTime: 90, notes: "Upper chest focus")
            ],
            estimatedDuration: 45,
            difficulty: .intermediate
        ),
        onSelect: {},
        onCancel: {}
    )
}
