import SwiftUI

struct AddCustomNutritionTemplateView: View {
    @ObservedObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbohydrates = ""
    @State private var fat = ""
    @State private var sodium = ""
    @State private var sugar = ""
    @State private var addedSugar = ""
    @State private var fiber = ""
    @State private var cholesterol = ""
    @State private var water = ""
    @State private var servingAmount: Double = 1.0
    @State private var servingAmountText: String = "1.0"
    @State private var servingSizeUnit: String = "serving"
    @State private var selectedCategory = NutritionTemplateCategory.general
    @State private var notes = ""
    
    private let inputFields = [
        NutritionInputField(unit: "cal", label: "Calories", icon: "flame.fill", color: "orange"),
        NutritionInputField(unit: "g", label: "Protein", icon: "scalemass.fill", color: "red"),
        NutritionInputField(unit: "g", label: "Carbs", icon: "leaf.fill", color: "green"),
        NutritionInputField(unit: "g", label: "Fat", icon: "drop.fill", color: "blue"),
        NutritionInputField(unit: "mg", label: "Sodium", icon: "cube.fill", color: "purple"),
        NutritionInputField(unit: "g", label: "Sugar", icon: "sparkles", color: "pink"),
        NutritionInputField(unit: "g", label: "Added Sugar", icon: "plus.circle.fill", color: "orange"),
        NutritionInputField(unit: "g", label: "Fiber", icon: "leaf.arrow.circlepath", color: "mint"),
        NutritionInputField(unit: "mg", label: "Cholesterol", icon: "heart.fill", color: "red"),
        NutritionInputField(unit: "oz", label: "Water", icon: "drop.circle.fill", color: "cyan")
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Basic Info
                    basicInfoSection
                    
                    // Nutrition Values
                    nutritionValuesSection
                    
                    // Category Selection
                    categorySection
                    
                    // Notes
                    notesSection
                }
                .padding()
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(name.isEmpty || !hasValidInput)
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Create Custom Template")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Save common foods for quick access")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                TextField("Template Name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                // Serving amount input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Amount")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("1.0", text: $servingAmountText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .onChange(of: servingAmountText) { newValue in
                            servingAmount = Double(newValue) ?? 1.0
                        }
                }
                
                // Unit input
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unit")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextField("serving", text: $servingSizeUnit)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Quick unit buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["serving", "cup", "cups", "tbsp", "tsp", "oz", "ml", "g", "piece", "slice"], id: \.self) { unit in
                            Button(unit) {
                                servingSizeUnit = unit
                            }
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(servingSizeUnit == unit ? Color.blue : Color(.systemGray5))
                            )
                            .foregroundColor(servingSizeUnit == unit ? .white : .primary)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Nutrition Values Section
    
    private var nutritionValuesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Nutrition Values")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(Array(inputFields.enumerated()), id: \.offset) { index, field in
                    CustomNutritionInputFieldView(
                        field: field,
                        value: getValueForField(field),
                        onValueChange: { newValue in
                            setValueForField(field, value: newValue)
                        }
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Category Section
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Menu {
                ForEach(NutritionTemplateCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(category.rawValue)
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: selectedCategory.icon)
                        .foregroundColor(selectedCategory.color)
                    
                    Text(selectedCategory.rawValue)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            TextField("Add any notes about this template...", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Helper Functions
    
    private func getValueForField(_ field: NutritionInputField) -> String {
        switch field.label {
        case "Calories": return calories
        case "Protein": return protein
        case "Carbs": return carbohydrates
        case "Fat": return fat
        case "Sodium": return sodium
        case "Sugar": return sugar
        case "Added Sugar": return addedSugar
        case "Fiber": return fiber
        case "Cholesterol": return cholesterol
        case "Water": return water
        default: return ""
        }
    }
    
    private func setValueForField(_ field: NutritionInputField, value: String) {
        switch field.label {
        case "Calories": calories = value
        case "Protein": protein = value
        case "Carbs": carbohydrates = value
        case "Fat": fat = value
        case "Sodium": sodium = value
        case "Sugar": sugar = value
        case "Added Sugar": addedSugar = value
        case "Fiber": fiber = value
        case "Cholesterol": cholesterol = value
        case "Water": water = value
        default: break
        }
    }
    
    private var hasValidInput: Bool {
        return !calories.isEmpty || !protein.isEmpty || !carbohydrates.isEmpty || 
               !fat.isEmpty || !sodium.isEmpty || !sugar.isEmpty || !addedSugar.isEmpty ||
               !fiber.isEmpty || !cholesterol.isEmpty || !water.isEmpty
    }
    
    private func saveTemplate() {
        let template = CustomNutritionTemplate(
            name: name,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbohydrates: Double(carbohydrates) ?? 0,
            fat: Double(fat) ?? 0,
            sodium: Double(sodium) ?? 0,
            sugar: Double(sugar) ?? 0,
            addedSugar: Double(addedSugar) ?? 0,
            fiber: Double(fiber) ?? 0,
            cholesterol: Double(cholesterol) ?? 0,
            water: Double(water) ?? 0,
            servingSize: "\(servingAmountText) \(servingSizeUnit)",
            category: selectedCategory.rawValue,
            notes: notes.isEmpty ? nil : notes
        )
        
        dataManager.addCustomNutritionTemplate(template)
        presentationMode.wrappedValue.dismiss()
    }
}

struct CustomNutritionInputFieldView: View {
    let field: NutritionInputField
    let value: String
    let onValueChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: field.icon)
                    .font(.subheadline)
                    .foregroundColor(Color(field.color))
                
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
    AddCustomNutritionTemplateView(dataManager: BPDataManager())
}
