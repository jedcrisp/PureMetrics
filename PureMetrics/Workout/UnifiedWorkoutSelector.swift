import SwiftUI

struct UnifiedWorkoutSelector: View {
    @ObservedObject var workoutManager: PreBuiltWorkoutManager
    @Binding var selectedWorkout: PreBuiltWorkout?
    let onWorkoutSelected: (PreBuiltWorkout) -> Void
    @EnvironmentObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: WorkoutCategory? = nil
    @State private var selectedDifficulty: WorkoutDifficulty? = nil
    @State private var showFavoritesOnly = false
    @State private var showingWorkoutPreview = false
    @State private var previewWorkout: PreBuiltWorkout? = nil
    @State private var selectedCustomWorkout: CustomWorkout? = nil
    @State private var showingCustomWorkoutPreview = false
    
    private var filteredPreBuiltWorkouts: [PreBuiltWorkout] {
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
    
    private var filteredCustomWorkouts: [CustomWorkout] {
        var workouts = dataManager.customWorkouts
        
        if showFavoritesOnly {
            workouts = workouts.filter { $0.isFavorite }
        }
        
        if let category = selectedCategory {
            // Convert CustomWorkout to WorkoutCategory for filtering
            workouts = workouts.filter { customWorkout in
                // Map custom workout categories to WorkoutCategory
                switch customWorkout.exercises.first?.exerciseCategory {
                case .upperBody: return category == .upperBody
                case .lowerBody: return category == .lowerBody
                case .fullBody: return category == .fullBody
                case .cardio: return category == .cardio
                default: return true
                }
            }
        }
        
        return workouts
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Filter Section
                filterSection
                
                // Workout List
                List {
                    // Pre-Built Workouts Section
                    if !filteredPreBuiltWorkouts.isEmpty {
                        Section("Pre-Built Workouts") {
                            ForEach(filteredPreBuiltWorkouts) { workout in
                                PreBuiltWorkoutCard(
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
                                    isSelected: selectedCustomWorkout?.id == workout.id,
                                    onTap: {
                                        selectedCustomWorkout = workout
                                        showingCustomWorkoutPreview = true
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
                    if filteredPreBuiltWorkouts.isEmpty && filteredCustomWorkouts.isEmpty {
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
                    onStart: {
                        onWorkoutSelected(workout)
                        presentationMode.wrappedValue.dismiss()
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
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
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(spacing: 16) {
            // Favorites Toggle
            HStack {
                Button(action: {
                    showFavoritesOnly.toggle()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: showFavoritesOnly ? "heart.fill" : "heart")
                            .foregroundColor(showFavoritesOnly ? .red : .secondary)
                        Text("Favorites Only")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(showFavoritesOnly ? Color.red.opacity(0.1) : Color(.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
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
    }
    
    // MARK: - Helper Methods
    
    private func convertCustomToPreBuilt(_ customWorkout: CustomWorkout) -> PreBuiltWorkout {
        // Convert CustomWorkout to PreBuiltWorkout for compatibility
        // This is a simplified conversion - you may need to adjust based on your PreBuiltWorkout structure
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

// MARK: - Pre-Built Workout Card

struct PreBuiltWorkoutCard: View {
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
                        Image(systemName: "tag.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(workout.category.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Difficulty
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(workout.difficulty.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(workout.estimatedDuration) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}


// MARK: - Previews

#Preview {
    UnifiedWorkoutSelector(
        workoutManager: PreBuiltWorkoutManager(),
        selectedWorkout: .constant(nil),
        onWorkoutSelected: { _ in }
    )
    .environmentObject(BPDataManager())
}
