import SwiftUI

// MARK: - Nutrition Summary Card

struct NutritionSummaryCard: View {
    let summary: NutritionSummary
    let goals: NutritionGoals
    
    var body: some View {
        VStack(spacing: 16) {
            // Main Stats
            HStack(spacing: 20) {
                StatItem(
                    icon: "flame.fill",
                    value: "\(Int(summary.totalCalories))",
                    label: "Calories",
                    color: .orange
                )
                
                StatItem(
                    icon: "drop.fill",
                    value: "\(Int(summary.totalWater))",
                    label: "Water (oz)",
                    color: .blue
                )
                
                StatItem(
                    icon: "scalemass.fill",
                    value: "\(Int(summary.totalProtein))",
                    label: "Protein (g)",
                    color: .red
                )
            }
            
            // Macro Breakdown
            VStack(alignment: .leading, spacing: 8) {
                Text("Macros")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    MacroItem(
                        label: "Carbs",
                        value: "\(Int(summary.totalCarbohydrates))g",
                        color: .green
                    )
                    
                    MacroItem(
                        label: "Fat",
                        value: "\(Int(summary.totalFat))g",
                        color: .blue
                    )
                    
                    MacroItem(
                        label: "Fiber",
                        value: "\(Int(summary.totalFiber))g",
                        color: .mint
                    )
                }
            }
            
            // Additional Nutrients
            HStack(spacing: 16) {
                NutrientItem(
                    label: "Sodium",
                    value: summary.totalSodium >= 1000 ? 
                        "\(String(format: "%.1f", summary.totalSodium / 1000))g" : 
                        "\(Int(summary.totalSodium))mg",
                    color: .purple
                )
                
                NutrientItem(
                    label: "Sugar",
                    value: "\(Int(summary.totalSugar))g",
                    color: .pink
                )
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

// MARK: - Goals Progress Card

struct GoalsProgressCard: View {
    let summary: NutritionSummary
    let goals: NutritionGoals
    
    var body: some View {
        VStack(spacing: 16) {
            // Progress Bars
            VStack(spacing: 12) {
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
                    label: "Water",
                    current: summary.totalWater,
                    goal: goals.dailyWater,
                    unit: "oz",
                    color: .cyan
                )
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

// MARK: - Stat Item

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(label)
                .font(.caption)
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
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
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
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOverGoal ? Color.red : color)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
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
            goals: NutritionGoals()
        )
        
        GoalsProgressCard(
            summary: NutritionSummary(
                entries: [
                    NutritionEntry(calories: 1500, protein: 100, carbohydrates: 200, fat: 50, water: 32)
                ],
                goals: NutritionGoals()
            ),
            goals: NutritionGoals()
        )
    }
    .padding()
}
