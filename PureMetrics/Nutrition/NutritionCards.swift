import SwiftUI

// MARK: - Nutrition Summary Card

struct NutritionSummaryCard: View {
    let summary: NutritionSummary
    let goals: NutritionGoals
    
    var body: some View {
        VStack(spacing: 10) {
            // Main Stats - Compact
            HStack(spacing: 12) {
                StatItem(
                    icon: "flame.fill",
                    value: "\(summary.totalCalories.isFinite && !summary.totalCalories.isNaN ? Int(summary.totalCalories) : 0)",
                    label: "Calories",
                    color: .orange
                )
                
                StatItem(
                    icon: "scalemass.fill",
                    value: "\(summary.totalProtein.isFinite && !summary.totalProtein.isNaN ? Int(summary.totalProtein) : 0)",
                    label: "Protein",
                    color: .red
                )
                
                StatItem(
                    icon: "drop.fill",
                    value: "\(summary.totalWater.isFinite && !summary.totalWater.isNaN ? Int(summary.totalWater) : 0)",
                    label: "Water",
                    color: .blue
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
        .padding(14)
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
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
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
    }
    .padding()
}
