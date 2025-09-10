import Foundation

// MARK: - Nutrition Entry Model

struct NutritionEntry: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
    let protein: Double // in grams
    let carbohydrates: Double // in grams
    let fat: Double // in grams
    let sodium: Double // in milligrams
    let sugar: Double // in grams
    let fiber: Double // in grams
    let water: Double // in ounces
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case date, calories, protein, carbohydrates, fat, sodium, sugar, fiber, water, notes
    }
    
    init(date: Date = Date(), calories: Double = 0, protein: Double = 0, carbohydrates: Double = 0, fat: Double = 0, sodium: Double = 0, sugar: Double = 0, fiber: Double = 0, water: Double = 0, notes: String? = nil) {
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.sodium = sodium
        self.sugar = sugar
        self.fiber = fiber
        self.water = water
        self.notes = notes
    }
    
    // MARK: - Computed Properties
    
    var totalMacros: Double {
        return protein + carbohydrates + fat
    }
    
    var proteinPercentage: Double {
        guard totalMacros > 0 else { return 0 }
        return (protein * 4) / (calories > 0 ? calories : 1) * 100
    }
    
    var carbPercentage: Double {
        guard totalMacros > 0 else { return 0 }
        return (carbohydrates * 4) / (calories > 0 ? calories : 1) * 100
    }
    
    var fatPercentage: Double {
        guard totalMacros > 0 else { return 0 }
        return (fat * 9) / (calories > 0 ? calories : 1) * 100
    }
    
    var sodiumInGrams: Double {
        return sodium / 1000
    }
    
    var sugarInTeaspoons: Double {
        return sugar / 4.2 // 1 teaspoon = 4.2 grams
    }
    
    // MARK: - Display Strings
    
    var caloriesString: String {
        return "\(Int(calories)) cal"
    }
    
    var proteinString: String {
        return "\(Int(protein))g"
    }
    
    var carbsString: String {
        return "\(Int(carbohydrates))g"
    }
    
    var fatString: String {
        return "\(Int(fat))g"
    }
    
    var sodiumString: String {
        if sodium >= 1000 {
            return "\(String(format: "%.1f", sodium / 1000))g"
        } else {
            return "\(Int(sodium))mg"
        }
    }
    
    var sugarString: String {
        return "\(Int(sugar))g"
    }
    
    var fiberString: String {
        return "\(Int(fiber))g"
    }
    
    var waterString: String {
        return "\(Int(water)) oz"
    }
}

// MARK: - Nutrition Goals Model

struct NutritionGoals: Codable {
    var dailyCalories: Double = 2000
    var dailyProtein: Double = 150 // grams
    var dailyCarbohydrates: Double = 250 // grams
    var dailyFat: Double = 65 // grams
    var dailySodium: Double = 2300 // milligrams
    var dailySugar: Double = 50 // grams
    var dailyFiber: Double = 25 // grams
    var dailyWater: Double = 64 // ounces
    
    enum CodingKeys: String, CodingKey {
        case dailyCalories, dailyProtein, dailyCarbohydrates, dailyFat, dailySodium, dailySugar, dailyFiber, dailyWater
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
    let totalFiber: Double
    let totalWater: Double
    let entryCount: Int
    let goals: NutritionGoals
    
    init(entries: [NutritionEntry], goals: NutritionGoals, date: Date = Date()) {
        self.date = date
        self.totalCalories = entries.reduce(0) { $0 + $1.calories }
        self.totalProtein = entries.reduce(0) { $0 + $1.protein }
        self.totalCarbohydrates = entries.reduce(0) { $0 + $1.carbohydrates }
        self.totalFat = entries.reduce(0) { $0 + $1.fat }
        self.totalSodium = entries.reduce(0) { $0 + $1.sodium }
        self.totalSugar = entries.reduce(0) { $0 + $1.sugar }
        self.totalFiber = entries.reduce(0) { $0 + $1.fiber }
        self.totalWater = entries.reduce(0) { $0 + $1.water }
        self.entryCount = entries.count
        self.goals = goals
    }
    
    // MARK: - Goal Progress
    
    func progress(for goal: Double, actual: Double) -> Double {
        guard goal > 0 else { return 0 }
        return min(actual / goal, 1.0)
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
    
    var fiberProgress: Double {
        return progress(for: goals.dailyFiber, actual: totalFiber)
    }
    
    var waterProgress: Double {
        return progress(for: goals.dailyWater, actual: totalWater)
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
