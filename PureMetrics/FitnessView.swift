import SwiftUI

struct FitnessView: View {
    @ObservedObject var dataManager: BPDataManager
    @StateObject private var workoutManager = PreBuiltWorkoutManager()
    @State private var selectedExerciseType: ExerciseType? = .benchPress
    @State private var showingExerciseSelector = false
    @State private var showingCategorySelector = false
    @State private var showingWorkoutSelector = false
    @State private var selectedCategory: ExerciseCategory?
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
                        VStack(spacing: 24) {
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
                startTimer()
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
        .sheet(isPresented: $showingCategorySelector) {
            ExerciseCategorySelector(selectedCategory: $selectedCategory) { category in
                selectedCategory = category
                showingCategorySelector = false
                showingExerciseSelector = true
            }
        }
        .sheet(isPresented: $showingExerciseSelector) {
            if let category = selectedCategory {
                ExerciseSelector(
                    category: category,
                    selectedExercise: $selectedExerciseType
                ) { exerciseType in
                    _ = dataManager.addExerciseSession(exerciseType)
                    // Initialize set inputs for the new exercise
                    let newExerciseIndex = dataManager.currentFitnessSession.exerciseSessions.count - 1
                    exerciseSetInputs[newExerciseIndex] = [SetInput()]
                    showingExerciseSelector = false
                }
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
                showingWorkoutSelector = false
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
            // Top gradient header
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.9),
                    Color.orange.opacity(0.7),
                    Color.red.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 100)
            .overlay(
                VStack(spacing: 0) {
                    // Top section with app name, status, and New Session button
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PureMetrics")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
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
                            
                            // New Session Button
                            Button(action: startNewFitnessSession) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.subheadline)
                                    Text("New")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 18)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.green, Color.green.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: .green.opacity(0.3), radius: 6, x: 0, y: 3)
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
    
    // MARK: - Session Info Section
    
    private var sessionInfoSection: some View {
        HStack(spacing: 40) {
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
                    showingCategorySelector = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
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
            }
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Current Exercises Section
    
    private var currentExercisesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
        VStack(spacing: 16) {
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
                    Text(exerciseSession.exerciseType.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(exerciseSession.displayString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Add Set Button
                    Button(action: {
                        if selectedExerciseIndices.contains(index) {
                            // If this exercise is already selected, close it
                            selectedExerciseIndices.remove(index)
                        } else {
                            // If this exercise is not selected, open it
                            selectedExerciseIndices.insert(index)
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
        VStack(spacing: 16) {
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
                
                // Add new set box
                Button(action: {
                    addNewSetInput(for: exerciseIndex)
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(colorForExerciseType(exerciseSession.exerciseType))
                        Text("Add Set")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(colorForExerciseType(exerciseSession.exerciseType))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorForExerciseType(exerciseSession.exerciseType).opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(colorForExerciseType(exerciseSession.exerciseType).opacity(0.3), lineWidth: 1)
                            )
                    )
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
        HStack(spacing: 12) {
            // Set Number
            ZStack {
                Circle()
                    .fill(colorForExerciseType(exerciseType).opacity(0.1))
                    .frame(width: 28, height: 28)
                
                Text("\(setIndex + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(colorForExerciseType(exerciseType))
            }
            
            // Reps Input
            VStack(alignment: .leading, spacing: 4) {
                Text("Reps")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                TextField("10", text: Binding(
                    get: { setInput.reps },
                    set: { updateSetInput(exerciseIndex: exerciseIndex, setIndex: setIndex, reps: $0) }
                ))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorForExerciseType(exerciseType).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colorForExerciseType(exerciseType).opacity(0.2), lineWidth: 1)
                        )
                )
            }
            
            // "x" separator
            Text("x")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .padding(.top, 20)
            
            // Weight Input
            VStack(alignment: .leading, spacing: 4) {
                Text("Weight")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                
                HStack(spacing: 2) {
                    TextField("135", text: Binding(
                        get: { setInput.weight },
                        set: { updateSetInput(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: $0) }
                    ))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorForExerciseType(exerciseType).opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(colorForExerciseType(exerciseType).opacity(0.2), lineWidth: 1)
                            )
                    )
                    
                    Text("lbs")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Time Input
            if exerciseType.supportsTime {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    
                    HStack(spacing: 2) {
                        TextField("60", text: Binding(
                            get: { setInput.time },
                            set: { updateSetInput(exerciseIndex: exerciseIndex, setIndex: setIndex, time: $0) }
                        ))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(colorForExerciseType(exerciseType).opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(colorForExerciseType(exerciseType).opacity(0.2), lineWidth: 1)
                                )
                        )
                        
                        Text("sec")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Add Set Button
            Button(action: {
                print("=== ADD SET BUTTON TAPPED ===")
                print("Exercise Index: \(exerciseIndex)")
                print("Set Input: \(setInput)")
                print("Set Input Valid: \(setInput.isValid)")
                addSetToExercise(exerciseIndex: exerciseIndex, setInput: setInput)
            }) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(setInput.isValid ? colorForExerciseType(exerciseType) : .gray)
                    .font(.title3)
            }
            .disabled(!setInput.isValid)
        }
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
    
    private func updateSetInput(exerciseIndex: Int, setIndex: Int, reps: String? = nil, weight: String? = nil, time: String? = nil) {
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
        
        exerciseSetInputs[exerciseIndex] = inputs
    }
    
    private func addSetToExercise(exerciseIndex: Int, setInput: SetInput) {
        print("=== Adding Set to Exercise ===")
        print("Exercise Index: \(exerciseIndex)")
        print("Set Input: reps='\(setInput.reps)', weight='\(setInput.weight)', time='\(setInput.time)'")
        print("Set Input Valid: \(setInput.isValid)")
        
        guard setInput.isValid else { 
            print("Set input is not valid, returning")
            return 
        }
        
        let repsInt = setInput.reps.isEmpty ? nil : Int(setInput.reps)
        let weightDouble = setInput.weight.isEmpty ? nil : Double(setInput.weight)
        let timeInterval = setInput.time.isEmpty ? nil : TimeInterval(setInput.time)
        
        let timestamp = useManualTime ? combineDateAndTime(manualDate, manualTime) : nil
        
        print("Parsed values: reps=\(repsInt ?? 0), weight=\(weightDouble ?? 0), time=\(timeInterval ?? 0)")
        
        let set = ExerciseSet(
            reps: repsInt,
            weight: weightDouble,
            time: timeInterval,
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
                VStack(spacing: 16) {
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
                VStack(spacing: 16) {
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
            
            if !dataManager.currentFitnessSession.exerciseSessions.isEmpty {
                Button(action: clearFitnessSession) {
                    HStack(spacing: 10) {
                        Image(systemName: "trash.circle.fill")
                            .font(.title3)
                        Text("Clear Session")
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
            let timeInSeconds = setInput.time.isEmpty ? 0 : TimeInterval(setInput.time) ?? 0
            return total + timeInSeconds
        }
        
        return savedCardioTime + currentInputCardioTime
    }
    
    // MARK: - Actions
    
    private func startNewFitnessSession() {
        if dataManager.currentFitnessSession.isActive {
            if !dataManager.currentFitnessSession.exerciseSessions.isEmpty {
                dataManager.saveCurrentFitnessSession()
            } else {
                dataManager.clearCurrentFitnessSession()
            }
        }
        // Don't auto-start the session - let user add exercises first
        isWorkoutTemplateLoaded = false
        exerciseSetInputs.removeAll()
    }
    
    private func startFitnessSession() {
        dataManager.startFitnessSession()
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
        // Collect any sets that were entered in the UI and add them to the current session
        for (exerciseIndex, exerciseSession) in dataManager.currentFitnessSession.exerciseSessions.enumerated() {
            if let setInputs = exerciseSetInputs[exerciseIndex] {
                var sets: [ExerciseSet] = []
                for setInput in setInputs {
                    if setInput.isValid {
                        let repsInt = setInput.reps.isEmpty ? nil : Int(setInput.reps)
                        let weightDouble = setInput.weight.isEmpty ? nil : Double(setInput.weight)
                        let timeInterval = setInput.time.isEmpty ? nil : TimeInterval(setInput.time)
                        
                        let set = ExerciseSet(
                            reps: repsInt,
                            weight: weightDouble,
                            time: timeInterval,
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
        
        dataManager.saveCurrentFitnessSession()
    }
    
    private func saveSessionWithoutClosing() {
        // Collect any sets that were entered in the UI and add them to the current session
        for (exerciseIndex, exerciseSession) in dataManager.currentFitnessSession.exerciseSessions.enumerated() {
            if let setInputs = exerciseSetInputs[exerciseIndex] {
                var sets: [ExerciseSet] = []
                for setInput in setInputs {
                    if setInput.isValid {
                        let repsInt = setInput.reps.isEmpty ? nil : Int(setInput.reps)
                        let weightDouble = setInput.weight.isEmpty ? nil : Double(setInput.weight)
                        let timeInterval = setInput.time.isEmpty ? nil : TimeInterval(setInput.time)
                        
                        let set = ExerciseSet(
                            reps: repsInt,
                            weight: weightDouble,
                            time: timeInterval,
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
        
        // Save the session data to Firestore without closing the session
        dataManager.saveCurrentSessionToFirestore()
    }
    
    private func clearFitnessSession() {
        dataManager.clearCurrentFitnessSession()
        isWorkoutTemplateLoaded = false
        exerciseSetInputs.removeAll()
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
    
    var isValid: Bool {
        return !reps.isEmpty || !weight.isEmpty || !time.isEmpty
    }
}

// MARK: - Preview

struct FitnessView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessView(dataManager: BPDataManager())
    }
}