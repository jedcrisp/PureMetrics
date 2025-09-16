import SwiftUI

struct DailyGoalsView: View {
    @ObservedObject var dailyGoalsManager: DailyGoalsManager
    let dataManager: BPDataManager
    @State private var showingNutritionGoals = false
    @State private var showingFitnessGoals = false
    @State private var showingGoalHistory = false
    @State private var isCompleted = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection
                    
                    // Goals Overview
                    if let currentGoals = dailyGoalsManager.currentDailyGoals {
                        goalsOverviewSection(currentGoals)
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        // Progress Summary
                        progressSummarySection(currentGoals)
                    } else {
                        noGoalsSection
                    }
                    
                    // Historical Goals
                    if !dailyGoalsManager.historicalGoals.isEmpty {
                        historicalGoalsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Daily Goals")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("History") {
                        showingGoalHistory = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingNutritionGoals) {
            if let currentGoals = dailyGoalsManager.currentDailyGoals {
                NutritionGoalsEditView(
                    goals: currentGoals.nutritionGoals,
                    onSave: { newGoals in
                        dailyGoalsManager.updateNutritionGoals(newGoals)
                        showingNutritionGoals = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingFitnessGoals) {
            if let currentGoals = dailyGoalsManager.currentDailyGoals {
                FitnessGoalsEditView(
                    goals: currentGoals.fitnessGoals,
                    onSave: { newGoals in
                        dailyGoalsManager.updateFitnessGoals(newGoals)
                        showingFitnessGoals = false
                    }
                )
            }
        }
        .sheet(isPresented: $showingGoalHistory) {
            GoalHistoryView(dailyGoalsManager: dailyGoalsManager)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Today's Goals")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                if let currentGoals = dailyGoalsManager.currentDailyGoals {
                    if currentGoals.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.gray)
                            .font(.title2)
                    }
                }
            }
            
            if let currentGoals = dailyGoalsManager.currentDailyGoals {
                Text(currentGoals.date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Goals Overview Section
    
    private func goalsOverviewSection(_ goals: DailyGoals) -> some View {
        VStack(spacing: 16) {
            // Nutrition Goals Card
            GoalsCard(
                title: "Nutrition Goals",
                icon: "fork.knife",
                color: .orange,
                goals: [
                    ("Calories", "\(Int(goals.nutritionGoals.dailyCalories)) cal"),
                    ("Protein", "\(Int(goals.nutritionGoals.dailyProtein))g"),
                    ("Water", "\(Int(goals.nutritionGoals.dailyWater)) oz")
                ]
            ) {
                showingNutritionGoals = true
            }
            
            // Fitness Goals Card
            GoalsCard(
                title: "Fitness Goals",
                icon: "figure.strengthtraining.traditional",
                color: .blue,
                goals: [
                    ("Workout", "\(goals.fitnessGoals.dailyWorkoutMinutes) min"),
                    ("Steps", "\(goals.fitnessGoals.dailySteps) steps"),
                    ("Sleep", "\(Int(goals.fitnessGoals.dailySleepHours)) hrs")
                ]
            ) {
                showingFitnessGoals = true
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button(action: {
                    showingNutritionGoals = true
                }) {
                    HStack {
                        Image(systemName: "fork.knife")
                        Text("Edit Nutrition")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    showingFitnessGoals = true
                }) {
                    HStack {
                        Image(systemName: "figure.strengthtraining.traditional")
                        Text("Edit Fitness")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            
            if let currentGoals = dailyGoalsManager.currentDailyGoals, !currentGoals.isCompleted {
                Button(action: {
                    dailyGoalsManager.markGoalsCompleted()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Mark as Completed")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Progress Summary Section
    
    private func progressSummarySection(_ goals: DailyGoals) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Progress Summary")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ProgressRow(
                    label: "Nutrition Goals",
                    progress: calculateNutritionProgress(goals),
                    color: .orange
                )
                
                ProgressRow(
                    label: "Fitness Goals",
                    progress: calculateFitnessProgress(goals),
                    color: .blue
                )
                
                ProgressRow(
                    label: "Overall Completion",
                    progress: calculateOverallProgress(goals),
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - No Goals Section
    
    private var noGoalsSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "target")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Goals Set")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Set your daily nutrition and fitness goals to start tracking your progress")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Set Goals") {
                // This will create new goals and show the edit views
                if dailyGoalsManager.currentDailyGoals == nil {
                    dailyGoalsManager.loadCurrentGoals()
                }
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
    
    // MARK: - Historical Goals Section
    
    private var historicalGoalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Goals")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 8) {
                ForEach(dailyGoalsManager.historicalGoals.prefix(5)) { goal in
                    HistoricalGoalRow(goal: goal)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Progress Calculations
    
    private func calculateNutritionProgress(_ goals: DailyGoals) -> Double {
        // Get today's nutrition entries
        let today = Calendar.current.startOfDay(for: Date())
        let todayEntries = dataManager.nutritionEntries.filter { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: today)
        }
        
        // Create nutrition summary
        let nutritionSummary = NutritionSummary(entries: todayEntries, goals: goals.nutritionGoals)
        
        // Calculate average progress across key metrics
        let caloriesProgress = nutritionSummary.caloriesProgress
        let proteinProgress = nutritionSummary.proteinProgress
        let waterProgress = nutritionSummary.waterProgress
        
        return (caloriesProgress + proteinProgress + waterProgress) / 3.0
    }
    
    private func calculateFitnessProgress(_ goals: DailyGoals) -> Double {
        // Get today's fitness sessions
        let today = Calendar.current.startOfDay(for: Date())
        let todaySessions = dataManager.fitnessSessions.filter { session in
            Calendar.current.isDate(session.startTime, inSameDayAs: today)
        }
        
        // Calculate total workout time
        let totalWorkoutTime = todaySessions.reduce(0) { total, session in
            let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
            return total + duration
        }
        
        // Convert to minutes
        let workoutMinutes = totalWorkoutTime / 60
        
        // Calculate progress based on daily workout goal
        let goalMinutes = goals.fitnessGoals.dailyWorkoutMinutes
        guard goalMinutes > 0 else { return 0 }
        
        return min(workoutMinutes / Double(goalMinutes), 1.0)
    }
    
    private func calculateOverallProgress(_ goals: DailyGoals) -> Double {
        let nutritionProgress = calculateNutritionProgress(goals)
        let fitnessProgress = calculateFitnessProgress(goals)
        
        return (nutritionProgress + fitnessProgress) / 2.0
    }
}

// MARK: - Goals Card

struct GoalsCard: View {
    let title: String
    let icon: String
    let color: Color
    let goals: [(String, String)]
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Edit") {
                    action()
                }
                .font(.caption)
                .foregroundColor(color)
            }
            
            VStack(spacing: 6) {
                ForEach(goals, id: \.0) { goal in
                    HStack {
                        Text(goal.0)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(goal.1)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Progress Row

struct ProgressRow: View {
    let label: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(color)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
        }
    }
}

// MARK: - Historical Goal Row

struct HistoricalGoalRow: View {
    let goal: DailyGoals
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(goal.date, style: .date)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Nutrition & Fitness Goals")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if goal.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Nutrition Goals Edit View

struct NutritionGoalsEditView: View {
    @State var goals: NutritionGoals
    let onSave: (NutritionGoals) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("Daily Nutrition Goals") {
                    HStack {
                        Text("Calories")
                        Spacer()
                        TextField("Calories", value: $goals.dailyCalories, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Protein (g)")
                        Spacer()
                        TextField("Protein", value: $goals.dailyProtein, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Water (oz)")
                        Spacer()
                        TextField("Water", value: $goals.dailyWater, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle("Edit Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(goals)
                    }
                }
            }
        }
    }
}

// MARK: - Fitness Goals Edit View

struct FitnessGoalsEditView: View {
    @State var goals: FitnessGoals
    let onSave: (FitnessGoals) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section("Daily Fitness Goals") {
                    HStack {
                        Text("Workout (min)")
                        Spacer()
                        TextField("Minutes", value: $goals.dailyWorkoutMinutes, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Steps")
                        Spacer()
                        TextField("Steps", value: $goals.dailySteps, format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                    
                    HStack {
                        Text("Sleep (hrs)")
                        Spacer()
                        TextField("Hours", value: $goals.dailySleepHours, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 100)
                    }
                }
            }
            .navigationTitle("Edit Fitness Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(goals)
                    }
                }
            }
        }
    }
}

// MARK: - Goal History View

struct GoalHistoryView: View {
    @ObservedObject var dailyGoalsManager: DailyGoalsManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(dailyGoalsManager.historicalGoals) { goal in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(goal.date, style: .date)
                                .font(.headline)
                            
                            Spacer()
                            
                            if goal.isCompleted {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Calories: \(Int(goal.nutritionGoals.dailyCalories))")
                                Text("Protein: \(Int(goal.nutritionGoals.dailyProtein))g")
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Workout: \(goal.fitnessGoals.dailyWorkoutMinutes)min")
                                Text("Steps: \(goal.fitnessGoals.dailySteps)")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Goal History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DailyGoalsView(dailyGoalsManager: DailyGoalsManager(), dataManager: BPDataManager())
}
