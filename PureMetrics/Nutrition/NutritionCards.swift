import SwiftUI

// MARK: - Nutrition Summary Card

struct NutritionSummaryCard: View {
    let summary: NutritionSummary
    let dataManager: BPDataManager
    
    // Get goals from daily goals manager
    private var goals: NutritionGoals {
        dataManager.dailyGoalsManager.currentDailyGoals?.nutritionGoals ?? dataManager.nutritionGoals
    }
    @State private var bmrCalories: Double = 0
    @State private var activeCalories: Double = 0
    @State private var netCalories: Double = 0
    @State private var isLoading: Bool = true
    @State private var showingBMRInfo: Bool = false
    @State private var showingCaloriesInfo: Bool = false
    @State private var showingTotalInfo: Bool = false
    
    var body: some View {
        VStack(spacing: 10) {
            // Main Stats - Compact
            HStack(spacing: 12) {
                StatItem(
                    icon: "flame.fill",
                    value: "\(summary.totalCalories.isFinite && !summary.totalCalories.isNaN ? Int(summary.totalCalories) : 0)",
                    label: "Calories",
                    color: .orange,
                    showInfoButton: true,
                    infoAction: {
                        showingCaloriesInfo = true
                    }
                )
                
                StatItem(
                    icon: "figure.walk",
                    value: getBMRDisplayValue(),
                    label: "BMR",
                    color: getBMRDisplayColor(),
                    showInfoButton: true,
                    infoAction: {
                        showingBMRInfo = true
                    }
                )
                
                StatItem(
                    icon: "plusminus",
                    value: getTotalDisplayValue(),
                    label: "Total",
                    color: getTotalDisplayColor(),
                    showInfoButton: true,
                    infoAction: {
                        showingTotalInfo = true
                    }
                )
            }
            
            
            // Goals Progress Section - All Visible
            VStack(alignment: .leading, spacing: 6) {
                Text("Daily Goals Progress")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                VStack(spacing: 5) {
                    // All progress bars visible
                    ProgressBar(
                        label: "Calories",
                        current: summary.totalCalories,
                        goal: goals.dailyCalories,
                        unit: "cal",
                        color: .orange
                    )
                    
                    ProgressBar(
                        label: "Protein",
                        current: summary.totalProtein,
                        goal: goals.dailyProtein,
                        unit: "g",
                        color: .red
                    )
                    
                    ProgressBar(
                        label: "Water",
                        current: summary.totalWater,
                        goal: goals.dailyWater,
                        unit: "oz",
                        color: .blue
                    )
                    
                    ProgressBar(
                        label: "Carbs",
                        current: summary.totalCarbohydrates,
                        goal: goals.dailyCarbohydrates,
                        unit: "g",
                        color: .green
                    )
                    
                    ProgressBar(
                        label: "Fat",
                        current: summary.totalFat,
                        goal: goals.dailyFat,
                        unit: "g",
                        color: .blue
                    )
                    
                    ProgressBar(
                        label: "Total Sugar",
                        current: summary.totalSugar,
                        goal: goals.dailySugar,
                        unit: "g",
                        color: .pink
                    )
                    
                    ProgressBar(
                        label: "Natural Sugar",
                        current: summary.totalNaturalSugar,
                        goal: goals.dailyNaturalSugar,
                        unit: "g",
                        color: .green
                    )
                    
                    ProgressBar(
                        label: "Added Sugar",
                        current: summary.totalAddedSugar,
                        goal: goals.dailyAddedSugar,
                        unit: "g",
                        color: .red
                    )
                    
                    ProgressBar(
                        label: "Sodium",
                        current: summary.totalSodium,
                        goal: goals.dailySodium,
                        unit: "mg",
                        color: .purple
                    )
                    
                    ProgressBar(
                        label: "Fiber",
                        current: summary.totalFiber,
                        goal: goals.dailyFiber,
                        unit: "g",
                        color: .mint
                    )
                    
                    ProgressBar(
                        label: "Cholesterol",
                        current: summary.totalCholesterol,
                        goal: goals.dailyCholesterol,
                        unit: "mg",
                        color: .indigo
                    )
                }
            }
        }
        .onAppear {
            loadCalorieData()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .sheet(isPresented: $showingBMRInfo) {
            BMRInfoView()
        }
        .sheet(isPresented: $showingCaloriesInfo) {
            CaloriesInfoView()
        }
        .sheet(isPresented: $showingTotalInfo) {
            TotalInfoView()
        }
    }
    
    private func loadCalorieData() {
        dataManager.getTodaysCalorieBurn { bmr, active in
            self.bmrCalories = bmr
            self.activeCalories = active
            self.netCalories = self.summary.totalCalories - (bmr + active)
            self.isLoading = false
        }
    }
    
    private func getBMRDisplayValue() -> String {
        if dataManager.bmrManager.profile.isValid {
            let recommendations = dataManager.getBMRRecommendations()
            let totalBurn = recommendations.bmr + activeCalories
            return "\(Int(totalBurn))"
        } else if isLoading {
            return "..."
        } else if bmrCalories + activeCalories > 0 {
            return "\(Int(bmrCalories + activeCalories))"
        } else {
            return "Setup BMR"
        }
    }
    
    private func getBMRDisplayColor() -> Color {
        if dataManager.bmrManager.profile.isValid {
            return .green
        } else {
            return .gray
        }
    }
    
    private func getTotalDisplayValue() -> String {
        if dataManager.bmrManager.profile.isValid {
            let recommendations = dataManager.getBMRRecommendations()
            let totalBurn = recommendations.bmr + activeCalories
            let netCalories = summary.totalCalories - totalBurn
            return "\(Int(netCalories))"
        } else if isLoading {
            return "..."
        } else if bmrCalories + activeCalories > 0 {
            return "\(Int(netCalories))"
        } else {
            return "No Data"
        }
    }
    
    private func getTotalDisplayColor() -> Color {
        if dataManager.bmrManager.profile.isValid {
            let recommendations = dataManager.getBMRRecommendations()
            let totalBurn = recommendations.bmr + activeCalories
            let netCalories = summary.totalCalories - totalBurn
            return netCalories >= 0 ? .red : .blue
        } else if bmrCalories + activeCalories > 0 {
            return netCalories >= 0 ? .red : .blue
        } else {
            return .gray
        }
    }
}


// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let showInfoButton: Bool
    let infoAction: (() -> Void)?
    
    init(icon: String, value: String, label: String, color: Color, showInfoButton: Bool = false, infoAction: (() -> Void)? = nil) {
        self.icon = icon
        self.value = value
        self.label = label
        self.color = color
        self.showInfoButton = showInfoButton
        self.infoAction = infoAction
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                if showInfoButton {
                    Button(action: {
                        infoAction?()
                    }) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Macro Item

struct MacroItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Nutrient Item

struct NutrientItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let label: String
    let current: Double
    let goal: Double
    let unit: String
    let color: Color
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }
    
    private var isOverGoal: Bool {
        return current > goal
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(current))/\(Int(goal)) \(unit)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray5))
                        .frame(height: 5)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isOverGoal ? Color.red : color)
                        .frame(width: geometry.size.width * progress, height: 5)
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - BMR Info View

struct BMRInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What is BMR?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("BMR (Basal Metabolic Rate) is the number of calories your body burns at rest to maintain basic functions like breathing, circulation, and cell production.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("BMR + Active Energy")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("This number combines:")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("•")
                                .foregroundColor(.blue)
                            Text("Your calculated BMR (static)")
                                .font(.body)
                        }
                        
                        HStack {
                            Text("•")
                                .foregroundColor(.green)
                            Text("Real-time active calories from Apple Health")
                                .font(.body)
                        }
                    }
                    .padding(.leading, 8)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it updates")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("•")
                                .foregroundColor(.orange)
                            Text("Morning: BMR + 0 active = BMR")
                                .font(.body)
                        }
                        
                        HStack {
                            Text("•")
                                .foregroundColor(.orange)
                            Text("Afternoon: BMR + 200 active = BMR + 200")
                                .font(.body)
                        }
                        
                        HStack {
                            Text("•")
                                .foregroundColor(.orange)
                            Text("Evening: BMR + 500 active = BMR + 500")
                                .font(.body)
                        }
                    }
                    .padding(.leading, 8)
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("BMR Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Calories Info View

struct CaloriesInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What are Calories?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Calories are units of energy that your body uses to fuel all its functions. The calories you consume through food and drinks provide the energy your body needs to function properly.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Calorie Intake")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("This number shows the total calories you've consumed today from all your nutrition entries, including:")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("•")
                                .foregroundColor(.orange)
                            Text("Food and drinks logged")
                                .font(.body)
                        }
                        
                        HStack {
                            Text("•")
                                .foregroundColor(.orange)
                            Text("Barcode-scanned items")
                                .font(.body)
                        }
                        
                        HStack {
                            Text("•")
                                .foregroundColor(.orange)
                            Text("Custom nutrition templates")
                                .font(.body)
                        }
                        
                        HStack {
                            Text("•")
                                .foregroundColor(.orange)
                            Text("Quick input entries")
                                .font(.body)
                        }
                    }
                    .padding(.leading, 8)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Real-time Updates")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("This number updates immediately as you add new nutrition entries throughout the day, giving you a live view of your calorie consumption.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Calories Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Total Info View

struct TotalInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("What is Net Calories?")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Net calories represent the difference between the calories you've consumed and the calories you've burned. This gives you insight into whether you're in a calorie surplus or deficit.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("How it's calculated")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("Net Calories = Food Calories - (BMR + Active Energy)")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Text("Where:")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("•")
                                .foregroundColor(.orange)
                            Text("Food Calories: Total calories consumed today")
                                .font(.body)
                        }
                        
                        HStack {
                            Text("•")
                                .foregroundColor(.green)
                            Text("BMR: Your calculated basal metabolic rate")
                                .font(.body)
                        }
                        
                        HStack {
                            Text("•")
                                .foregroundColor(.blue)
                            Text("Active Energy: Real-time calories from Apple Health")
                                .font(.body)
                        }
                    }
                    .padding(.leading, 8)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("What the colors mean")
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            Text("Red: Calorie surplus (consumed more than burned)")
                                .font(.body)
                        }
                        
                        HStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                            Text("Blue: Calorie deficit (burned more than consumed)")
                                .font(.body)
                        }
                        
                        HStack {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 12, height: 12)
                            Text("Gray: No data available")
                                .font(.body)
                        }
                    }
                    .padding(.leading, 8)
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Total Information")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}


#Preview {
    VStack(spacing: 20) {
        NutritionSummaryCard(
            summary: NutritionSummary(
                entries: [
                    NutritionEntry(calories: 500, protein: 25, carbohydrates: 60, fat: 15, water: 16)
                ],
                goals: NutritionGoals()
            ),
            dataManager: BPDataManager()
        )
    }
    .padding()
}
