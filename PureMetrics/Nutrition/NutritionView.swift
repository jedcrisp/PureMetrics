import SwiftUI

enum QuickInputType: String, CaseIterable {
    case calories = "Calories"
    case water = "Water"
    case protein = "Protein"
    case fiber = "Fiber"
    case sodium = "Sodium"
    case carbs = "Carbs"
    case fat = "Fat"
    case cholesterol = "Cholesterol"
    
    var unit: String {
        switch self {
        case .calories: return "cal"
        case .water: return "oz"
        case .protein, .fiber, .carbs, .fat: return "g"
        case .sodium, .cholesterol: return "mg"
        }
    }
    
    var icon: String {
        switch self {
        case .calories: return "flame.fill"
        case .water: return "drop.fill"
        case .protein: return "scalemass.fill"
        case .fiber: return "leaf.fill"
        case .sodium: return "drop.triangle.fill"
        case .carbs: return "leaf.fill"
        case .fat: return "circle.fill"
        case .cholesterol: return "heart.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .calories: return .orange
        case .water: return .blue
        case .protein: return .red
        case .fiber: return .green
        case .sodium: return .purple
        case .carbs: return .yellow
        case .fat: return .brown
        case .cholesterol: return .pink
        }
    }
}

struct NutritionView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var selectedDate = Date()
    @State private var showingAddEntry = false
    @State private var showingGoals = false
    @State private var showingScanner = false
    @State private var showingBarcodeScanner = false
    @State private var showingHistory = false
    @State private var showingCustomTemplates = false
    @State private var showingTodaysEntries = false
    @State private var showingUnifiedEdit = false
    
    // Quick input states
    @State private var showingQuickInput = false
    @State private var selectedQuickInputType: QuickInputType = .calories
    @State private var quickInputValue = ""
    
    // Success popup states
    @State private var showingSuccessPopup = false
    @State private var successMessage = ""
    
    // PDF generation state
    
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
                        VStack(spacing: 12) {
                            // Today's Summary
                            todaysSummarySection
                            
                            // Food Access Section
                            foodAccessSection
                            
                            // Quick Add Buttons
                            // quickAddSection
                            
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("PDF") {
                    }
                }
            }
        }
        .onAppear {
            // Load nutrition entries for the current selected date when view appears
            dataManager.loadNutritionEntriesForDate(selectedDate)
        }
        .sheet(isPresented: $showingAddEntry) {
            AddNutritionEntryView(
                selectedDate: selectedDate,
                onSave: { entry in
                    dataManager.addNutritionEntry(entry)
                    successMessage = "Food added to summary!"
                    showingSuccessPopup = true
                },
                labelManager: dataManager.nutritionLabelManager,
                dataManager: dataManager
            )
        }
        .sheet(isPresented: $showingGoals) {
            NutritionGoalsView(
                goals: dataManager.nutritionGoals,
                onSave: { goals in
                    dataManager.updateNutritionGoals(goals)
                }
            )
        }
        .sheet(isPresented: $showingScanner) {
            NutritionLabelScanner(dataManager: dataManager)
        }
        .sheet(isPresented: $showingBarcodeScanner) {
            BarcodeScanner(dataManager: dataManager)
        }
        .sheet(isPresented: $showingHistory) {
            NutritionHistoryView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingCustomTemplates) {
            CustomNutritionTemplatesView(dataManager: dataManager)
        }
        .sheet(isPresented: $showingTodaysEntries) {
            TodaysEntriesView(dataManager: dataManager, selectedDate: selectedDate)
        }
        .sheet(isPresented: $showingQuickInput) {
            QuickInputView(dataManager: dataManager, selectedDate: selectedDate)
        }
        .sheet(isPresented: $showingUnifiedEdit) {
            UnifiedEditView(dataManager: dataManager, isPresented: $showingUnifiedEdit, selectedDate: selectedDate)
        }
        .alert("Success", isPresented: $showingSuccessPopup) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Top gradient header
            LinearGradient(
                colors: [
                    Color.green.opacity(0.9),
                    Color.green.opacity(0.7),
                    Color.blue.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 65)
            .overlay(
                VStack(spacing: 0) {
                    // Top section with app name
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("PureMetrics")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            
                            Text("Nutrition")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(selectedDate, style: .date)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            
                            Text(selectedDate, style: .time)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    
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
    
    // MARK: - Date Selector
    
    private var dateSelector: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Select Date")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    selectedDate = Date()
                }) {
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
                .onChange(of: selectedDate) { newDate in
                    // Load nutrition entries for the selected date
                    dataManager.loadNutritionEntriesForDate(newDate)
                }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    
    // MARK: - Today's Summary Section
    
    private var todaysSummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Edit") {
                    showingUnifiedEdit = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            NutritionSummaryCard(summary: todaysSummary, dataManager: dataManager)
            
            // Today's Foods Button
            Button(action: {
                showingTodaysEntries = true
            }) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                    
                    Text("View Today's Foods")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.indigo, .indigo.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Quick Add Section
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Add")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach([QuickInputType.calories, .water, .protein, .fiber, .sodium, .carbs], id: \.self) { type in
                    QuickAddButton(
                        icon: type.icon,
                        title: type.rawValue,
                        value: getValueForType(type),
                        unit: type.unit,
                        color: type.color
                    ) {
                        showQuickInput(for: type)
                    }
                }
            }
            
            // Inline Input Section
            if showingQuickInput {
                inlineInputSection
            }
        }
    }
    
    // MARK: - Inline Input Section
    
    private var inlineInputSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: selectedQuickInputType.icon)
                    .font(.title2)
                    .foregroundColor(selectedQuickInputType.color)
                
                Text("Add \(selectedQuickInputType.rawValue)")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Cancel") {
                    showingQuickInput = false
                    quickInputValue = ""
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            HStack(spacing: 12) {
                if selectedQuickInputType == .water {
                    // Water-specific input with common fluid oz options
                    VStack(spacing: 8) {
                        // Quick selection buttons for common amounts
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach([8, 16, 32, 64], id: \.self) { amount in
                                Button("\(amount) oz") {
                                    quickInputValue = "\(amount)"
                                }
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedQuickInputType.color)
                                )
                            }
                        }
                        
                        // Custom input field
                        HStack(spacing: 8) {
                            TextField("0", text: $quickInputValue)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(selectedQuickInputType.color.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(selectedQuickInputType.color.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            
                            Text(selectedQuickInputType.unit)
                                .font(.headline)
                                .foregroundColor(selectedQuickInputType.color)
                                .frame(minWidth: 30)
                        }
                    }
                } else {
                    // Standard input for other types
                    TextField("0", text: $quickInputValue)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedQuickInputType.color.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedQuickInputType.color.opacity(0.3), lineWidth: 2)
                                )
                        )
                    
                    Text(selectedQuickInputType.unit)
                        .font(.headline)
                        .foregroundColor(selectedQuickInputType.color)
                        .frame(minWidth: 30)
                }
                
                Button(action: saveQuickEntry) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [selectedQuickInputType.color, selectedQuickInputType.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .disabled(quickInputValue.isEmpty || Double(quickInputValue) == nil)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private func getValueForType(_ type: QuickInputType) -> Double {
        let summary = todaysSummary
        switch type {
        case .calories: return summary.totalCalories
        case .water: return summary.totalWater
        case .protein: return summary.totalProtein
        case .fiber: return summary.totalFiber
        case .sodium: return summary.totalSodium
        case .carbs: return summary.totalCarbohydrates
        case .fat: return summary.totalFat
        case .cholesterol: return summary.totalCholesterol
        }
    }
    
    // MARK: - Recent Entries Section
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Entries")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    showingHistory = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if todaysEntries.isEmpty {
                emptyEntriesView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(todaysEntries.prefix(3), id: \.id) { entry in
                        NutritionEntryCard(entry: entry, dataManager: dataManager)
                    }
                }
            }
        }
    }
    
    // MARK: - Today's Entries Section
    
    private var todaysEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Entries")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !todaysEntries.isEmpty {
                    Button("View All") {
                        showingTodaysEntries = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }
            
            if todaysEntries.isEmpty {
                emptyEntriesView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(todaysEntries.prefix(5), id: \.id) { entry in
                        NutritionEntryCard(entry: entry, dataManager: dataManager)
                    }
                    
                    if todaysEntries.count > 5 {
                        Button(action: {
                            showingTodaysEntries = true
                        }) {
                            HStack {
                                Text("View \(todaysEntries.count - 5) more entries")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Food Access Section
    
    private var foodAccessSection: some View {
        VStack(spacing: 8) {
            Text("Add Food")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                // Scan Barcode
                Button(action: {
                    showingBarcodeScanner = true
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("Scan Barcode")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Quick scan")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 75)
                    .background(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
                
                // Quick Add
                Button(action: {
                    showingQuickInput = true
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("Quick Add")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Fast entry")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 75)
                    .background(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
                
                // Custom Templates
                Button(action: {
                    showingCustomTemplates = true
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("My Foods")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Saved foods")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 75)
                    .background(
                        LinearGradient(
                            colors: [.purple, .purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
                
                // Manual Entry
                Button(action: {
                    showingAddEntry = true
                }) {
                    VStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text("Manual Entry")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("Type values")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 75)
                    .background(
                        LinearGradient(
                            colors: [.orange, .orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(16)
                }
                
            }
        }
        .padding(.vertical, 8)
    }
    
    
    // MARK: - Empty Views
    
    private var emptySummaryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No Entries Today")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Start tracking your nutrition by adding your first entry")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    private var emptyEntriesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
            
            Text("No entries yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    
    // MARK: - Functions
    
    private func addQuickEntry(value: Double) {
        let entry = NutritionEntry(
            date: selectedDate,
            calories: selectedQuickInputType == .calories ? value : 0,
            protein: selectedQuickInputType == .protein ? value : 0,
            carbohydrates: selectedQuickInputType == .carbs ? value : 0,
            fat: selectedQuickInputType == .fat ? value : 0,
            sodium: selectedQuickInputType == .sodium ? value : 0,
            sugar: 0,
            fiber: selectedQuickInputType == .fiber ? value : 0,
            water: selectedQuickInputType == .water ? value : 0,
            notes: "Quick entry: \(selectedQuickInputType.rawValue)"
        )
        dataManager.addNutritionEntry(entry)
        successMessage = "\(selectedQuickInputType.rawValue) added to summary!"
        showingSuccessPopup = true
        quickInputValue = ""
    }
    
    private func showQuickInput(for type: QuickInputType) {
        selectedQuickInputType = type
        quickInputValue = ""
        showingQuickInput = true
    }
    
    private func saveQuickEntry() {
        guard let value = Double(quickInputValue), value > 0 else { return }
        addQuickEntry(value: value)
        showingQuickInput = false
        quickInputValue = ""
    }
    
    private func clearDataFrom231() {
        let calendar = Calendar.current
        let today = Date()
        let targetTime = calendar.date(bySettingHour: 14, minute: 31, second: 0, of: today) ?? today
        
        dataManager.clearNutritionDataFromTime(targetTime)
    }
    
    private func clearAllNutritionData() {
        dataManager.clearAllNutritionData()
    }
    
    // MARK: - Computed Properties
    
    private var todaysEntries: [NutritionEntry] {
        let allEntries = dataManager.nutritionEntries
        let filtered = allEntries.filter { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: selectedDate)
        }
        print("=== NUTRITION VIEW DEBUG ===")
        print("Total nutrition entries: \(allEntries.count)")
        print("Today's entries: \(filtered.count)")
        print("Selected date: \(selectedDate)")
        if !allEntries.isEmpty {
            print("Sample entry date: \(allEntries.first?.date ?? Date())")
        }
        return filtered
    }
    
    private var todaysSummary: NutritionSummary {
        let entries = todaysEntries
        return NutritionSummary(entries: entries, goals: dataManager.nutritionGoals, date: selectedDate)
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let icon: String
    let title: String
    let value: Double
    let unit: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(Int(value)) \(unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Nutrition Entry Card

struct NutritionEntryCard: View {
    let entry: NutritionEntry
    @ObservedObject var dataManager: BPDataManager
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if let label = entry.label {
                        HStack(spacing: 4) {
                            if let nutritionLabel = dataManager.nutritionLabelManager.getLabelByName(label) {
                                Image(systemName: nutritionLabel.icon)
                                    .font(.caption2)
                                    .foregroundColor(nutritionLabel.color)
                            }
                            Text(label)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                HStack(spacing: 16) {
                    if entry.calories > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(entry.caloriesString)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Text("calories")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if entry.water > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(entry.waterString)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Text("water")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Edit and Delete Buttons
                HStack(spacing: 8) {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .sheet(isPresented: $showingEditSheet) {
            EditNutritionEntryView(
                entry: entry,
                onSave: { updatedEntry in
                    dataManager.updateNutritionEntry(updatedEntry)
                    showingEditSheet = false
                }
            )
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataManager.deleteNutritionEntry(entry)
            }
        } message: {
            Text("Are you sure you want to delete this nutrition entry? This action cannot be undone.")
        }
    }
}



#Preview {
    NutritionView(dataManager: BPDataManager())
}
