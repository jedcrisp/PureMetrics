import SwiftUI

struct CustomWorkoutPreview: View {
    let workout: CustomWorkout
    let onStart: () -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Workout Info
                    workoutInfoSection
                    
                    // Exercises List
                    exercisesSection
                    
                    // Start Button
                    startButtonSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Workout Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Workout Icon
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            // Workout Name
            Text(workout.displayName)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Description
            if let description = workout.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Workout Info Section
    
    private var workoutInfoSection: some View {
        VStack(spacing: 16) {
            // Stats Row
            HStack(spacing: 20) {
                StatItem(
                    icon: "figure.strengthtraining.traditional",
                    value: "\(workout.totalExercises)",
                    label: "Exercises",
                    color: .blue
                )
                
                StatItem(
                    icon: "repeat",
                    value: "\(workout.totalSets)",
                    label: "Sets",
                    color: .green
                )
                
                StatItem(
                    icon: "clock",
                    value: "\(workout.estimatedDuration)m",
                    label: "Duration",
                    color: .orange
                )
            }
            
            // Additional Info
            HStack(spacing: 20) {
                if workout.useCount > 0 {
                    StatItem(
                        icon: "arrow.up.arrow.down",
                        value: "\(workout.useCount)",
                        label: "Times Used",
                        color: .purple
                    )
                }
                
                if let lastUsed = workout.lastUsed {
                    StatItem(
                        icon: "calendar",
                        value: formatDate(lastUsed),
                        label: "Last Used",
                        color: .red
                    )
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Exercises Section
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                    ExercisePreviewCard(
                        exercise: exercise,
                        exerciseNumber: index + 1
                    )
                }
            }
        }
    }
    
    // MARK: - Start Button Section
    
    private var startButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: onStart) {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill")
                        .font(.title3)
                    Text("Start Workout")
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
            
            Text("This will load the workout template and start your session")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}


// MARK: - Previews

#Preview {
    CustomWorkoutPreview(
        workout: CustomWorkout(
            name: "Sample Custom Workout",
            description: "A sample custom workout for preview",
            exercises: [
                WorkoutExercise(
                    exerciseType: .benchPress,
                    sets: 3,
                    reps: 10,
                    weight: 135
                ),
                WorkoutExercise(
                    exerciseType: .squat,
                    sets: 3,
                    reps: 12,
                    weight: 185
                )
            ],
            createdDate: Date(),
            isFavorite: false
        ),
        onStart: {}
    )
}
