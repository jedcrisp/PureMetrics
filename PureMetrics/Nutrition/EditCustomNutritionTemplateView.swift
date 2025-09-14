import SwiftUI

struct EditCustomNutritionTemplateView: View {
    let template: CustomNutritionTemplate
    @ObservedObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var name: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbohydrates: String
    @State private var fat: String
    @State private var sodium: String
    @State private var sugar: String
    @State private var naturalSugar: String
    @State private var addedSugar: String
    @State private var fiber: String
    @State private var cholesterol: String
    @State private var water: String
    @State private var servingSize: String
    @State private var selectedCategory: NutritionTemplateCategory
    @State private var notes: String
    
    private let inputFields = [
        NutritionInputField(unit: "cal", label: "Calories", icon: "flame.fill", color: "orange"),
        NutritionInputField(unit: "g", label: "Protein", icon: "scalemass.fill", color: "red"),
        NutritionInputField(unit: "g", label: "Carbs", icon: "leaf.fill", color: "green"),
        NutritionInputField(unit: "g", label: "Fat", icon: "drop.fill", color: "blue"),
        NutritionInputField(unit: "mg", label: "Sodium", icon: "cube.fill", color: "purple"),
        NutritionInputField(unit: "g", label: "Total Sugar", icon: "sparkles", color: "pink"),
        NutritionInputField(unit: "g", label: "Natural Sugar", icon: "leaf.fill", color: "green"),
        NutritionInputField(unit: "g", label: "Added Sugar", icon: "exclamationmark.triangle.fill", color: "red"),
        NutritionInputField(unit: "g", label: "Fiber", icon: "leaf.arrow.circlepath", color: "mint"),
        NutritionInputField(unit: "mg", label: "Cholesterol", icon: "heart.fill", color: "red"),
        NutritionInputField(unit: "oz", label: "Water", icon: "drop.circle.fill", color: "cyan")
    ]
    
    init(template: CustomNutritionTemplate, dataManager: BPDataManager) {
        self.template = template
        self.dataManager = dataManager
        
        _name = State(initialValue: template.name)
        _calories = State(initialValue: template.calories > 0 ? String(Int(template.calories)) : "")
        _protein = State(initialValue: template.protein > 0 ? String(format: "%.1f", template.protein) : "")
        _carbohydrates = State(initialValue: template.carbohydrates > 0 ? String(format: "%.1f", template.carbohydrates) : "")
        _fat = State(initialValue: template.fat > 0 ? String(format: "%.1f", template.fat) : "")
        _sodium = State(initialValue: template.sodium > 0 ? String(format: "%.1f", template.sodium) : "")
        _sugar = State(initialValue: template.sugar > 0 ? String(format: "%.1f", template.sugar) : "")
        _naturalSugar = State(initialValue: (template.naturalSugar ?? 0) > 0 ? String(format: "%.1f", template.naturalSugar ?? 0) : "")
        _addedSugar = State(initialValue: template.addedSugar > 0 ? String(format: "%.1f", template.addedSugar) : "")
        _fiber = State(initialValue: template.fiber > 0 ? String(format: "%.1f", template.fiber) : "")
        _cholesterol = State(initialValue: template.cholesterol > 0 ? String(format: "%.1f", template.cholesterol) : "")
        _water = State(initialValue: template.water > 0 ? String(format: "%.1f", template.water) : "")
        _servingSize = State(initialValue: template.servingSize)
        _selectedCategory = State(initialValue: NutritionTemplateCategory(rawValue: template.category) ?? .general)
        _notes = State(initialValue: template.notes ?? "")
    }
    
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
            .navigationTitle("Edit Template")
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
            
            Text("Edit Template")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Update your custom nutrition template")
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
                
                TextField("Serving Size", text: $servingSize)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
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
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(NutritionTemplateCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: category.icon)
                                .font(.title3)
                                .foregroundColor(selectedCategory == category ? .white : category.color)
                            
                            Text(category.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedCategory == category ? category.color : Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
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
        case "Total Sugar": return sugar
        case "Natural Sugar": return naturalSugar
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
        case "Total Sugar": sugar = value
        case "Natural Sugar": naturalSugar = value
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
        let updatedTemplate = CustomNutritionTemplate(
            id: template.id,
            name: name,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbohydrates: Double(carbohydrates) ?? 0,
            fat: Double(fat) ?? 0,
            sodium: Double(sodium) ?? 0,
            sugar: Double(sugar) ?? 0,
            naturalSugar: Double(naturalSugar) ?? 0,
            addedSugar: Double(addedSugar) ?? 0,
            fiber: Double(fiber) ?? 0,
            cholesterol: Double(cholesterol) ?? 0,
            water: Double(water) ?? 0,
            servingSize: servingSize,
            category: selectedCategory.rawValue,
            notes: notes.isEmpty ? nil : notes,
            dateCreated: template.dateCreated,
            lastUsed: template.lastUsed
        )
        
        dataManager.updateCustomNutritionTemplate(updatedTemplate)
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    EditCustomNutritionTemplateView(
        template: CustomNutritionTemplate(
            name: "Sample Template",
            calories: 250,
            protein: 15,
            carbohydrates: 30,
            fat: 8
        ),
        dataManager: BPDataManager()
    )
}
