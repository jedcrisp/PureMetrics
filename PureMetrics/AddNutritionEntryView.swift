import SwiftUI

struct AddNutritionEntryView: View {
    let selectedDate: Date
    let onSave: (NutritionEntry) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbohydrates: String = ""
    @State private var fat: String = ""
    @State private var sodium: String = ""
    @State private var sugar: String = ""
    @State private var fiber: String = ""
    @State private var water: String = ""
    @State private var notes: String = ""
    @State private var showingSaveConfirmation = false
    
    private let inputFields = [
        NutritionInputField(unit: "cal", label: "Calories", icon: "flame.fill", color: "orange"),
        NutritionInputField(unit: "g", label: "Protein", icon: "scalemass.fill", color: "red"),
        NutritionInputField(unit: "g", label: "Carbs", icon: "leaf.fill", color: "green"),
        NutritionInputField(unit: "g", label: "Fat", icon: "drop.fill", color: "blue"),
        NutritionInputField(unit: "mg", label: "Sodium", icon: "cube.fill", color: "purple"),
        NutritionInputField(unit: "g", label: "Sugar", icon: "sparkles", color: "pink"),
        NutritionInputField(unit: "g", label: "Fiber", icon: "leaf.arrow.circlepath", color: "mint"),
        NutritionInputField(unit: "oz", label: "Water", icon: "drop.circle.fill", color: "cyan")
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
                        
                        // Date Display
                        dateSection
                        
                        // Input Fields
                        inputFieldsSection
                        
                        // Notes Section
                        notesSection
                        
                        // Save Button
                        saveButtonSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Add Nutrition Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert("Save Entry", isPresented: $showingSaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveEntry()
            }
        } message: {
            Text("This will add the nutrition entry for \(selectedDate.formatted(date: .abbreviated, time: .omitted)).")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundColor(.green)
            
            Text("Add Nutrition Entry")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Track your daily nutrition intake")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Date Section
    
    private var dateSection: some View {
        VStack(spacing: 8) {
            Text("Date")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(selectedDate.formatted(date: .complete, time: .omitted))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
        }
    }
    
    // MARK: - Input Fields Section
    
    private var inputFieldsSection: some View {
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
                    NutritionInputFieldView(
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
    
    // MARK: - Notes Section
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            TextField("Add any notes about this meal...", text: $notes, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
    }
    
    // MARK: - Save Button Section
    
    private var saveButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingSaveConfirmation = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Save Entry")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: hasValidInput ? [Color.green, Color.green.opacity(0.8)] : [Color.gray, Color.gray.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: hasValidInput ? .green.opacity(0.3) : .gray.opacity(0.3), radius: 8, x: 0, y: 4)
                )
                .foregroundColor(.white)
            }
            .disabled(!hasValidInput)
            
            if !hasValidInput {
                Text("Enter at least one nutrition value to save")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
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
        case "Fiber": return fiber
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
        case "Fiber": fiber = value
        case "Water": water = value
        default: break
        }
    }
    
    private var hasValidInput: Bool {
        return !calories.isEmpty || !protein.isEmpty || !carbohydrates.isEmpty || 
               !fat.isEmpty || !sodium.isEmpty || !sugar.isEmpty || 
               !fiber.isEmpty || !water.isEmpty
    }
    
    private func saveEntry() {
        let entry = NutritionEntry(
            date: selectedDate,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbohydrates: Double(carbohydrates) ?? 0,
            fat: Double(fat) ?? 0,
            sodium: Double(sodium) ?? 0,
            sugar: Double(sugar) ?? 0,
            fiber: Double(fiber) ?? 0,
            water: Double(water) ?? 0,
            notes: notes.isEmpty ? nil : notes
        )
        
        onSave(entry)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Nutrition Input Field View

struct NutritionInputFieldView: View {
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
    AddNutritionEntryView(
        selectedDate: Date(),
        onSave: { _ in }
    )
}
