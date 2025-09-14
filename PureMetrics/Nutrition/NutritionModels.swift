import Foundation
import SwiftUI

// MARK: - Nutrition Entry Model

struct NutritionEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let calories: Double
    let protein: Double // in grams
    let carbohydrates: Double // in grams
    let fat: Double // in grams
    let sodium: Double // in milligrams
    let sugar: Double // in grams (total sugar)
    let naturalSugar: Double? // in grams (natural sugar from fruits, dairy, etc.)
    let addedSugar: Double // in grams (added/processed sugar)
    let fiber: Double // in grams
    let cholesterol: Double // in milligrams
    let water: Double // in ounces
    let notes: String?
    let label: String?
    
    enum CodingKeys: String, CodingKey {
        case id, date, calories, protein, carbohydrates, fat, sodium, sugar, naturalSugar, addedSugar, fiber, cholesterol, water, notes, label
    }
    
    init(date: Date = Date(), calories: Double = 0, protein: Double = 0, carbohydrates: Double = 0, fat: Double = 0, sodium: Double = 0, sugar: Double = 0, naturalSugar: Double? = nil, addedSugar: Double = 0, fiber: Double = 0, cholesterol: Double = 0, water: Double = 0, notes: String? = nil, label: String? = nil) {
        self.id = UUID() // Generate new ID for new entries
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.sodium = sodium
        self.sugar = sugar
        self.naturalSugar = naturalSugar
        self.addedSugar = addedSugar
        self.fiber = fiber
        self.cholesterol = cholesterol
        self.water = water
        self.notes = notes
        self.label = label
    }
    
    // Custom initializer for updating existing entries (preserves ID)
    init(id: UUID, date: Date, calories: Double, protein: Double, carbohydrates: Double, fat: Double, sodium: Double, sugar: Double, naturalSugar: Double?, addedSugar: Double, fiber: Double, cholesterol: Double, water: Double, notes: String?, label: String?) {
        self.id = id
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.sodium = sodium
        self.sugar = sugar
        self.naturalSugar = naturalSugar
        self.addedSugar = addedSugar
        self.fiber = fiber
        self.cholesterol = cholesterol
        self.water = water
        self.notes = notes
        self.label = label
    }
    
    // MARK: - Computed Properties
    
    var totalMacros: Double {
        return protein + carbohydrates + fat
    }
    
    var proteinPercentage: Double {
        guard totalMacros > 0 && calories > 0 && calories.isFinite && !calories.isNaN else { return 0 }
        let percentage = (protein * 4) / calories * 100
        return percentage.isFinite && !percentage.isNaN ? percentage : 0
    }
    
    var carbPercentage: Double {
        guard totalMacros > 0 && calories > 0 && calories.isFinite && !calories.isNaN else { return 0 }
        let percentage = (carbohydrates * 4) / calories * 100
        return percentage.isFinite && !percentage.isNaN ? percentage : 0
    }
    
    var fatPercentage: Double {
        guard totalMacros > 0 && calories > 0 && calories.isFinite && !calories.isNaN else { return 0 }
        let percentage = (fat * 9) / calories * 100
        return percentage.isFinite && !percentage.isNaN ? percentage : 0
    }
    
    var sodiumInGrams: Double {
        return sodium / 1000
    }
    
    var sugarInTeaspoons: Double {
        return sugar / 4.2 // 1 teaspoon = 4.2 grams
    }
    
    // MARK: - Display Strings
    
    private func safeInt(_ value: Double) -> Int {
        guard value.isFinite && !value.isNaN else { return 0 }
        return Int(value)
    }
    
    private func safeDouble(_ value: Double) -> Double {
        guard value.isFinite && !value.isNaN else { return 0 }
        return value
    }
    
    var caloriesString: String {
        return "\(safeInt(calories)) cal"
    }
    
    var proteinString: String {
        return "\(safeInt(protein))g"
    }
    
    var carbsString: String {
        return "\(safeInt(carbohydrates))g"
    }
    
    var fatString: String {
        return "\(safeInt(fat))g"
    }
    
    var sodiumString: String {
        let safeSodium = safeDouble(sodium)
        if safeSodium >= 1000 {
            return "\(String(format: "%.1f", safeSodium / 1000))g"
        } else {
            return "\(safeInt(safeSodium))mg"
        }
    }
    
    var sugarString: String {
        return "\(safeInt(sugar))g"
    }
    
    var naturalSugarString: String {
        return "\(safeInt(naturalSugar ?? 0))g"
    }
    
    var addedSugarString: String {
        return "\(safeInt(addedSugar))g"
    }
    
    var fiberString: String {
        return "\(safeInt(fiber))g"
    }
    
    var waterString: String {
        return "\(safeInt(water)) oz"
    }
    
    var cholesterolString: String {
        return "\(safeInt(cholesterol))mg"
    }
}

// MARK: - Nutrition Goals Model

struct NutritionGoals: Codable {
    var dailyCalories: Double = 2000
    var dailyProtein: Double = 150 // grams
    var dailyCarbohydrates: Double = 250 // grams
    var dailyFat: Double = 65 // grams
    var dailySodium: Double = 2300 // milligrams
    var dailySugar: Double = 50 // grams (total sugar)
    var dailyNaturalSugar: Double = 30 // grams (natural sugar from fruits, dairy, etc.)
    var dailyAddedSugar: Double = 20 // grams (added/processed sugar)
    var dailyFiber: Double = 25 // grams
    var dailyCholesterol: Double = 300 // milligrams
    var dailyWater: Double = 64 // ounces
    
    enum CodingKeys: String, CodingKey {
        case dailyCalories, dailyProtein, dailyCarbohydrates, dailyFat, dailySodium, dailySugar, dailyNaturalSugar, dailyAddedSugar, dailyFiber, dailyCholesterol, dailyWater
    }
    
    // MARK: - Computed Properties
    
    var proteinCalories: Double {
        return dailyProtein * 4
    }
    
    var carbCalories: Double {
        return dailyCarbohydrates * 4
    }
    
    var fatCalories: Double {
        return dailyFat * 9
    }
    
    var totalMacroCalories: Double {
        return proteinCalories + carbCalories + fatCalories
    }
    
    var sodiumInGrams: Double {
        return dailySodium / 1000
    }
    
    var sugarInTeaspoons: Double {
        return dailySugar / 4.2
    }
}

// MARK: - Nutrition Summary Model

struct NutritionSummary: Codable {
    let date: Date
    let totalCalories: Double
    let totalProtein: Double
    let totalCarbohydrates: Double
    let totalFat: Double
    let totalSodium: Double
    let totalSugar: Double
    let totalNaturalSugar: Double
    let totalAddedSugar: Double
    let totalFiber: Double
    let totalCholesterol: Double
    let totalWater: Double
    let entryCount: Int
    let goals: NutritionGoals
    
    init(entries: [NutritionEntry], goals: NutritionGoals, date: Date = Date()) {
        self.date = date
        self.totalCalories = entries.reduce(0) { $0 + ($1.calories.isFinite && !$1.calories.isNaN ? $1.calories : 0) }
        self.totalProtein = entries.reduce(0) { $0 + ($1.protein.isFinite && !$1.protein.isNaN ? $1.protein : 0) }
        self.totalCarbohydrates = entries.reduce(0) { $0 + ($1.carbohydrates.isFinite && !$1.carbohydrates.isNaN ? $1.carbohydrates : 0) }
        self.totalFat = entries.reduce(0) { $0 + ($1.fat.isFinite && !$1.fat.isNaN ? $1.fat : 0) }
        self.totalSodium = entries.reduce(0) { $0 + ($1.sodium.isFinite && !$1.sodium.isNaN ? $1.sodium : 0) }
        self.totalSugar = entries.reduce(0) { $0 + ($1.sugar.isFinite && !$1.sugar.isNaN ? $1.sugar : 0) }
        self.totalNaturalSugar = entries.reduce(0) { $0 + (($1.naturalSugar ?? 0).isFinite && !($1.naturalSugar ?? 0).isNaN ? ($1.naturalSugar ?? 0) : 0) }
        self.totalAddedSugar = entries.reduce(0) { $0 + ($1.addedSugar.isFinite && !$1.addedSugar.isNaN ? $1.addedSugar : 0) }
        self.totalFiber = entries.reduce(0) { $0 + ($1.fiber.isFinite && !$1.fiber.isNaN ? $1.fiber : 0) }
        self.totalCholesterol = entries.reduce(0) { $0 + ($1.cholesterol.isFinite && !$1.cholesterol.isNaN ? $1.cholesterol : 0) }
        self.totalWater = entries.reduce(0) { $0 + ($1.water.isFinite && !$1.water.isNaN ? $1.water : 0) }
        self.entryCount = entries.count
        self.goals = goals
    }
    
    // MARK: - Goal Progress
    
    func progress(for goal: Double, actual: Double) -> Double {
        guard goal > 0 && goal.isFinite && !goal.isNaN && actual.isFinite && !actual.isNaN else { return 0 }
        let progress = min(actual / goal, 1.0)
        return progress.isFinite && !progress.isNaN ? progress : 0
    }
    
    var caloriesProgress: Double {
        return progress(for: goals.dailyCalories, actual: totalCalories)
    }
    
    var proteinProgress: Double {
        return progress(for: goals.dailyProtein, actual: totalProtein)
    }
    
    var carbsProgress: Double {
        return progress(for: goals.dailyCarbohydrates, actual: totalCarbohydrates)
    }
    
    var fatProgress: Double {
        return progress(for: goals.dailyFat, actual: totalFat)
    }
    
    var sodiumProgress: Double {
        return progress(for: goals.dailySodium, actual: totalSodium)
    }
    
    var sugarProgress: Double {
        return progress(for: goals.dailySugar, actual: totalSugar)
    }
    
    var naturalSugarProgress: Double {
        return progress(for: goals.dailyNaturalSugar, actual: totalNaturalSugar)
    }
    
    var addedSugarProgress: Double {
        return progress(for: goals.dailyAddedSugar, actual: totalAddedSugar)
    }
    
    var fiberProgress: Double {
        return progress(for: goals.dailyFiber, actual: totalFiber)
    }
    
    var cholesterolProgress: Double {
        return progress(for: goals.dailyCholesterol, actual: totalCholesterol)
    }
    
    var waterProgress: Double {
        return progress(for: goals.dailyWater, actual: totalWater)
    }
}

// MARK: - Nutrition Label Management

class NutritionLabelManager: ObservableObject {
    @Published var availableLabels: [NutritionLabel] = []
    @Published var customLabels: [String] = []
    
    private let userDefaults = UserDefaults.standard
    private let customLabelsKey = "nutrition_custom_labels"
    
    init() {
        loadCustomLabels()
        setupDefaultLabels()
    }
    
    private func setupDefaultLabels() {
        let defaultLabels = [
            NutritionLabel(name: "Breakfast", color: .orange, icon: "sunrise.fill"),
            NutritionLabel(name: "Lunch", color: .blue, icon: "sun.max.fill"),
            NutritionLabel(name: "Dinner", color: .purple, icon: "moon.fill"),
            NutritionLabel(name: "Snack", color: .green, icon: "leaf.fill"),
            NutritionLabel(name: "Pre-Workout", color: .red, icon: "figure.strengthtraining.traditional"),
            NutritionLabel(name: "Post-Workout", color: .mint, icon: "figure.walk"),
            NutritionLabel(name: "Hydration", color: .cyan, icon: "drop.fill"),
            NutritionLabel(name: "Supplements", color: .yellow, icon: "pills.fill")
        ]
        
        availableLabels = defaultLabels + customLabels.map { 
            NutritionLabel(name: $0, color: .gray, icon: "tag.fill") 
        }
    }
    
    func addCustomLabel(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty,
              !customLabels.contains(trimmedName),
              !availableLabels.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) else {
            return
        }
        
        customLabels.append(trimmedName)
        saveCustomLabels()
        setupDefaultLabels()
    }
    
    func removeCustomLabel(_ name: String) {
        customLabels.removeAll { $0 == name }
        saveCustomLabels()
        setupDefaultLabels()
    }
    
    private func saveCustomLabels() {
        userDefaults.set(customLabels, forKey: customLabelsKey)
    }
    
    private func loadCustomLabels() {
        customLabels = userDefaults.stringArray(forKey: customLabelsKey) ?? []
    }
    
    func getLabelByName(_ name: String) -> NutritionLabel? {
        return availableLabels.first { $0.name == name }
    }
}

// MARK: - Nutrition Label Model

struct NutritionLabel: Codable, Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let icon: String
    
    enum CodingKeys: String, CodingKey {
        case name, color, icon
    }
    
    init(name: String, color: Color, icon: String) {
        self.name = name
        self.color = color
        self.icon = icon
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        
        // Decode color from hex string
        let colorHex = try container.decode(String.self, forKey: .color)
        if let color = Color(hex: colorHex) {
            self.color = color
        } else {
            self.color = .gray
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(color.toHex(), forKey: .color)
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return "#000000"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// MARK: - Custom Nutrition Template

struct CustomNutritionTemplate: Codable, Identifiable {
    let id: UUID
    let name: String
    let calories: Double
    let protein: Double
    let carbohydrates: Double
    let fat: Double
    let sodium: Double
    let sugar: Double
    let naturalSugar: Double
    let addedSugar: Double
    let fiber: Double
    let cholesterol: Double
    let water: Double
    let servingSize: String
    let category: String
    let notes: String?
    let dateCreated: Date
    let lastUsed: Date?
    
    init(name: String, calories: Double = 0, protein: Double = 0, carbohydrates: Double = 0, fat: Double = 0, sodium: Double = 0, sugar: Double = 0, naturalSugar: Double = 0, addedSugar: Double = 0, fiber: Double = 0, cholesterol: Double = 0, water: Double = 0, servingSize: String = "1 serving", category: String = "General", notes: String? = nil) {
        self.id = UUID()
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.sodium = sodium
        self.sugar = sugar
        self.naturalSugar = naturalSugar
        self.addedSugar = addedSugar
        self.fiber = fiber
        self.cholesterol = cholesterol
        self.water = water
        self.servingSize = servingSize
        self.category = category
        self.notes = notes
        self.dateCreated = Date()
        self.lastUsed = nil
    }
    
    // Initializer for updating existing templates (preserves ID and dateCreated)
    init(id: UUID, name: String, calories: Double, protein: Double, carbohydrates: Double, fat: Double, sodium: Double, sugar: Double, naturalSugar: Double, addedSugar: Double, fiber: Double, cholesterol: Double, water: Double, servingSize: String, category: String, notes: String?, dateCreated: Date, lastUsed: Date?) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.sodium = sodium
        self.sugar = sugar
        self.naturalSugar = naturalSugar
        self.addedSugar = addedSugar
        self.fiber = fiber
        self.cholesterol = cholesterol
        self.water = water
        self.servingSize = servingSize
        self.category = category
        self.notes = notes
        self.dateCreated = dateCreated
        self.lastUsed = lastUsed
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, calories, protein, carbohydrates, fat, sodium, sugar, naturalSugar, addedSugar, fiber, cholesterol, water, servingSize, category, notes, dateCreated, lastUsed
    }
    
    // Convert template to NutritionEntry
    func toNutritionEntry() -> NutritionEntry {
        return NutritionEntry(
            date: Date(),
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            sodium: sodium,
            sugar: sugar,
            naturalSugar: naturalSugar,
            addedSugar: addedSugar,
            fiber: fiber,
            cholesterol: cholesterol,
            water: water,
            notes: notes,
            label: name
        )
    }
}

// MARK: - Nutrition Template Categories

enum NutritionTemplateCategory: String, CaseIterable, Codable {
    case general = "General"
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snacks = "Snacks"
    case beverages = "Beverages"
    case protein = "Protein"
    case vegetables = "Vegetables"
    case fruits = "Fruits"
    case grains = "Grains"
    case dairy = "Dairy"
    case supplements = "Supplements"
    
    var icon: String {
        switch self {
        case .general: return "star.fill"
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snacks: return "leaf.fill"
        case .beverages: return "drop.fill"
        case .protein: return "scalemass.fill"
        case .vegetables: return "carrot.fill"
        case .fruits: return "apple.logo"
        case .grains: return "square.grid.3x2.fill"
        case .dairy: return "circle.circle.fill"
        case .supplements: return "pills.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .general: return .gray
        case .breakfast: return .orange
        case .lunch: return .blue
        case .dinner: return .purple
        case .snacks: return .green
        case .beverages: return .cyan
        case .protein: return .red
        case .vegetables: return .green
        case .fruits: return .pink
        case .grains: return .yellow
        case .dairy: return .blue
        case .supplements: return .mint
        }
    }
}

// MARK: - Nutrition Input Field

struct NutritionInputField: Codable, Identifiable {
    let id = UUID()
    var value: Double = 0
    let unit: String
    let label: String
    let icon: String
    let color: String
    
    init(value: Double = 0, unit: String, label: String, icon: String, color: String) {
        self.value = value
        self.unit = unit
        self.label = label
        self.icon = icon
        self.color = color
    }
    
    enum CodingKeys: String, CodingKey {
        case value, unit, label, icon, color
    }
}
