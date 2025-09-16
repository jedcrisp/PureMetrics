import Foundation
import SwiftUI

// MARK: - BMR Profile Model

struct BMRProfile: Codable {
    var age: Int = 25
    var weight: Double = 70.0 // in kg
    var height: Double = 170.0 // in cm
    var gender: Gender = .male
    var activityLevel: ActivityLevel = .moderate
    var dateCreated: Date = Date()
    var lastUpdated: Date = Date()
    
    enum Gender: String, CaseIterable, Codable {
        case male = "male"
        case female = "female"
        
        var displayName: String {
            switch self {
            case .male: return "Male"
            case .female: return "Female"
            }
        }
    }
    
    enum ActivityLevel: String, CaseIterable, Codable {
        case sedentary = "sedentary"
        case light = "light"
        case moderate = "moderate"
        case active = "active"
        case veryActive = "very_active"
        
        var displayName: String {
            switch self {
            case .sedentary: return "Sedentary"
            case .light: return "Light Activity"
            case .moderate: return "Moderate Activity"
            case .active: return "Active"
            case .veryActive: return "Very Active"
            }
        }
        
        var description: String {
            switch self {
            case .sedentary: return "Little to no exercise"
            case .light: return "Light exercise 1-3 days/week"
            case .moderate: return "Moderate exercise 3-5 days/week"
            case .active: return "Heavy exercise 6-7 days/week"
            case .veryActive: return "Very heavy exercise, physical job"
            }
        }
        
        var multiplier: Double {
            switch self {
            case .sedentary: return 1.2
            case .light: return 1.375
            case .moderate: return 1.55
            case .active: return 1.725
            case .veryActive: return 1.9
            }
        }
    }
    
    // MARK: - BMR Calculations
    
    /// Calculate BMR using Mifflin-St Jeor Equation
    var bmr: Double {
        let baseBMR: Double
        
        switch gender {
        case .male:
            baseBMR = (10 * weight) + (6.25 * height) - (5 * Double(age)) + 5
        case .female:
            baseBMR = (10 * weight) + (6.25 * height) - (5 * Double(age)) - 161
        }
        
        return max(baseBMR, 1000) // Minimum BMR of 1000 calories
    }
    
    /// Calculate Total Daily Energy Expenditure (TDEE)
    var tdee: Double {
        return bmr * activityLevel.multiplier
    }
    
    /// Calculate calories for weight loss (500 calorie deficit)
    var weightLossCalories: Double {
        return max(tdee - 500, bmr) // Don't go below BMR
    }
    
    /// Calculate calories for weight gain (500 calorie surplus)
    var weightGainCalories: Double {
        return tdee + 500
    }
    
    /// Calculate calories for maintenance
    var maintenanceCalories: Double {
        return tdee
    }
    
    // MARK: - Macro Recommendations
    
    var proteinRecommendation: Double {
        // 1.6-2.2g per kg body weight for active individuals
        return weight * 1.8
    }
    
    var fatRecommendation: Double {
        // 25-35% of total calories
        let fatCalories = tdee * 0.3
        return fatCalories / 9 // Convert calories to grams
    }
    
    var carbRecommendation: Double {
        // Remaining calories after protein and fat
        let proteinCalories = proteinRecommendation * 4
        let fatCalories = fatRecommendation * 9
        let remainingCalories = tdee - proteinCalories - fatCalories
        return max(remainingCalories / 4, 0) // Convert calories to grams
    }
    
    // MARK: - Water Recommendation
    
    var waterRecommendation: Double {
        // 35ml per kg body weight, converted to ounces
        let mlPerKg = 35.0
        let totalML = weight * mlPerKg
        return totalML / 29.5735 // Convert ml to ounces
    }
    
    // MARK: - Validation
    
    var isValid: Bool {
        return age >= 15 && age <= 100 &&
               weight >= 30 && weight <= 300 &&
               height >= 100 && height <= 250
    }
    
    // MARK: - Display Properties
    
    var weightInPounds: Double {
        return weight * 2.20462
    }
    
    var heightInFeet: (feet: Int, inches: Int) {
        let totalInches = height / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return (feet, inches)
    }
    
    var heightInInches: Double {
        return height / 2.54
    }
    
    // MARK: - Unit Conversion Helpers
    
    mutating func setWeightInPounds(_ pounds: Double) {
        weight = pounds / 2.20462
    }
    
    mutating func setHeightInFeetAndInches(feet: Int, inches: Int) {
        let totalInches = Double(feet * 12 + inches)
        height = totalInches * 2.54
    }
    
    mutating func setHeightInInches(_ inches: Double) {
        height = inches * 2.54
    }
}

// MARK: - BMR Manager

class BMRManager: ObservableObject {
    @Published var profile: BMRProfile = BMRProfile()
    @Published var isWeightSyncingEnabled: Bool = false
    
    private let userDefaults = UserDefaults.standard
    private let profileKey = "BMRProfile"
    private let weightSyncKey = "BMRWeightSyncEnabled"
    
    init() {
        loadProfile()
        loadWeightSyncPreference()
    }
    
    func updateProfile(_ newProfile: BMRProfile) {
        profile = newProfile
        saveProfile()
    }
    
    func resetProfile() {
        profile = BMRProfile()
        saveProfile()
    }
    
    func toggleWeightSyncing() {
        isWeightSyncingEnabled.toggle()
        saveWeightSyncPreference()
    }
    
    func syncWeightFromHealthKit(_ weightInPounds: Double) {
        guard isWeightSyncingEnabled else { return }
        
        // Convert pounds to kg for BMR calculation
        let weightInKg = weightInPounds * 0.453592
        
        // Only update if weight has changed significantly (more than 0.1 kg)
        if abs(profile.weight - weightInKg) > 0.1 {
            profile.weight = weightInKg
            profile.lastUpdated = Date()
            saveProfile()
            print("BMR Profile updated with new weight: \(String(format: "%.1f", weightInPounds)) lbs (\(String(format: "%.1f", weightInKg)) kg)")
        }
    }
    
    private func saveProfile() {
        do {
            let data = try JSONEncoder().encode(profile)
            userDefaults.set(data, forKey: profileKey)
        } catch {
            print("Failed to save BMR profile: \(error)")
        }
    }
    
    private func loadProfile() {
        guard let data = userDefaults.data(forKey: profileKey) else { return }
        
        do {
            profile = try JSONDecoder().decode(BMRProfile.self, from: data)
        } catch {
            print("Failed to load BMR profile: \(error)")
            profile = BMRProfile()
        }
    }
    
    private func saveWeightSyncPreference() {
        userDefaults.set(isWeightSyncingEnabled, forKey: weightSyncKey)
    }
    
    private func loadWeightSyncPreference() {
        isWeightSyncingEnabled = userDefaults.bool(forKey: weightSyncKey)
    }
    
    // MARK: - Quick Setup Helpers
    
    func setupForWeightLoss() {
        // This would be called when user wants to set up for weight loss
        // The actual calorie goals are calculated dynamically
    }
    
    func setupForWeightGain() {
        // This would be called when user wants to set up for weight gain
        // The actual calorie goals are calculated dynamically
    }
    
    func setupForMaintenance() {
        // This would be called when user wants to set up for maintenance
        // The actual calorie goals are calculated dynamically
    }
}

// MARK: - BMR Profile Input View

struct BMRProfileInputView: View {
    @ObservedObject var bmrManager: BMRManager
    @Environment(\.presentationMode) var presentationMode
    @State private var tempProfile: BMRProfile
    @State private var showingUnitPicker = false
    @State private var isMetric = true
    
    init(bmrManager: BMRManager) {
        self.bmrManager = bmrManager
        self._tempProfile = State(initialValue: bmrManager.profile)
        // Initialize unit preference - default to metric if not set
        self._isMetric = State(initialValue: !UserDefaults.standard.bool(forKey: "prefersImperialUnits"))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    // Age
                    HStack {
                        Text("Age")
                        Spacer()
                        TextField("25", value: $tempProfile.age, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("years")
                            .foregroundColor(.secondary)
                    }
                    
                    // Gender
                    Picker("Gender", selection: $tempProfile.gender) {
                        ForEach(BMRProfile.Gender.allCases, id: \.self) { gender in
                            Text(gender.displayName).tag(gender)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Physical Measurements")) {
                    // Unit Toggle
                    HStack {
                        Text("Units")
                        Spacer()
                        Picker("Units", selection: $isMetric) {
                            Text("Metric").tag(true)
                            Text("Imperial").tag(false)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 150)
                    }
                    
                    // Weight
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Weight")
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            if isMetric {
                                TextField("70", value: $tempProfile.weight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("kg")
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 30)
                            } else {
                                TextField("154", value: Binding(
                                    get: { tempProfile.weightInPounds },
                                    set: { tempProfile.setWeightInPounds($0) }
                                ), format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("lbs")
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 30)
                            }
                        }
                    }
                    
                    // Height
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Height")
                            Spacer()
                        }
                        
                        if isMetric {
                            HStack(spacing: 12) {
                                TextField("170", value: $tempProfile.height, format: .number)
                                    .keyboardType(.decimalPad)
                                    .multilineTextAlignment(.trailing)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Text("cm")
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 30)
                            }
                        } else {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Feet")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("5", value: Binding(
                                        get: { Double(tempProfile.heightInFeet.feet) },
                                        set: { tempProfile.setHeightInFeetAndInches(feet: Int($0), inches: tempProfile.heightInFeet.inches) }
                                    ), format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Inches")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    TextField("7", value: Binding(
                                        get: { Double(tempProfile.heightInFeet.inches) },
                                        set: { tempProfile.setHeightInFeetAndInches(feet: tempProfile.heightInFeet.feet, inches: Int($0)) }
                                    ), format: .number)
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Activity Level")) {
                    Picker("Activity Level", selection: $tempProfile.activityLevel) {
                        ForEach(BMRProfile.ActivityLevel.allCases, id: \.self) { level in
                            VStack(alignment: .leading) {
                                Text(level.displayName)
                                    .font(.headline)
                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(level)
                        }
                    }
                    .pickerStyle(DefaultPickerStyle())
                }
                
                Section(header: Text("Calculated Values")) {
                    if tempProfile.isValid {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("BMR (Basal Metabolic Rate)")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(tempProfile.bmr)) cal/day")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                            
                            HStack {
                                Text("TDEE (Total Daily Energy Expenditure)")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(tempProfile.tdee)) cal/day")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Macro Recommendations")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                HStack {
                                    Text("Protein:")
                                    Spacer()
                                    Text("\(Int(tempProfile.proteinRecommendation))g")
                                        .foregroundColor(.red)
                                }
                                
                                HStack {
                                    Text("Fat:")
                                    Spacer()
                                    Text("\(Int(tempProfile.fatRecommendation))g")
                                        .foregroundColor(.brown)
                                }
                                
                                HStack {
                                    Text("Carbs:")
                                    Spacer()
                                    Text("\(Int(tempProfile.carbRecommendation))g")
                                        .foregroundColor(.yellow)
                                }
                                
                                HStack {
                                    Text("Water:")
                                    Spacer()
                                    Text("\(Int(tempProfile.waterRecommendation)) oz")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    } else {
                        Text("Please enter valid information to see calculations")
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .navigationTitle("BMR Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save unit preference
                        UserDefaults.standard.set(isMetric, forKey: "prefersImperialUnits")
                        bmrManager.updateProfile(tempProfile)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(!tempProfile.isValid)
                }
            }
        }
    }
}

// MARK: - BMR Goal Types

enum BMRGoalType: String, CaseIterable, Codable {
    case weightLoss = "weight_loss"
    case weightGain = "weight_gain"
    case maintenance = "maintenance"
    
    var displayName: String {
        switch self {
        case .weightLoss: return "Weight Loss"
        case .weightGain: return "Weight Gain"
        case .maintenance: return "Maintenance"
        }
    }
    
    var description: String {
        switch self {
        case .weightLoss: return "Create a calorie deficit for weight loss"
        case .weightGain: return "Create a calorie surplus for weight gain"
        case .maintenance: return "Maintain current weight"
        }
    }
    
    var icon: String {
        switch self {
        case .weightLoss: return "arrow.down.circle.fill"
        case .weightGain: return "arrow.up.circle.fill"
        case .maintenance: return "equal.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .weightLoss: return .green
        case .weightGain: return .blue
        case .maintenance: return .orange
        }
    }
}

// MARK: - BMR Recommendations

struct BMRRecommendations: Codable {
    let bmr: Double
    let tdee: Double
    let weightLossCalories: Double
    let weightGainCalories: Double
    let maintenanceCalories: Double
    let proteinRecommendation: Double
    let fatRecommendation: Double
    let carbRecommendation: Double
    let waterRecommendation: Double
    
    var bmrString: String {
        return "\(Int(bmr)) cal/day"
    }
    
    var tdeeString: String {
        return "\(Int(tdee)) cal/day"
    }
    
    var weightLossString: String {
        return "\(Int(weightLossCalories)) cal/day"
    }
    
    var weightGainString: String {
        return "\(Int(weightGainCalories)) cal/day"
    }
    
    var maintenanceString: String {
        return "\(Int(maintenanceCalories)) cal/day"
    }
    
    var proteinString: String {
        return "\(Int(proteinRecommendation))g"
    }
    
    var fatString: String {
        return "\(Int(fatRecommendation))g"
    }
    
    var carbString: String {
        return "\(Int(carbRecommendation))g"
    }
    
    var waterString: String {
        return "\(Int(waterRecommendation)) oz"
    }
}

#Preview {
    BMRProfileInputView(bmrManager: BMRManager())
}
