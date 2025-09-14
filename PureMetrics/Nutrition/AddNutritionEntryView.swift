import SwiftUI

struct AddNutritionEntryView: View {
    let selectedDate: Date
    let onSave: (NutritionEntry) -> Void
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var labelManager: NutritionLabelManager
    @ObservedObject var dataManager: BPDataManager
    
    // Basic Info
    @State private var foodName: String = ""
    @State private var servingAmount: Double = 1.0
    @State private var servingAmountText: String = "1.0"
    @State private var servingSizeUnit: String = "serving"
    @State private var selectedCategory: NutritionTemplateCategory = .general
    
    // Nutrition Values
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbohydrates: String = ""
    @State private var fat: String = ""
    @State private var sodium: String = ""
    @State private var sugar: String = ""
    @State private var naturalSugar: String = ""
    @State private var addedSugar: String = ""
    @State private var fiber: String = ""
    @State private var water: String = ""
    @State private var notes: String = ""
    
    // Base nutritional values (per 1 serving) for proportional recalculation
    @State private var baseCalories: Double = 0
    @State private var baseProtein: Double = 0
    @State private var baseCarbohydrates: Double = 0
    @State private var baseFat: Double = 0
    @State private var baseSodium: Double = 0
    @State private var baseSugar: Double = 0
    @State private var baseNaturalSugar: Double = 0
    @State private var baseAddedSugar: Double = 0
    @State private var baseFiber: Double = 0
    @State private var baseWater: Double = 0
    @State private var selectedLabel: String? = nil
    @State private var showingSaveConfirmation = false
    @State private var showingAddCustomLabel = false
    @State private var customLabelName = ""
    @State private var showingTemplateSelection = false
    @State private var saveMode: SaveMode = .createTemplate
    @State private var showingModeSelection = false
    
    enum SaveMode: String, CaseIterable {
        case createTemplate = "Create Template"
        case addToToday = "Add to Today"
        
        var description: String {
            switch self {
            case .createTemplate:
                return "Save to My Foods for future use"
            case .addToToday:
                return "Add directly to today's nutrition entries"
            }
        }
        
        var icon: String {
            switch self {
            case .createTemplate:
                return "star.fill"
            case .addToToday:
                return "calendar.badge.plus"
            }
        }
    }
    
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
                        
                        // Basic Info Section
                        basicInfoSection
                        
                        // Input Fields
                        inputFieldsSection
                        
                        // Notes Section
                        notesSection
                        
                        // Label Section
                        labelSection
                        
                        // Template Selection
                        templateSection
                        
                        // Save Mode Selection
                        saveModeSection
                        
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
        .alert(saveMode.rawValue, isPresented: $showingSaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                saveEntry()
            }
        } message: {
            Text(saveMode == .createTemplate ? 
                 "This will create a new template in My Foods for future use." : 
                 "This will add the nutrition entry for \(selectedDate.formatted(date: .abbreviated, time: .omitted)).")
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
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Food Information")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Food Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Food Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Enter food name", text: $foodName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            // Serving Size
            VStack(alignment: .leading, spacing: 12) {
                Text("Serving Size")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                HStack(spacing: 12) {
                    // Amount
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Amount")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("1.0", text: $servingAmountText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .onChange(of: servingAmountText) { newValue in
                                if let amount = Double(newValue) {
                                    servingAmount = amount
                                    // Removed automatic recalculation - serving size changes no longer affect nutritional values
                                }
                            }
                    }
                    
                    // Unit
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("serving", text: $servingSizeUnit)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Quick Unit Buttons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["serving", "cup", "cups", "tbsp", "tsp", "oz", "ml", "g", "piece", "slice"], id: \.self) { unit in
                            Button(action: {
                                servingSizeUnit = unit
                            }) {
                                Text(unit)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(servingSizeUnit == unit ? .white : .blue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(servingSizeUnit == unit ? Color.blue : Color.blue.opacity(0.1))
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Category Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.subheadline)
                    .fontWeight(.medium)
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
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
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
    
    // MARK: - Label Section
    
    private var labelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Label (Optional)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Add Custom") {
                    showingAddCustomLabel = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            // Selected Label Display
            if let selectedLabel = selectedLabel {
                HStack {
                    if let label = labelManager.getLabelByName(selectedLabel) {
                        Image(systemName: label.icon)
                            .foregroundColor(label.color)
                        Text(label.name)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    Button("Remove") {
                        self.selectedLabel = nil
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                )
            } else {
                // Label Selection Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(labelManager.availableLabels, id: \.id) { label in
                        Button(action: {
                            selectedLabel = label.name
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: label.icon)
                                    .font(.title3)
                                    .foregroundColor(label.color)
                                
                                Text(label.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddCustomLabel) {
            addCustomLabelSheet
        }
        .sheet(isPresented: $showingTemplateSelection) {
            templateSelectionSheet
        }
    }
    
    // MARK: - Template Section
    
    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Use Template")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Button(action: {
                showingTemplateSelection = true
            }) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.blue)
                    
                    Text("Select from Custom Templates")
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Template Selection Sheet
    
    private var templateSelectionSheet: some View {
        NavigationView {
            List {
                ForEach(dataManager.customNutritionTemplates) { (template: CustomNutritionTemplate) in
                    Button(action: {
                        calories = String(template.calories)
                        protein = String(template.protein)
                        carbohydrates = String(template.carbohydrates)
                        fat = String(template.fat)
                        sodium = String(template.sodium)
                        sugar = String(template.sugar)
                        naturalSugar = String(template.naturalSugar ?? 0)
                        addedSugar = String(template.addedSugar)
                        fiber = String(template.fiber)
                        water = String(template.water)
                        notes = template.notes ?? ""
                        showingTemplateSelection = false
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(template.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(template.category)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 12) {
                                    if template.calories > 0 {
                                        Text("\(Int(template.calories)) cal")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    
                                    if template.protein > 0 {
                                        Text("\(Int(template.protein))g protein")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingTemplateSelection = false
                    }
                }
            }
        }
    }
    
    // MARK: - Add Custom Label Sheet
    
    private var addCustomLabelSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Label Name", text: $customLabelName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Add Custom Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        customLabelName = ""
                        showingAddCustomLabel = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if !customLabelName.isEmpty {
                            labelManager.addCustomLabel(customLabelName)
                            selectedLabel = customLabelName
                            customLabelName = ""
                            showingAddCustomLabel = false
                        }
                    }
                    .disabled(customLabelName.isEmpty)
                }
            }
        }
    }
    
    // MARK: - Save Mode Section
    
    private var saveModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Save Options")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Button(action: {
                showingModeSelection = true
            }) {
                HStack {
                    Image(systemName: saveMode.icon)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(saveMode.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        Text(saveMode.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingModeSelection) {
            saveModeSelectionSheet
        }
    }
    
    // MARK: - Save Mode Selection Sheet
    
    private var saveModeSelectionSheet: some View {
        NavigationView {
            List {
                ForEach(SaveMode.allCases, id: \.self) { mode in
                    Button(action: {
                        saveMode = mode
                        showingModeSelection = false
                    }) {
                        HStack {
                            Image(systemName: mode.icon)
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(mode.rawValue)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(mode.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if saveMode == mode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Save Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingModeSelection = false
                    }
                }
            }
        }
    }
    
    // MARK: - Save Button Section
    
    private var saveButtonSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                showingSaveConfirmation = true
            }) {
                HStack(spacing: 10) {
                    Image(systemName: saveMode.icon)
                        .font(.title3)
                    Text(saveMode.rawValue)
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
        case "Total Sugar": return sugar
        case "Natural Sugar": return naturalSugar
        case "Added Sugar": return addedSugar
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
        case "Total Sugar": sugar = value
        case "Natural Sugar": naturalSugar = value
        case "Added Sugar": addedSugar = value
        case "Fiber": fiber = value
        case "Water": water = value
        default: break
        }
        
        // Update base values when user manually changes nutritional values
        updateBaseValues()
    }
    
    private var hasValidInput: Bool {
        return !calories.isEmpty || !protein.isEmpty || !carbohydrates.isEmpty || 
               !fat.isEmpty || !sodium.isEmpty || !sugar.isEmpty || !naturalSugar.isEmpty || !addedSugar.isEmpty ||
               !fiber.isEmpty || !water.isEmpty
    }
    
    private func saveEntry() {
        switch saveMode {
        case .createTemplate:
            createTemplate()
        case .addToToday:
            addToToday()
        }
    }
    
    private func createTemplate() {
        let template = CustomNutritionTemplate(
            name: foodName.isEmpty ? "Custom Food" : foodName,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbohydrates: Double(carbohydrates) ?? 0,
            fat: Double(fat) ?? 0,
            sodium: Double(sodium) ?? 0,
            sugar: Double(sugar) ?? 0,
            naturalSugar: Double(naturalSugar) ?? 0,
            addedSugar: Double(addedSugar) ?? 0,
            fiber: Double(fiber) ?? 0,
            cholesterol: 0,
            water: Double(water) ?? 0,
            servingSize: "\(servingAmountText) \(servingSizeUnit)",
            category: selectedCategory.rawValue,
            notes: notes.isEmpty ? nil : notes
        )
        
        dataManager.addCustomNutritionTemplate(template)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func addToToday() {
        let entry = NutritionEntry(
            date: selectedDate,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbohydrates: Double(carbohydrates) ?? 0,
            fat: Double(fat) ?? 0,
            sodium: Double(sodium) ?? 0,
            sugar: Double(sugar) ?? 0,
            naturalSugar: Double(naturalSugar) ?? 0,
            addedSugar: Double(addedSugar) ?? 0,
            fiber: Double(fiber) ?? 0,
            water: Double(water) ?? 0,
            notes: notes.isEmpty ? nil : notes,
            label: selectedLabel
        )
        
        onSave(entry)
        presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: - Proportional Recalculation (Removed)
    
    // Automatic recalculation when serving size changes has been removed
    // Users can now change serving size without affecting nutritional values
    
    private func updateBaseValues() {
        // Store the current values as base values (per 1 serving)
        baseCalories = Double(calories) ?? 0
        baseProtein = Double(protein) ?? 0
        baseCarbohydrates = Double(carbohydrates) ?? 0
        baseFat = Double(fat) ?? 0
        baseSodium = Double(sodium) ?? 0
        baseSugar = Double(sugar) ?? 0
        baseNaturalSugar = Double(naturalSugar) ?? 0
        baseAddedSugar = Double(addedSugar) ?? 0
        baseFiber = Double(fiber) ?? 0
        baseWater = Double(water) ?? 0
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
        onSave: { _ in },
        labelManager: NutritionLabelManager(),
        dataManager: BPDataManager()
    )
}
