import SwiftUI

struct CustomWorkoutsLibrary: View {
    @EnvironmentObject var dataManager: BPDataManager
    @State private var showingWorkoutBuilder = false
    @State private var selectedWorkout: CustomWorkout?
    @State private var showingWorkoutDetails = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .newest
    @State private var filterOption: FilterOption = .all
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case name = "Name A-Z"
        case mostUsed = "Most Used"
        case duration = "Duration"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All Workouts"
        case favorites = "Favorites Only"
        case myWorkouts = "My Workouts"
        case preBuilt = "Pre-Built"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Filter and Sort Controls
                filterSection
                
                // Workout List
                if filteredWorkouts.isEmpty {
                    emptyStateView
                } else {
                    workoutList
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingWorkoutBuilder) {
            CustomWorkoutBuilder()
        }
        .sheet(isPresented: $showingWorkoutDetails) {
            if let workout = selectedWorkout {
                CustomWorkoutDetailView(workout: workout)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout Library")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button(action: {
                    showingWorkoutBuilder = true
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search workouts...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            
            // Filter and Sort Controls
            HStack(spacing: 12) {
                // Filter Picker
                Menu {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            filterOption = option
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(filterOption.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                
                // Sort Picker
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            sortOption = option
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Workout List
    
    private var workoutList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredWorkouts, id: \.id) { workout in
                    CustomWorkoutCard(
                        workout: workout,
                        onTap: {
                            selectedWorkout = workout
                            showingWorkoutDetails = true
                        },
                        onStart: {
                            dataManager.loadCustomWorkout(workout)
                        },
                        onFavorite: {
                            dataManager.toggleCustomWorkoutFavorite(workout)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Custom Workouts")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Create your first custom workout template")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingWorkoutBuilder = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Workout")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue)
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Computed Properties
    
    private var filteredWorkouts: [CustomWorkout] {
        var workouts = dataManager.customWorkouts
        
        // Apply search filter
        if !searchText.isEmpty {
            workouts = workouts.filter { workout in
                workout.name.localizedCaseInsensitiveContains(searchText) ||
                workout.description?.localizedCaseInsensitiveContains(searchText) == true ||
                workout.exercises.contains { exercise in
                    exercise.exerciseType.rawValue.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        // Apply category filter
        switch filterOption {
        case .all:
            break
        case .favorites:
            workouts = workouts.filter { $0.isFavorite }
        case .myWorkouts:
            // All custom workouts are "my workouts"
            break
        case .preBuilt:
            // This would be for pre-built workouts if you add them
            workouts = []
        }
        
        // Apply sorting
        switch sortOption {
        case .newest:
            workouts.sort { $0.createdDate > $1.createdDate }
        case .oldest:
            workouts.sort { $0.createdDate < $1.createdDate }
        case .name:
            workouts.sort { $0.name < $1.name }
        case .mostUsed:
            workouts.sort { $0.useCount > $1.useCount }
        case .duration:
            workouts.sort { $0.estimatedDuration > $1.estimatedDuration }
        }
        
        return workouts
    }
}

// MARK: - Custom Workout Card

struct CustomWorkoutCard: View {
    let workout: CustomWorkout
    let onTap: () -> Void
    let onStart: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let description = workout.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button(action: onFavorite) {
                    Image(systemName: workout.isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(workout.isFavorite ? .red : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Stats
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
                    color: .blue
                )
                
                StatItem(
                    icon: "clock",
                    value: "\(workout.estimatedDuration)m",
                    label: "Duration",
                    color: .blue
                )
                
                StatItem(
                    icon: "arrow.up.arrow.down",
                    value: "\(workout.useCount)",
                    label: "Used",
                    color: .blue
                )
            }
            
            // Exercise Preview
            if !workout.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Exercises:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text(exercisePreview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: onTap) {
                    HStack(spacing: 6) {
                        Image(systemName: "info.circle")
                        Text("Details")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                
                Button(action: onStart) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                        Text("Start")
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                    )
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    private var exercisePreview: String {
        let exerciseNames = workout.exercises.prefix(3).map { $0.exerciseType.rawValue }
        let preview = exerciseNames.joined(separator: ", ")
        
        if workout.exercises.count > 3 {
            return preview + " +\(workout.exercises.count - 3) more"
        }
        return preview
    }
}

// MARK: - Custom Workout Detail View

struct CustomWorkoutDetailView: View {
    let workout: CustomWorkout
    @EnvironmentObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var showingStartConfirmation = false
    
    var body: some View {
        NavigationView {
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
                    Button(action: {
                        dataManager.toggleCustomWorkoutFavorite(workout)
                    }) {
                        Image(systemName: workout.isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(workout.isFavorite ? .red : .primary)
                    }
                }
            }
        }
        .alert("Start Workout", isPresented: $showingStartConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Start") {
                dataManager.loadCustomWorkout(workout)
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("This will load the workout exercises into your current session.")
        }
    }
    
    // MARK: - Header Section
    
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
                    value: "\(workout.totalExercises)",
                    color: .blue
                )
                
                StatCard(
                    icon: "repeat",
                    title: "Total Sets",
                    value: "\(workout.totalSets)",
                    color: .green
                )
                
                StatCard(
                    icon: "arrow.up.arrow.down",
                    title: "Total Reps",
                    value: "\(workout.totalReps)",
                    color: .orange
                )
                
                StatCard(
                    icon: "clock",
                    title: "Duration",
                    value: "\(workout.estimatedDuration)m",
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
            
            if workout.exercises.isEmpty {
                Text("No exercises in this workout")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(Array(workout.exercises.enumerated()), id: \.offset) { index, exercise in
                    CustomExerciseDetailCard(exercise: exercise, index: index + 1)
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingStartConfirmation = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "play.circle.fill")
                        .font(.title3)
                    Text("Start This Workout")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Custom Exercise Detail Card

struct CustomExerciseDetailCard: View {
    let exercise: WorkoutExercise
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise Header
            HStack {
                Text("\(index). \(exercise.exerciseType.rawValue)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let weight = exercise.weight {
                    Text("\(Int(weight)) lbs")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
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
            
            // Rest Time and Notes
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Rest: \(Int(exercise.restTime ?? 0))s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !(exercise.notes?.isEmpty ?? true) {
                    HStack {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(exercise.notes ?? "")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
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
    CustomWorkoutsLibrary()
        .environmentObject(BPDataManager())
}
