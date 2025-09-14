import SwiftUI

struct WorkoutHistoryView: View {
    @EnvironmentObject var dataManager: BPDataManager
    @State private var selectedWorkout: FitnessSession?
    @State private var showingWorkoutDetails = false
    @State private var searchText = ""
    @State private var sortOption: SortOption = .newest
    @State private var filterOption: FilterOption = .all
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case duration = "Duration"
        case exercises = "Most Exercises"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All Workouts"
        case favorites = "Favorites Only"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
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
        .sheet(isPresented: $showingWorkoutDetails) {
            if let workout = selectedWorkout {
                WorkoutDetailView(workout: workout)
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Workout History")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(filteredWorkouts.count) workouts")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                    FitnessWorkoutCard(
                        workout: workout,
                        onTap: {
                            selectedWorkout = workout
                            showingWorkoutDetails = true
                        },
                        onFavorite: {
                            toggleFavorite(workout)
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
            
            Text("No Workouts Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Start your first workout to see it here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Computed Properties
    
    private var filteredWorkouts: [FitnessSession] {
        var workouts = dataManager.fitnessSessions
        
        // Apply search filter
        if !searchText.isEmpty {
            workouts = workouts.filter { workout in
                workout.exerciseSessions.contains { exercise in
                    exercise.exerciseName.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
        
        // Apply category filter
        switch filterOption {
        case .all:
            break
        case .favorites:
            workouts = workouts.filter { $0.isFavorite }
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            workouts = workouts.filter { $0.startTime >= weekAgo }
        case .thisMonth:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            workouts = workouts.filter { $0.startTime >= monthAgo }
        }
        
        // Apply sorting
        switch sortOption {
        case .newest:
            workouts.sort { $0.startTime > $1.startTime }
        case .oldest:
            workouts.sort { $0.startTime < $1.startTime }
        case .duration:
            workouts.sort { $0.duration > $1.duration }
        case .exercises:
            workouts.sort { $0.exerciseSessions.count > $1.exerciseSessions.count }
        }
        
        return workouts
    }
    
    // MARK: - Actions
    
    private func toggleFavorite(_ workout: FitnessSession) {
        dataManager.toggleWorkoutFavorite(workout)
    }
}

// MARK: - Workout Card

struct FitnessWorkoutCard: View {
    let workout: FitnessSession
    let onTap: () -> Void
    let onFavorite: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(workout.startTime.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: onFavorite) {
                        Image(systemName: workout.isFavorite ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(workout.isFavorite ? .red : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                // Stats
                HStack(spacing: 20) {
                    StatItem(
                        icon: "clock",
                        value: formatDuration(workout.duration),
                        label: "Duration",
                        color: .blue
                    )
                    
                    StatItem(
                        icon: "figure.strengthtraining.traditional",
                        value: "\(workout.exerciseSessions.count)",
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
                        icon: "arrow.up.arrow.down",
                        value: "\(workout.totalReps)",
                        label: "Reps",
                        color: .blue
                    )
                }
                
                // Exercise Preview
                if !workout.exerciseSessions.isEmpty {
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
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var exercisePreview: String {
        let exerciseNames = workout.exerciseSessions.prefix(3).map { $0.exerciseName }
        let preview = exerciseNames.joined(separator: ", ")
        
        if workout.exerciseSessions.count > 3 {
            return preview + " +\(workout.exerciseSessions.count - 3) more"
        }
        return preview
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Stat Item


#Preview {
    WorkoutHistoryView()
        .environmentObject(BPDataManager())
}
