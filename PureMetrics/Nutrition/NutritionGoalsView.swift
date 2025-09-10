import SwiftUI

struct NutritionGoalsView: View {
    let goals: NutritionGoals
    let onSave: (NutritionGoals) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var dailyCalories: String = ""
    @State private var dailyProtein: String = ""
    @State private var dailyCarbohydrates: String = ""
    @State private var dailyFat: String = ""
    @State private var dailySodium: String = ""
    @State private var dailySugar: String = ""
    @State private var dailyFiber: String = ""
    @State private var dailyWater: String = ""
    
    private let goalFields = [
        GoalField(label: "Daily Calories", value: "dailyCalories", unit: "cal", icon: "flame.fill", color: .orange),
        GoalField(label: "Protein", value: "dailyProtein", unit: "g", icon: "scalemass.fill", color: .red),
        GoalField(label: "Carbohydrates", value: "dailyCarbohydrates", unit: "g", icon: "leaf.fill", color: .green),
        GoalField(label: "Fat", value: "dailyFat", unit: "g", icon: "drop.fill", color: .blue),
        GoalField(label: "Sodium", value: "dailySodium", unit: "mg", icon: "cube.fill", color: .purple),
        GoalField(label: "Sugar", value: "dailySugar", unit: "g", icon: "sparkles", color: .pink),
        GoalField(label: "Fiber", value: "dailyFiber", unit: "g", icon: "leaf.arrow.circlepath", color: .mint),
        GoalField(label: "Water", value: "dailyWater", unit: "oz", icon: "drop.circle.fill", color: .cyan)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Goal Fields
                        goalFieldsSection
                        
                        // Save Button
                        saveButtonSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Nutrition Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoals()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            loadCurrentGoals()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Set Your Nutrition Goals")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Customize your daily nutrition targets")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Goal Fields Section
    
    private var goalFieldsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Goals")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(goalFields, id: \.value) { field in
                    GoalFieldView(
                        field: field,
                        value: getValueForField(field),
                        onValueChange: { newValue in
                            setValueForField(field, value: newValue)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Save Button Section
    
    private var saveButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                saveGoals()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Save Goals")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .foregroundColor(.white)
            }
            
            Text("Goals will be used to track your daily progress")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadCurrentGoals() {
        dailyCalories = String(Int(goals.dailyCalories))
        dailyProtein = String(Int(goals.dailyProtein))
        dailyCarbohydrates = String(Int(goals.dailyCarbohydrates))
        dailyFat = String(Int(goals.dailyFat))
        dailySodium = String(Int(goals.dailySodium))
        dailySugar = String(Int(goals.dailySugar))
        dailyFiber = String(Int(goals.dailyFiber))
        dailyWater = String(Int(goals.dailyWater))
    }
    
    private func getValueForField(_ field: GoalField) -> String {
        switch field.value {
        case "dailyCalories": return dailyCalories
        case "dailyProtein": return dailyProtein
        case "dailyCarbohydrates": return dailyCarbohydrates
        case "dailyFat": return dailyFat
        case "dailySodium": return dailySodium
        case "dailySugar": return dailySugar
        case "dailyFiber": return dailyFiber
        case "dailyWater": return dailyWater
        default: return ""
        }
    }
    
    private func setValueForField(_ field: GoalField, value: String) {
        switch field.value {
        case "dailyCalories": dailyCalories = value
        case "dailyProtein": dailyProtein = value
        case "dailyCarbohydrates": dailyCarbohydrates = value
        case "dailyFat": dailyFat = value
        case "dailySodium": dailySodium = value
        case "dailySugar": dailySugar = value
        case "dailyFiber": dailyFiber = value
        case "dailyWater": dailyWater = value
        default: break
        }
    }
    
    private func saveGoals() {
        let newGoals = NutritionGoals(
            dailyCalories: Double(dailyCalories) ?? goals.dailyCalories,
            dailyProtein: Double(dailyProtein) ?? goals.dailyProtein,
            dailyCarbohydrates: Double(dailyCarbohydrates) ?? goals.dailyCarbohydrates,
            dailyFat: Double(dailyFat) ?? goals.dailyFat,
            dailySodium: Double(dailySodium) ?? goals.dailySodium,
            dailySugar: Double(dailySugar) ?? goals.dailySugar,
            dailyFiber: Double(dailyFiber) ?? goals.dailyFiber,
            dailyWater: Double(dailyWater) ?? goals.dailyWater
        )
        
        onSave(newGoals)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Goal Field

struct GoalField {
    let label: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
}

// MARK: - Goal Field View

struct GoalFieldView: View {
    let field: GoalField
    let value: String
    let onValueChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: field.icon)
                    .font(.subheadline)
                    .foregroundColor(field.color)
                
                Text(field.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            
            HStack {
                TextField("0", text: Binding(
                    get: { value },
                    set: { onValueChange($0) }
                ))
                .textFieldStyle(PlainTextFieldStyle())
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                
                Text(field.unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

#Preview {
    NutritionGoalsView(
        goals: NutritionGoals(),
        onSave: { _ in }
    )
}
