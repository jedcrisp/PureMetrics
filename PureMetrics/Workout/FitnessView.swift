import SwiftUI

struct FitnessView: View {
    @ObservedObject var dataManager: BPDataManager
    @StateObject private var workoutManager = PreBuiltWorkoutManager()
    @State private var selectedExerciseType: ExerciseType? = .benchPress
    @State private var showingExerciseSelector = false
    @State private var showingWorkoutSelector = false
    @State private var selectedExerciseIndices: Set<Int> = []
    @State private var useManualTime = false
    @State private var manualDate = Date()
    @State private var manualTime = Date()
    @State private var exerciseSetInputs: [Int: [SetInput]] = [:]
    @State private var timer: Timer?
    @State private var timerUpdate: Int = 0
    @State private var isWorkoutTemplateLoaded: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var showingCompleteConfirmation: Bool = false
    @State private var showingCustomWorkoutBuilder: Bool = false
    @State private var showingCustomWorkoutSelector: Bool = false
    @State private var hasSessionBeenSaved: Bool = false
    @State private var uiUpdateTrigger: Int = 0
    @State private var exerciseStartTimes: [Int: Date] = [:]
    @State private var expandedRepMaxCards: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        headerSection
                        
                        // Content
                        VStack(spacing: 12) {
                            // One Rep Max Dashboard
                            oneRepMaxSection
                            
                            // Rep Max Estimation
                            repMaxEstimationSection
                            
                            // Session Info
                            sessionInfoSection
                            
                            // Add Exercise Button
                            addExerciseSection
                            
                            
                            // Current Exercises
                            if !dataManager.currentFitnessSession.exerciseSessions.isEmpty {
                                currentExercisesSection
                            }
                            
                            // Action Buttons
                            actionButtonsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                // Only start timer if session is already active
                if dataManager.currentFitnessSession.isActive && !dataManager.currentFitnessSession.isPaused {
                    startTimer()
                }
                // Load custom workouts from Firestore
                dataManager.loadCustomWorkoutsFromFirestore()
            }
            .onDisappear {
                stopTimer()
            }
            .onChange(of: dataManager.currentFitnessSession.isActive) { isActive in
                if isActive {
                    startTimer()
                } else {
                    stopTimer()
                }
            }
            .onChange(of: dataManager.currentFitnessSession.isPaused) { isPaused in
                if isPaused {
                    stopTimer()
                } else if dataManager.currentFitnessSession.isActive {
                    startTimer()
                }
            }
        }
        .sheet(isPresented: $showingExerciseSelector) {
            UnifiedExerciseSelector(
                selectedExercise: $selectedExerciseType
            ) { exerciseType in
                _ = dataManager.addExerciseSession(exerciseType)
                // Initialize set inputs for the new exercise
                let newExerciseIndex = dataManager.currentFitnessSession.exerciseSessions.count - 1
                exerciseSetInputs[newExerciseIndex] = [SetInput()]
                showingExerciseSelector = false
            }
        }
        .sheet(isPresented: $showingWorkoutSelector) {
            WorkoutSelector(
                workoutManager: workoutManager,
                selectedWorkout: .constant(nil)
            ) { workout in
                _ = dataManager.loadPreBuiltWorkout(workout)
                // Initialize set inputs for all exercises
                for i in 0..<dataManager.currentFitnessSession.exerciseSessions.count {
                    exerciseSetInputs[i] = [SetInput()]
                }
                isWorkoutTemplateLoaded = true
                hasSessionBeenSaved = false
                showingWorkoutSelector = false
            }
        }
        .sheet(isPresented: $showingCustomWorkoutBuilder) {
            CustomWorkoutBuilder()
                .environmentObject(dataManager)
        }
        .sheet(isPresented: $showingCustomWorkoutSelector) {
            CustomWorkoutSelector(selectedWorkout: .constant(nil)) { workout in
                startCustomWorkoutSession(workout)
                showingCustomWorkoutSelector = false
            }
        }
        .alert("Delete Workout Template", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataManager.clearWorkoutTemplate()
                exerciseSetInputs.removeAll()
                isWorkoutTemplateLoaded = false
            }
        } message: {
            Text("Are you sure you want to remove the current workout template? This will delete all exercises from the template.")
        }
        .alert("Complete Session", isPresented: $showingCompleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                saveFitnessSession()
            }
            .foregroundColor(.green)
        } message: {
            Text("Are you sure you want to complete and save this fitness session? This will end the current session and save all your progress.")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Top gradient header - tighter around text
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.9),
                    Color.orange.opacity(0.8),
                    Color.red.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 80)
            .overlay(
                VStack(spacing: 0) {
                    // Top section with app name, status, and New Session button
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 0) {
                                Text("PureMetrics")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                                
                                Text(" Fitness")
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            // Live Session Timer
                            if dataManager.currentFitnessSession.isActive || dataManager.currentFitnessSession.isPaused {
                                VStack(alignment: .trailing, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(dataManager.currentFitnessSession.isActive ? Color.green : Color.yellow)
                                            .frame(width: 8, height: 8)
                                        Text(dataManager.currentFitnessSession.isActive ? "Active" : "Paused")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(formatDuration(dataManager.currentFitnessSession.duration))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .id(timerUpdate) // Force update when timer changes
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.white.opacity(0.15))
                                )
                            }
                            
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
                    Spacer()
                }
            )
            
            // White rounded bottom
            Rectangle()
                .fill(Color(.systemGroupedBackground))
                .frame(height: 20)
                .clipShape(
                    .rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 24,
                        bottomTrailingRadius: 24,
                        topTrailingRadius: 0
                    )
                )
        }
    }
    
    // MARK: - One Rep Max Section
    
    private var oneRepMaxSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("One Rep Max")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                NavigationLink(destination: OneRepMaxDashboard(oneRepMaxManager: dataManager.oneRepMaxManager)) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // One Rep Max info
            if !dataManager.oneRepMaxManager.personalRecords.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Personal Records")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(dataManager.oneRepMaxManager.personalRecords.prefix(6), id: \.id) { record in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(record.liftName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Text(record.formattedWeight)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No personal records yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Tap 'View All' to add your first PR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        )
    }
    
    // MARK: - Rep Max Estimation Section
    
    private var repMaxEstimationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Rep Max Estimations")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Based on 1RM")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !dataManager.oneRepMaxManager.personalRecords.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(Array(dataManager.oneRepMaxManager.personalRecords.prefix(4).enumerated()), id: \.element.id) { index, record in
                        if record.recordType == .weight {
                            RepMaxEstimationCard(
                                record: record,
                                isExpanded: expandedRepMaxCards.contains(record.id),
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        if expandedRepMaxCards.contains(record.id) {
                                            expandedRepMaxCards.remove(record.id)
                                        } else {
                                            expandedRepMaxCards.insert(record.id)
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No 1RM records available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Add 1RM records to see rep estimations")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        )
    }
    
    // MARK: - Session Info Section
    
    private var sessionInfoSection: some View {
        HStack(spacing: 30) {
            // Sets Count
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text("\(totalSetsCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 2) {
                    Text("Sets")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("Total")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Reps Count
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text("\(totalRepsCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                VStack(spacing: 2) {
                    Text("Reps")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("Total")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Volume Count
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text("\(Int(totalVolume))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 2) {
                    Text("Volume")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("lbs")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Cardio Time
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundColor(.purple)
                }
                
                VStack(spacing: 2) {
                    Text("Cardio")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(formatDuration(currentSessionCardioTime))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        )
    }
    
    // MARK: - Add Exercise Section
    
    private var addExerciseSection: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Add Exercise")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Delete Template Button (when template is loaded)
                if isWorkoutTemplateLoaded {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            VStack(spacing: 12) {
                
                // Pre-built Workout Button
                Button(action: {
                    showingWorkoutSelector = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.title3)
                        Text(isWorkoutTemplateLoaded ? "Choose Different Workout" : "Choose Pre-Built Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                    .foregroundColor(.white)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // Divider
                HStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                    
                    Text("OR")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                    
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                }
                
                // Add Individual Exercise Button
                Button(action: {
                    showingExerciseSelector = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "dumbbell")
                            .font(.title3)
                        Text("Add Individual Exercise")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(colors: [Color.orange, Color.orange.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                    .foregroundColor(.white)
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                
                // Build Custom Workout Button
                Button(action: {
                    showingCustomWorkoutBuilder = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.title3)
                        Text("Build Custom Workout")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(colors: [Color.purple, Color.purple.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                            )
                    )
                    .foregroundColor(.white)
                    .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                // Custom Workouts Button (if any exist)
                if !dataManager.customWorkouts.isEmpty {
                    Button(action: {
                        showingCustomWorkoutSelector = true
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "bookmark.circle.fill")
                                .font(.title3)
                            Text("Use Custom Workout")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(colors: [Color.green, Color.green.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                        .foregroundColor(.white)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    
    private func startCustomWorkoutSession(_ workout: CustomWorkout) {
        // Load the custom workout into the current session
        dataManager.loadCustomWorkout(workout)
        
        // Clear existing set inputs
        exerciseSetInputs.removeAll()
        
        // Create set inputs for each exercise, pre-populating if sets exist
        for exerciseIndex in 0..<dataManager.currentFitnessSession.exerciseSessions.count {
            let exerciseSession = dataManager.currentFitnessSession.exerciseSessions[exerciseIndex]
            
            if exerciseSession.sets.isEmpty {
                // No pre-populated sets, create empty input
                exerciseSetInputs[exerciseIndex] = [SetInput()]
            } else {
                // Pre-populated sets exist, create inputs based on them
                var setInputs: [SetInput] = []
                for set in exerciseSession.sets {
                    let setInput = SetInput(
                        reps: set.reps?.description ?? "",
                        weight: set.weight?.description ?? "",
                        time: set.time?.description ?? "",
                        distance: set.distance?.description ?? ""
                    )
                    setInputs.append(setInput)
                }
                // Add one empty input for additional sets
                setInputs.append(SetInput())
                exerciseSetInputs[exerciseIndex] = setInputs
            }
        }
        
        // Mark workout template as loaded
        isWorkoutTemplateLoaded = true
        hasSessionBeenSaved = false
        
        // Start the session if not already active
        if !dataManager.currentFitnessSession.isActive {
            dataManager.startFitnessSession()
        }
    }
    
    // MARK: - Current Exercises Section
    
    private var currentExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.bullet.circle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                Text("Current Exercises")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(dataManager.currentFitnessSession.totalExercises)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.1))
                    )
            }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(dataManager.currentFitnessSession.exerciseSessions.enumerated()), id: \.element.id) { index, exerciseSession in
                    exerciseRow(exerciseSession: exerciseSession, index: index)
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
    
    private func exerciseRow(exerciseSession: ExerciseSession, index: Int) -> some View {
        VStack(spacing: 12) {
            // Exercise Header
            HStack {
                ZStack {
                    Circle()
                        .fill(colorForExerciseType(exerciseSession.exerciseType).opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: exerciseSession.exerciseType.icon)
                        .font(.title3)
                        .foregroundColor(colorForExerciseType(exerciseSession.exerciseType))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(exerciseSession.exerciseType.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        // Running clock for this exercise
                        if selectedExerciseIndices.contains(index) {
                            Text("Time: \(formatDuration(getExerciseRunningTime(exerciseIndex: index)))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(colorForExerciseType(exerciseSession.exerciseType))
                                .id("\(uiUpdateTrigger)-\(timerUpdate)") // Update with timer
                        }
                    }
                    
                    // Enhanced Exercise Summary
                    exerciseSummaryView(exerciseSession: exerciseSession, exerciseIndex: index)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Add Set Button
                    Button(action: {
                        if selectedExerciseIndices.contains(index) {
                            // If this exercise is already selected, close it
                            selectedExerciseIndices.remove(index)
                            stopExerciseTimer(exerciseIndex: index)
                        } else {
                            // If this exercise is not selected, open it
                            selectedExerciseIndices.insert(index)
                            startExerciseTimer(exerciseIndex: index)
                        }
                    }) {
                        Image(systemName: selectedExerciseIndices.contains(index) ? "minus.circle.fill" : "plus.circle.fill")
                            .foregroundColor(selectedExerciseIndices.contains(index) ? .orange : .blue)
                            .font(.title3)
                    }
                    
                    // Remove Exercise Button
                    Button(action: {
                        dataManager.removeExerciseSession(at: index)
                        // Clear set inputs for this exercise
                        exerciseSetInputs.removeValue(forKey: index)
                        // Remove from selected indices
                        selectedExerciseIndices.remove(index)
                        // Stop the exercise timer
                        stopExerciseTimer(exerciseIndex: index)
                        // Update indices for remaining exercises
                        updateExerciseIndices()
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red.opacity(0.7))
                            .font(.title3)
                    }
                }
            }
            
            // Inline Set Input (when selected)
            if selectedExerciseIndices.contains(index) {
                inlineSetInput(exerciseSession: exerciseSession, exerciseIndex: index)
            }
            
            // Existing Sets List
            if !exerciseSession.sets.isEmpty {
                VStack(spacing: 8) {
                    ForEach(Array(exerciseSession.sets.enumerated()), id: \.element.id) { setIndex, set in
                        HStack {
                            Text("Set \(setIndex + 1)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(set.displayString)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                dataManager.removeExerciseSet(from: index, at: setIndex)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red.opacity(0.7))
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Inline Set Input
    
    private func inlineSetInput(exerciseSession: ExerciseSession, exerciseIndex: Int) -> some View {
        VStack(spacing: 12) {
            // Exercise Name Header
            HStack {
                Text(exerciseSession.exerciseType.rawValue)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Set Input Boxes
            LazyVStack(spacing: 8) {
                ForEach(Array(getSetInputs(for: exerciseIndex).enumerated()), id: \.element.id) { setIndex, setInput in
                    setInputBox(exerciseType: exerciseSession.exerciseType, setIndex: setIndex, exerciseIndex: exerciseIndex, setInput: setInput)
                }
                
                // Add new set button
                Button(action: {
                    addNewSetInput(for: exerciseIndex)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.caption)
                        Text("Add Another Set")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorForExerciseType(exerciseSession.exerciseType).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(colorForExerciseType(exerciseSession.exerciseType).opacity(0.3), lineWidth: 1)
                            )
                    )
                    .foregroundColor(colorForExerciseType(exerciseSession.exerciseType))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colorForExerciseType(exerciseSession.exerciseType).opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func setInputBox(exerciseType: ExerciseType, setIndex: Int, exerciseIndex: Int, setInput: SetInput) -> some View {
        VStack(spacing: 16) {
            // Set Header
            HStack {
                Text("Set \(setIndex + 1)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Input Fields Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Reps Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reps")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack {
                        TextField("10", text: Binding(
                            get: { setInput.reps },
                            set: { updateSetInput(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: $0) }
                        ))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        )
                        
                        Text("reps")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 4)
                    }
                }
                
                // Weight Input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Weight")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack {
                        TextField("135", text: Binding(
                            get: { setInput.weight },
                            set: { updateSetInput(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: $0) }
                        ))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(.systemGray4), lineWidth: 1)
                                )
                        )
                        
                        Text("lbs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.trailing, 4)
                    }
                }
                
                // Time Input (if supported)
                if exerciseType.supportsTime {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Time")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack {
                            TextField("9:15", text: Binding(
                                get: { setInput.time },
                                set: { updateSetInput(exerciseIndex: exerciseIndex, setIndex: setIndex, time: $0) }
                            ))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numbersAndPunctuation)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            )
                            
                            Text("min:sec")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.trailing, 4)
                        }
                    }
                }
                
                // Distance Input (for cardio exercises)
                if exerciseType.category == .cardio {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Distance")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        HStack {
                            TextField("3.5", text: Binding(
                                get: { setInput.distance },
                                set: { updateSetInput(exerciseIndex: exerciseIndex, setIndex: setIndex, distance: $0) }
                            ))
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.decimalPad)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            )
                            
                            Text("mi")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.trailing, 4)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Set Input Management
    
    private func getSetInputs(for exerciseIndex: Int) -> [SetInput] {
        if exerciseSetInputs[exerciseIndex] == nil {
            exerciseSetInputs[exerciseIndex] = [SetInput()]
        }
        return exerciseSetInputs[exerciseIndex] ?? []
    }
    
    private func addNewSetInput(for exerciseIndex: Int) {
        if exerciseSetInputs[exerciseIndex] == nil {
            exerciseSetInputs[exerciseIndex] = [SetInput()]
        } else {
            exerciseSetInputs[exerciseIndex]?.append(SetInput())
        }
    }
    
    
    private func updateSetInput(exerciseIndex: Int, setIndex: Int, reps: String? = nil, weight: String? = nil, time: String? = nil, distance: String? = nil) {
        guard var inputs = exerciseSetInputs[exerciseIndex],
              setIndex < inputs.count else { return }
        
        if let reps = reps {
            inputs[setIndex].reps = reps
        }
        if let weight = weight {
            inputs[setIndex].weight = weight
        }
        if let time = time {
            inputs[setIndex].time = time
        }
        if let distance = distance {
            inputs[setIndex].distance = distance
        }
        
        exerciseSetInputs[exerciseIndex] = inputs
        
        // Trigger UI update to refresh exercise summaries
        uiUpdateTrigger += 1
    }
    
    private func parseTimeInput(_ timeString: String) -> TimeInterval? {
        // Handle minutes:seconds format (e.g., "9:15", "1:30")
        if timeString.contains(":") {
            let components = timeString.split(separator: ":")
            if components.count == 2,
               let minutes = Int(components[0]),
               let seconds = Int(components[1]) {
                return TimeInterval(minutes * 60 + seconds)
            }
        }
        
        // Handle plain seconds format (e.g., "60", "90")
        if let seconds = Int(timeString) {
            return TimeInterval(seconds)
        }
        
        // Handle decimal seconds format (e.g., "60.5")
        if let seconds = Double(timeString) {
            return TimeInterval(seconds)
        }
        
        return nil
    }
    
    private func addSetToExercise(exerciseIndex: Int, setInput: SetInput) {
        print("=== Adding Set to Exercise ===")
        print("Exercise Index: \(exerciseIndex)")
        print("Set Input: reps='\(setInput.reps)', weight='\(setInput.weight)', time='\(setInput.time)', distance='\(setInput.distance)'")
        print("Set Input Valid: \(setInput.isValid)")
        
        guard setInput.isValid else { 
            print("Set input is not valid, returning")
            return 
        }
        
        let repsInt = setInput.reps.isEmpty ? nil : Int(setInput.reps)
        let weightDouble = setInput.weight.isEmpty ? nil : Double(setInput.weight)
        let timeInterval = setInput.time.isEmpty ? nil : parseTimeInput(setInput.time)
        let distanceDouble = setInput.distance.isEmpty ? nil : Double(setInput.distance)
        
        let timestamp = useManualTime ? combineDateAndTime(manualDate, manualTime) : nil
        
        print("Parsed values: reps=\(repsInt ?? 0), weight=\(weightDouble ?? 0), time=\(timeInterval ?? 0), distance=\(distanceDouble ?? 0)")
        
        let set = ExerciseSet(
            reps: repsInt,
            weight: weightDouble,
            time: timeInterval,
            distance: distanceDouble,
            timestamp: timestamp
        )
        
        print("Created ExerciseSet: \(set)")
        print("ExerciseSet valid: \(set.isValid)")
        
        let success = dataManager.addExerciseSet(to: exerciseIndex, set: set)
        print("Add exercise set result: \(success)")
        
        // Clear the input after adding
        if let index = getSetInputs(for: exerciseIndex).firstIndex(where: { $0.id == setInput.id }) {
            exerciseSetInputs[exerciseIndex]?[index] = SetInput()
        }
        
        print("=== End Adding Set ===")
    }
    
    private func updateExerciseIndices() {
        // Rebuild the exerciseSetInputs dictionary with correct indices
        let newInputs: [Int: [SetInput]] = Dictionary(uniqueKeysWithValues: 
            exerciseSetInputs.compactMap { (key, value) in
                let newKey = key > 0 ? key - 1 : nil
                return newKey.map { ($0, value) }
            }
        )
        exerciseSetInputs = newInputs
    }
    
    private func combineDateAndTime(_ date: Date, _ time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        
        return calendar.date(from: combinedComponents) ?? Date()
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 20) {
            // Show Start Session button if there are exercises but no active session
            if !dataManager.currentFitnessSession.exerciseSessions.isEmpty && !dataManager.currentFitnessSession.isActive && !dataManager.currentFitnessSession.isPaused {
                Button(action: startFitnessSession) {
                    HStack(spacing: 10) {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                        Text("Start Session")
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
            
            if dataManager.currentFitnessSession.isActive {
                VStack(spacing: 12) {
                    // Primary action buttons row
                    HStack(spacing: 16) {
                        Button(action: pauseFitnessSession) {
                            HStack(spacing: 10) {
                                Image(systemName: "pause.circle.fill")
                                    .font(.title3)
                                Text("Pause")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.yellow, Color.yellow.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .yellow.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .foregroundColor(.white)
                        }
                        
                        Button(action: stopFitnessSession) {
                            HStack(spacing: 10) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title3)
                                Text("Stop")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.red, Color.red.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .foregroundColor(.white)
                        }
                    }
                    
                    // Secondary action buttons row
                    HStack(spacing: 16) {
                        Button(action: saveSessionWithoutClosing) {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.title3)
                                Text("Save Session")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: canSaveFitnessSession ? [Color.blue, Color.blue.opacity(0.8)] : [Color.gray, Color.gray.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: canSaveFitnessSession ? .blue.opacity(0.3) : .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(!canSaveFitnessSession)
                        
                        Button(action: {
                            showingCompleteConfirmation = true
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Complete")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: canSaveFitnessSession ? [Color.green, Color.green.opacity(0.8)] : [Color.gray, Color.gray.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: canSaveFitnessSession ? .green.opacity(0.3) : .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .foregroundColor(.white)
                        }
                        .disabled(!canSaveFitnessSession)
                    }
                }
            } else if dataManager.currentFitnessSession.isPaused {
                VStack(spacing: 12) {
                    // Primary action buttons row
                    HStack(spacing: 16) {
                        Button(action: resumeFitnessSession) {
                            HStack(spacing: 10) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                                Text("Resume")
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
                        
                        Button(action: stopFitnessSession) {
                            HStack(spacing: 10) {
                                Image(systemName: "stop.circle.fill")
                                    .font(.title3)
                                Text("Stop")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.red, Color.red.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .foregroundColor(.white)
                        }
                    }
                    
                    // Secondary action button
                    Button(action: {
                        showingCompleteConfirmation = true
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                            Text("Save & Complete")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: canSaveFitnessSession ? [Color.green, Color.green.opacity(0.8)] : [Color.gray, Color.gray.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: canSaveFitnessSession ? .green.opacity(0.3) : .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(!canSaveFitnessSession)
                }
            }
            
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSaveFitnessSession: Bool {
        return !dataManager.currentFitnessSession.exerciseSessions.isEmpty
    }
    
    
    private var totalSetsCount: Int {
        // Count saved sets from data manager
        let savedSets = dataManager.currentFitnessSession.totalSets
        
        // Count current set inputs that have valid data
        let currentSetInputs = exerciseSetInputs.values.flatMap { $0 }.filter { $0.isValid }.count
        
        return savedSets + currentSetInputs
    }
    
    private var totalRepsCount: Int {
        // Count reps from saved sets
        let savedReps = dataManager.currentFitnessSession.exerciseSessions.flatMap { $0.sets }.compactMap { $0.reps }.reduce(0, +)
        
        // Count reps from current set inputs that have valid data
        let currentReps = exerciseSetInputs.values.flatMap { $0 }.compactMap { Int($0.reps) }.reduce(0, +)
        
        return savedReps + currentReps
    }
    
    private var totalVolume: Double {
        // Calculate volume from saved sets
        let savedVolume = dataManager.currentFitnessSession.exerciseSessions.flatMap { $0.sets }.compactMap { set in
            guard let reps = set.reps, let weight = set.weight else { return nil }
            return Double(reps) * weight
        }.reduce(0.0) { $0 + $1 }
        
        // Calculate volume from current set inputs
        let currentVolume = exerciseSetInputs.values.flatMap { $0 }.compactMap { setInput in
            guard let reps = Int(setInput.reps), let weight = Double(setInput.weight) else { return nil }
            return Double(reps) * weight
        }.reduce(0.0) { $0 + $1 }
        
        return savedVolume + currentVolume
    }
    
    
    private var currentSessionCardioTime: TimeInterval {
        // Calculate total cardio time from current session's sets (saved + current inputs)
        let savedCardioTime = dataManager.currentFitnessSession.exerciseSessions.reduce(0) { total, exerciseSession in
            exerciseSession.sets.reduce(0) { exerciseTotal, set in
                exerciseTotal + (set.time ?? 0)
            }
        }
        
        let currentInputCardioTime = exerciseSetInputs.values.flatMap { $0 }.reduce(0) { total, setInput in
            let timeInSeconds = setInput.time.isEmpty ? 0 : parseTimeInput(setInput.time) ?? 0
            return total + timeInSeconds
        }
        
        return savedCardioTime + currentInputCardioTime
    }
    
    // MARK: - Actions
    
    
    private func startFitnessSession() {
        dataManager.startFitnessSession()
        hasSessionBeenSaved = false
    }
    
    private func pauseFitnessSession() {
        dataManager.pauseFitnessSession()
    }
    
    private func resumeFitnessSession() {
        dataManager.resumeFitnessSession()
    }
    
    private func stopFitnessSession() {
        dataManager.stopFitnessSession()
    }
    
    private func saveFitnessSession() {
        // Only collect sets if the session hasn't been saved yet
        if !hasSessionBeenSaved {
            // Collect any sets that were entered in the UI and add them to the current session
            for (exerciseIndex, exerciseSession) in dataManager.currentFitnessSession.exerciseSessions.enumerated() {
                if let setInputs = exerciseSetInputs[exerciseIndex] {
                    var sets: [ExerciseSet] = []
                    for setInput in setInputs {
                        if setInput.isValid {
                            let repsInt = setInput.reps.isEmpty ? nil : Int(setInput.reps)
                            let weightDouble = setInput.weight.isEmpty ? nil : Double(setInput.weight)
                            let timeInterval = setInput.time.isEmpty ? nil : parseTimeInput(setInput.time)
                            let distanceDouble = setInput.distance.isEmpty ? nil : Double(setInput.distance)
                            
                            let set = ExerciseSet(
                                reps: repsInt,
                                weight: weightDouble,
                                time: timeInterval,
                                distance: distanceDouble,
                                timestamp: Date()
                            )
                            sets.append(set)
                        }
                    }
                    
                    if !sets.isEmpty {
                        dataManager.addSetsToCurrentSession(exerciseIndex: exerciseIndex, sets: sets)
                    }
                }
            }
        }
        
        dataManager.saveCurrentFitnessSession()
        hasSessionBeenSaved = true
    }
    
    private func saveSessionWithoutClosing() {
        // Only collect sets if the session hasn't been saved yet
        if !hasSessionBeenSaved {
            // Collect any sets that were entered in the UI and add them to the current session
            for (exerciseIndex, exerciseSession) in dataManager.currentFitnessSession.exerciseSessions.enumerated() {
                if let setInputs = exerciseSetInputs[exerciseIndex] {
                    var sets: [ExerciseSet] = []
                    for setInput in setInputs {
                        if setInput.isValid {
                            let repsInt = setInput.reps.isEmpty ? nil : Int(setInput.reps)
                            let weightDouble = setInput.weight.isEmpty ? nil : Double(setInput.weight)
                            let timeInterval = setInput.time.isEmpty ? nil : parseTimeInput(setInput.time)
                            let distanceDouble = setInput.distance.isEmpty ? nil : Double(setInput.distance)
                            
                            let set = ExerciseSet(
                                reps: repsInt,
                                weight: weightDouble,
                                time: timeInterval,
                                distance: distanceDouble,
                                timestamp: Date()
                            )
                            sets.append(set)
                        }
                    }
                    
                    if !sets.isEmpty {
                        dataManager.addSetsToCurrentSession(exerciseIndex: exerciseIndex, sets: sets)
                    }
                }
            }
        }
        
        // Save the session data to Firestore without closing the session
        dataManager.saveCurrentSessionToFirestore()
        hasSessionBeenSaved = true
    }
    
    
    
    // MARK: - Exercise Summary View
    
    private func exerciseSummaryView(exerciseSession: ExerciseSession, exerciseIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Show summary in small text format (always show, even if no sets)
            Text(createSummaryText(exerciseSession: exerciseSession, exerciseIndex: exerciseIndex))
                .font(.caption)
                .foregroundColor(.secondary)
                .id("\(uiUpdateTrigger)-\(timerUpdate)") // This will cause the view to refresh when inputs or timer changes
        }
    }
    
    private func createSummaryText(exerciseSession: ExerciseSession, exerciseIndex: Int) -> String {
        var components: [String] = []
        
        // Calculate totals from both completed sets and current inputs
        let completedSets = exerciseSession.sets
        let currentInputs = getSetInputs(for: exerciseIndex)
        
        // Count total sets (completed + current inputs with data)
        let completedSetsCount = completedSets.count
        let currentInputsWithData = currentInputs.filter { $0.isValid }.count
        let totalSets = completedSetsCount + currentInputsWithData
        
        if totalSets > 0 {
            components.append("\(totalSets) sets")
        }
        
        // Calculate total reps (completed + current inputs)
        let completedReps = completedSets.compactMap { $0.reps }.reduce(0) { $0 + $1 }
        let currentReps = currentInputs.compactMap { input in
            guard input.isValid, let reps = Int(input.reps) else { return nil }
            return reps
        }.reduce(0) { $0 + $1 }
        let totalReps = completedReps + currentReps
        
        if totalReps > 0 {
            components.append("\(totalReps) reps")
        }
        
        // Calculate total volume (completed + current inputs)
        let completedVolume = completedSets.compactMap { set in
            guard let reps = set.reps, let weight = set.weight else { return nil }
            return Double(reps) * weight
        }.reduce(0.0) { $0 + $1 }
        
        let currentVolume = currentInputs.compactMap { input in
            guard input.isValid, 
                  let reps = Int(input.reps), 
                  let weight = Double(input.weight) else { return nil }
            return Double(reps) * weight
        }.reduce(0.0) { $0 + $1 }
        
        let totalVolume = completedVolume + currentVolume
        if totalVolume > 0 {
            components.append("\(Int(totalVolume)) lbs volume")
        }
        
        // Calculate total time (completed + current inputs)
        let completedTime = completedSets.compactMap { $0.time }.reduce(0.0) { $0 + $1 }
        let currentTime = currentInputs.compactMap { input in
            guard input.isValid, let time = parseTimeInput(input.time) else { return nil }
            return time
        }.reduce(0.0) { $0 + $1 }
        
        let totalTime = completedTime + currentTime
        
        if totalTime > 0 {
            let minutes = Int(totalTime) / 60
            let seconds = Int(totalTime) % 60
            if minutes > 0 {
                components.append("\(minutes):\(String(format: "%02d", seconds)) time")
            } else {
                components.append("\(seconds)s time")
            }
        }
        
        return components.isEmpty ? "No sets completed" : components.joined(separator: " • ")
    }
    
    // MARK: - Helper Functions
    
    private func colorForExerciseType(_ type: ExerciseType) -> Color {
        switch type.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        default: return .gray
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func getExerciseRunningTime(exerciseIndex: Int) -> TimeInterval {
        guard let startTime = exerciseStartTimes[exerciseIndex] else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    private func startExerciseTimer(exerciseIndex: Int) {
        exerciseStartTimes[exerciseIndex] = Date()
    }
    
    private func stopExerciseTimer(exerciseIndex: Int) {
        exerciseStartTimes.removeValue(forKey: exerciseIndex)
    }
    
    private func startTimer() {
        guard dataManager.currentFitnessSession.isActive && !dataManager.currentFitnessSession.isPaused else { return }
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Force UI update by incrementing timer update counter
            timerUpdate += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}


// MARK: - Exercise Selector View

struct ExerciseSelectorView: View {
    @Binding var selectedExercise: ExerciseType
    let onExerciseSelected: (ExerciseType) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(ExerciseType.allCases, id: \.self) { exerciseType in
                    Button(action: {
                        selectedExercise = exerciseType
                        onExerciseSelected(exerciseType)
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(colorForExerciseType(exerciseType).opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: exerciseType.icon)
                                    .font(.title3)
                                    .foregroundColor(colorForExerciseType(exerciseType))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(exerciseType.rawValue)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Text(exerciseType.unit)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func colorForExerciseType(_ type: ExerciseType) -> Color {
        switch type.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        default: return .gray
        }
    }
}


// MARK: - Set Input Model

struct SetInput: Identifiable {
    let id = UUID()
    var reps: String = ""
    var weight: String = ""
    var time: String = ""
    var distance: String = ""
    
    var isValid: Bool {
        return !reps.isEmpty || !weight.isEmpty || !time.isEmpty || !distance.isEmpty
    }
}

// MARK: - Custom Workout Selector

struct CustomWorkoutSelector: View {
    @Binding var selectedWorkout: CustomWorkout?
    let onWorkoutSelected: (CustomWorkout) -> Void
    @EnvironmentObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dataManager.customWorkouts, id: \.id) { workout in
                    Button(action: {
                        onWorkoutSelected(workout)
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "bookmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.purple)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(workout.displayName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                if let description = workout.description, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                                
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "dumbbell")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Text("\(workout.totalExercises) exercises")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "repeat")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                        Text("\(workout.totalSets) sets")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Image(systemName: "clock")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        Text("\(workout.estimatedDuration) min")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Custom Workouts")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Rep Max Estimation Card

struct RepMaxEstimationCard: View {
    let record: OneRepMax
    let isExpanded: Bool
    let onTap: () -> Void
    
    private var repEstimations: [(reps: Int, weight: Double)] {
        let oneRepMax = record.value
        return [
            (2, OneRepMaxCalculator.calculateWeightForReps(oneRepMax: oneRepMax, targetReps: 2)),
            (3, OneRepMaxCalculator.calculateWeightForReps(oneRepMax: oneRepMax, targetReps: 3)),
            (5, OneRepMaxCalculator.calculateWeightForReps(oneRepMax: oneRepMax, targetReps: 5)),
            (10, OneRepMaxCalculator.calculateWeightForReps(oneRepMax: oneRepMax, targetReps: 10))
        ]
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Exercise Name and 1RM Value
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(record.liftName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text("1RM: \(String(format: "%.0f", record.value)) lbs")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    // Expand/Collapse Icon
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Rep Estimations (only show when expanded)
                if isExpanded {
                    VStack(alignment: .leading, spacing: 4) {
                        Divider()
                            .padding(.vertical, 4)
                        
                        ForEach(repEstimations, id: \.reps) { estimation in
                            HStack {
                                Text("\(estimation.reps)RM:")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .frame(width: 25, alignment: .leading)
                                
                                Text("\(String(format: "%.0f", estimation.weight)) lbs")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isExpanded ? Color(.systemBlue).opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isExpanded ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct FitnessView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessView(dataManager: BPDataManager())
    }
}