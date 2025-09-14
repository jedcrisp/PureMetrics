import SwiftUI

struct WorkoutSelector: View {
    @ObservedObject var workoutManager: PreBuiltWorkoutManager
    @Binding var selectedWorkout: PreBuiltWorkout?
    let onWorkoutSelected: (PreBuiltWorkout) -> Void
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var dataManager: BPDataManager
    @State private var selectedCategory: WorkoutCategory? = nil
    @State private var selectedDifficulty: WorkoutDifficulty? = nil
    @State private var showFavoritesOnly = false
    @State private var showingWorkoutPreview = false
    @State private var previewWorkout: PreBuiltWorkout? = nil
    @State private var selectedCustomWorkout: CustomWorkout? = nil
    @State private var showingCustomWorkoutPreview = false
    
    private var filteredWorkouts: [PreBuiltWorkout] {
        var workouts = workoutManager.workouts
        
        if showFavoritesOnly {
            workouts = workouts.filter { $0.isFavorite }
        }
        
        if let category = selectedCategory {
            workouts = workouts.filter { $0.category == category }
        }
        
        if let difficulty = selectedDifficulty {
            workouts = workouts.filter { $0.difficulty == difficulty }
        }
        
        return workouts
    }
    
    private var favoriteWorkouts: [PreBuiltWorkout] {
        return workoutManager.getFavoriteWorkouts()
    }
    
    private var filteredCustomWorkouts: [CustomWorkout] {
        var workouts = dataManager.customWorkouts
        
        if showFavoritesOnly {
            workouts = workouts.filter { $0.isFavorite }
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
                    
                    Text("Choose Workout")
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
                                isSelected: selectedCategory == nil && !showFavoritesOnly,
                                onTap: { 
                                    selectedCategory = nil
                                    showFavoritesOnly = false
                                }
                            )
                            
                            FilterChip(
                                title: "⭐ Favorites",
                                isSelected: showFavoritesOnly,
                                onTap: { 
                                    showFavoritesOnly = true
                                    selectedCategory = nil
                                }
                            )
                            
                            ForEach(WorkoutCategory.allCases, id: \.self) { category in
                                FilterChip(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category && !showFavoritesOnly,
                                    onTap: { 
                                        selectedCategory = category
                                        showFavoritesOnly = false
                                    }
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
                    // Pre-Built Workouts Section
                    if !filteredWorkouts.isEmpty {
                        Section("Pre-Built Workouts") {
                            ForEach(filteredWorkouts) { workout in
                                WorkoutCard(
                                    workout: workout,
                                    isSelected: selectedWorkout?.id == workout.id,
                                    onTap: {
                                        previewWorkout = workout
                                        showingWorkoutPreview = true
                                    },
                                    onFavorite: {
                                        workoutManager.toggleFavorite(workout)
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                    
                    // Custom Workouts Section
                    if !filteredCustomWorkouts.isEmpty {
                        Section("Custom Workouts") {
                            ForEach(filteredCustomWorkouts) { workout in
                                CustomWorkoutCard(
                                    workout: workout,
                                    onTap: {
                                        selectedCustomWorkout = workout
                                        showingCustomWorkoutPreview = true
                                    },
                                    onStart: {
                                        // Convert CustomWorkout to PreBuiltWorkout for compatibility
                                        let preBuiltWorkout = convertCustomToPreBuilt(workout)
                                        onWorkoutSelected(preBuiltWorkout)
                                        presentationMode.wrappedValue.dismiss()
                                    },
                                    onFavorite: {
                                        dataManager.toggleCustomWorkoutFavorite(workout)
                                    }
                                )
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                            }
                        }
                    }
                    
                    // Empty State
                    if filteredWorkouts.isEmpty && filteredCustomWorkouts.isEmpty {
                        Section {
                            VStack(spacing: 16) {
                                Image(systemName: "dumbbell")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No Workouts Found")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Try adjusting your filters or create a custom workout")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingWorkoutPreview) {
            if let workout = previewWorkout {
                PreBuiltWorkoutPreview(
                    workout: workout,
                    onSelect: {
                        selectedWorkout = workout
                        onWorkoutSelected(workout)
                        showingWorkoutPreview = false
                        presentationMode.wrappedValue.dismiss()
                    },
                    onCancel: {
                        showingWorkoutPreview = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingCustomWorkoutPreview) {
            if let workout = selectedCustomWorkout {
                CustomWorkoutPreview(
                    workout: workout,
                    onStart: {
                        // Convert CustomWorkout to PreBuiltWorkout for compatibility
                        let preBuiltWorkout = convertCustomToPreBuilt(workout)
                        onWorkoutSelected(preBuiltWorkout)
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertCustomToPreBuilt(_ customWorkout: CustomWorkout) -> PreBuiltWorkout {
        return PreBuiltWorkout(
            name: customWorkout.name,
            category: .fullBody, // Default category
            description: customWorkout.description ?? "",
            exercises: customWorkout.exercises,
            estimatedDuration: customWorkout.estimatedDuration,
            difficulty: .intermediate, // Default difficulty
            isFavorite: customWorkout.isFavorite
        )
    }
}


// MARK: - Custom Workout Preview

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
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let description = workout.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(workout.estimatedDuration)m")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("Created: \(workout.createdDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Used \(workout.useCount) times")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var workoutInfoSection: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text("\(workout.totalExercises)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("Exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("\(workout.totalSets)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("Sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 4) {
                Text("\(workout.totalReps)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("Reps")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
    }
    
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exercises")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                HStack(spacing: 16) {
                    // Exercise Number
                    Text("\(index + 1)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.blue)
                        )
                    
                    // Exercise Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exercise.exerciseName)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(exercise.displayString)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
            }
        }
    }
    
    private var startButtonSection: some View {
        Button(action: onStart) {
            Text("Start Workout")
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
        .buttonStyle(PlainButtonStyle())
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
    let onFavorite: (() -> Void)?
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.displayName)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(workout.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Favorite Button
                        if let onFavorite = onFavorite {
                            Button(action: onFavorite) {
                                Image(systemName: workout.isFavorite ? "heart.fill" : "heart")
                                    .font(.title3)
                                    .foregroundColor(workout.isFavorite ? .red : .secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Selection Indicator
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
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
