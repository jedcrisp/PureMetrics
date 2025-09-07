import SwiftUI

struct FitnessView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var selectedExerciseType: ExerciseType = .benchPress
    @State private var showingExerciseSelector = false
    @State private var showingSetInput = false
    @State private var selectedExerciseIndex: Int?
    @State private var reps = ""
    @State private var weight = ""
    @State private var time = ""
    @State private var useManualTime = false
    @State private var manualDate = Date()
    @State private var manualTime = Date()
    
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
        }
        .sheet(isPresented: $showingExerciseSelector) {
            ExerciseSelectorView(selectedExercise: $selectedExerciseType) { exerciseType in
                dataManager.addExerciseSession(exerciseType)
                showingExerciseSelector = false
            }
        }
        .sheet(isPresented: $showingSetInput) {
            if let exerciseIndex = selectedExerciseIndex {
                SetInputView(
                    exerciseType: dataManager.currentFitnessSession.exerciseSessions[exerciseIndex].exerciseType,
                    reps: $reps,
                    weight: $weight,
                    time: $time,
                    useManualTime: $useManualTime,
                    manualDate: $manualDate,
                    manualTime: $manualTime
                ) { set in
                    dataManager.addExerciseSet(to: exerciseIndex, set: set)
                    clearSetInputs()
                    showingSetInput = false
                }
            }
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
                            if dataManager.currentFitnessSession.isActive {
                                VStack(alignment: .trailing, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 8, height: 8)
                                        Text("Active")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(formatDuration(dataManager.currentFitnessSession.duration))
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
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
        HStack(spacing: 20) {
            // Exercises Count
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text("\(dataManager.currentFitnessSession.totalExercises)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                
                VStack(spacing: 2) {
                    Text("Exercises")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("Added")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Sets Count
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text("\(dataManager.currentFitnessSession.totalSets)")
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
            
            Spacer()
            
            // Session Status
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(dataManager.currentFitnessSession.isActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: dataManager.currentFitnessSession.isActive ? "play.circle.fill" : "pause.circle.fill")
                        .font(.title3)
                        .foregroundColor(dataManager.currentFitnessSession.isActive ? .green : .gray)
                }
                
                VStack(spacing: 2) {
                    Text("Status")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(dataManager.currentFitnessSession.isActive ? "Active" : "Ready")
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
            }
            
            Button(action: {
                showingExerciseSelector = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add Exercise")
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
                        selectedExerciseIndex = index
                        showingSetInput = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                    
                    // Remove Exercise Button
                    Button(action: {
                        dataManager.removeExerciseSession(at: index)
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red.opacity(0.7))
                            .font(.title3)
                    }
                }
            }
            
            // Sets List
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
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if dataManager.currentFitnessSession.isActive {
                HStack(spacing: 12) {
                    Button(action: stopFitnessSession) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop Session")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red)
                        )
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                    
                    Button(action: saveFitnessSession) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save & Complete")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canSaveFitnessSession ? Color.orange : Color.gray)
                        )
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                    .disabled(!canSaveFitnessSession)
                }
            }
            
            if !dataManager.currentFitnessSession.exerciseSessions.isEmpty {
                Button(action: clearFitnessSession) {
                    HStack(spacing: 12) {
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
                            .fill(Color.red)
                    )
                    .foregroundColor(.white)
                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSaveFitnessSession: Bool {
        return !dataManager.currentFitnessSession.exerciseSessions.isEmpty
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
        dataManager.startFitnessSession()
    }
    
    private func stopFitnessSession() {
        dataManager.stopFitnessSession()
    }
    
    private func saveFitnessSession() {
        dataManager.saveCurrentFitnessSession()
    }
    
    private func clearFitnessSession() {
        dataManager.clearCurrentFitnessSession()
    }
    
    private func clearSetInputs() {
        reps = ""
        weight = ""
        time = ""
        useManualTime = false
        manualDate = Date()
        manualTime = Date()
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

// MARK: - Set Input View

struct SetInputView: View {
    let exerciseType: ExerciseType
    @Binding var reps: String
    @Binding var weight: String
    @Binding var time: String
    @Binding var useManualTime: Bool
    @Binding var manualDate: Date
    @Binding var manualTime: Date
    let onSetAdded: (ExerciseSet) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Exercise Header
                HStack {
                    ZStack {
                        Circle()
                            .fill(colorForExerciseType(exerciseType).opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: exerciseType.icon)
                            .font(.title2)
                            .foregroundColor(colorForExerciseType(exerciseType))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exerciseType.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Add Set")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Input Fields
                VStack(spacing: 20) {
                    if exerciseType.supportsReps {
                        inputField(title: "Reps", value: $reps, placeholder: "10", unit: "reps")
                    }
                    
                    if exerciseType.supportsWeight {
                        inputField(title: "Weight", value: $weight, placeholder: "135", unit: "lbs")
                    }
                    
                    if exerciseType.supportsTime {
                        inputField(title: "Time", value: $time, placeholder: "60", unit: "seconds")
                    }
                }
                .padding(.horizontal, 20)
                
                // Manual Time Toggle
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("Use Manual Date/Time", isOn: $useManualTime)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if useManualTime {
                        VStack(spacing: 12) {
                            DatePicker("Date", selection: $manualDate, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                            
                            DatePicker("Time", selection: $manualTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(CompactDatePickerStyle())
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Add Set Button
                Button(action: addSet) {
                    HStack(spacing: 12) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add Set")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(canAddSet ? colorForExerciseType(exerciseType) : Color.gray)
                    )
                    .foregroundColor(.white)
                    .shadow(color: canAddSet ? colorForExerciseType(exerciseType).opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
                }
                .disabled(!canAddSet)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    private func inputField(title: String, value: Binding<String>, placeholder: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForExerciseType(exerciseType))
                
                Spacer()
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextField(placeholder, text: value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorForExerciseType(exerciseType).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colorForExerciseType(exerciseType).opacity(0.2), lineWidth: 1.5)
                        )
                )
        }
    }
    
    private var canAddSet: Bool {
        let hasReps = !exerciseType.supportsReps || !reps.isEmpty
        let hasWeight = !exerciseType.supportsWeight || !weight.isEmpty
        let hasTime = !exerciseType.supportsTime || !time.isEmpty
        
        return hasReps && hasWeight && hasTime
    }
    
    private func addSet() {
        let repsInt = exerciseType.supportsReps ? Int(reps) : nil
        let weightDouble = exerciseType.supportsWeight ? Double(weight) : nil
        let timeInterval = exerciseType.supportsTime ? TimeInterval(time) : nil
        
        let timestamp = useManualTime ? combineDateAndTime(manualDate, manualTime) : nil
        
        let set = ExerciseSet(
            reps: repsInt,
            weight: weightDouble,
            time: timeInterval,
            timestamp: timestamp
        )
        
        onSetAdded(set)
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
    
    private func colorForExerciseType(_ type: ExerciseType) -> Color {
        switch type.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        default: return .gray
        }
    }
}

// MARK: - Preview

struct FitnessView_Previews: PreviewProvider {
    static var previews: some View {
        FitnessView(dataManager: BPDataManager())
    }
}