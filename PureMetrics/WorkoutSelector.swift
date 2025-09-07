import SwiftUI

struct WorkoutSelector: View {
    @ObservedObject var workoutManager: PreBuiltWorkoutManager
    @Binding var selectedWorkout: PreBuiltWorkout?
    let onWorkoutSelected: (PreBuiltWorkout) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: WorkoutCategory? = nil
    @State private var selectedDifficulty: WorkoutDifficulty? = nil
    
    private var filteredWorkouts: [PreBuiltWorkout] {
        var workouts = workoutManager.workouts
        
        if let category = selectedCategory {
            workouts = workouts.filter { $0.category == category }
        }
        
        if let difficulty = selectedDifficulty {
            workouts = workouts.filter { $0.difficulty == difficulty }
        }
        
        return workouts
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("Pre-Built Workouts")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Filter Section
                VStack(spacing: 16) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                onTap: { selectedCategory = nil }
                            )
                            
                            ForEach(WorkoutCategory.allCases, id: \.self) { category in
                                FilterChip(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    onTap: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Difficulty Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterChip(
                                title: "All",
                                isSelected: selectedDifficulty == nil,
                                onTap: { selectedDifficulty = nil }
                            )
                            
                            ForEach(WorkoutDifficulty.allCases, id: \.self) { difficulty in
                                FilterChip(
                                    title: difficulty.rawValue,
                                    isSelected: selectedDifficulty == difficulty,
                                    onTap: { selectedDifficulty = difficulty }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                
                Divider()
                
                // Workout List
                List {
                    ForEach(filteredWorkouts) { workout in
                        WorkoutCard(
                            workout: workout,
                            isSelected: selectedWorkout?.id == workout.id,
                            onTap: {
                                selectedWorkout = workout
                                onWorkoutSelected(workout)
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarHidden(true)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct WorkoutCard: View {
    let workout: PreBuiltWorkout
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(workout.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                
                // Details
                HStack(spacing: 16) {
                    // Category
                    HStack(spacing: 4) {
                        Image(systemName: workout.category.icon)
                            .foregroundColor(colorForCategory(workout.category))
                            .font(.caption)
                        Text(workout.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Difficulty
                    HStack(spacing: 4) {
                        Circle()
                            .fill(colorForDifficulty(workout.difficulty))
                            .frame(width: 8, height: 8)
                        Text(workout.difficulty.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                            .font(.caption)
                        Text("\(workout.estimatedDuration) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // Exercise Count
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("\(workout.exercises.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.blue : Color(.systemGray4),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
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

#Preview {
    WorkoutSelector(
        workoutManager: PreBuiltWorkoutManager(),
        selectedWorkout: .constant(nil),
        onWorkoutSelected: { _ in }
    )
}
