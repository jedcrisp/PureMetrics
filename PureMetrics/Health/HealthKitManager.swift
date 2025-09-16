import Foundation
import HealthKit
import SwiftUI

// MARK: - HealthKit Data Point

struct HealthKitDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private let userDefaults = UserDefaults.standard
    private let healthKitEnabledKey = "HealthKitEnabled"
    private let healthKitRequestedKey = "HealthKitRequested"
    
    @Published var isAuthorized = false
    @Published var isHealthKitEnabled: Bool {
        didSet {
            userDefaults.set(isHealthKitEnabled, forKey: healthKitEnabledKey)
            if isHealthKitEnabled && !isAuthorized {
                // Only print this message if we're actually waiting for permissions
                if self.shouldShowPermissionMessage() {
                    print("HealthKit enabled, waiting for user to grant permissions")
                }
            } else if !isHealthKitEnabled {
                isAuthorized = false
            }
        }
    }
    @Published var stepsToday: Int = 0
    @Published var stepsThisWeek: Int = 0
    @Published var stepsThisMonth: Int = 0
    @Published var heartRateToday: Double = 0
    @Published var activeEnergyBurned: Double = 0
    @Published var restingHeartRate: Double = 0
    @Published var walkingDistance: Double = 0
    @Published var flightsClimbed: Int = 0
    @Published var currentWeight: Double = 0
    @Published var bodyFatPercentage: Double = 0
    @Published var leanBodyMass: Double = 0
    @Published var averageHeartRate: Double = 0
    
    // Health data types we want to read
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .bodyFatPercentage)!,
        HKObjectType.quantityType(forIdentifier: .leanBodyMass)!
    ]
    
    init() {
        // Load user's HealthKit preference
        self.isHealthKitEnabled = userDefaults.bool(forKey: healthKitEnabledKey)
        
        print("=== HEALTHKIT MANAGER INIT ===")
        print("HealthKit available: \(HKHealthStore.isHealthDataAvailable())")
        print("HealthKit enabled: \(isHealthKitEnabled)")
        
        checkHealthKitAvailability()
        
        // If HealthKit is enabled, check authorization status
        if isHealthKitEnabled {
            // Add a delay to prevent immediate authorization check
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkAuthorizationStatusOnly()
            }
        }
        
        // Sample data generation disabled - using real HealthKit data only
        // #if targetEnvironment(simulator)
        // DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
        //     self.addSampleDataToSimulator()
        // }
        // #endif
    }
    
    private func checkHealthKitAvailability() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { 
            print("HealthKit is not available on this device")
            return 
        }
        
        // Check if we have authorization for any of our read types
        var hasAnyAuthorization = false
        var allDenied = true
        var hasNotDetermined = false
        var hasAnyDenied = false
        
        for readType in readTypes {
            let status = healthStore.authorizationStatus(for: readType)
            print("Authorization status for \(readType.identifier): \(status.rawValue) (\(status))")
            
            switch status {
            case .sharingAuthorized:
                hasAnyAuthorization = true
                allDenied = false
            case .notDetermined:
                hasNotDetermined = true
                allDenied = false
            case .sharingDenied:
                hasAnyDenied = true
                // Don't set allDenied = false here, we need to check if ALL are denied
            @unknown default:
                print("Unknown authorization status: \(status.rawValue)")
            }
        }
        
        // Set allDenied based on authorization status
        if hasAnyAuthorization {
            allDenied = false
        } else if hasAnyDenied {
            allDenied = true
        } else {
            // No authorization and no denials - not determined
            allDenied = false
        }
        
        DispatchQueue.main.async {
            if allDenied {
                // All types are denied, disable HealthKit
                self.isHealthKitEnabled = false
                self.isAuthorized = false
                print("All HealthKit data types denied by user")
            } else if hasAnyAuthorization {
                // At least some types are authorized
                self.isAuthorized = true
                self.fetchTodayData()
                print("HealthKit authorized for some data types")
            } else if hasNotDetermined {
                // Some types not determined, need to request authorization
                // Don't turn off HealthKit, just mark as not authorized
                self.isAuthorized = false
                print("Some HealthKit data types not determined, need authorization")
            } else {
                // Fallback case - don't turn off HealthKit
                self.isAuthorized = false
                print("HealthKit authorization status unclear")
            }
        }
    }
    
    func requestAuthorization() {
        print("Requesting HealthKit authorization...")
        
        // Check if we've already requested authorization recently
        let lastRequestTime = userDefaults.double(forKey: "HealthKitLastRequestTime")
        let currentTime = Date().timeIntervalSince1970
        let timeSinceLastRequest = currentTime - lastRequestTime
        
        // Don't request again if we just requested within the last 5 seconds
        if timeSinceLastRequest < 5.0 {
            print("HealthKit authorization already requested recently, skipping...")
            checkAuthorizationStatus()
            return
        }
        
        // Record the request time
        userDefaults.set(currentTime, forKey: "HealthKitLastRequestTime")
        
        healthStore.requestAuthorization(toShare: [], read: readTypes) { [weak self] success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                }
                
                print("HealthKit authorization request completed with success: \(success)")
                // Always check the actual authorization status after the request
                self?.checkAuthorizationStatus()
            }
        }
    }
    
    func fetchTodayData() {
        guard isAuthorized && isHealthKitEnabled else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        fetchSteps(from: startOfDay, to: endOfDay) { [weak self] steps in
            DispatchQueue.main.async {
                self?.stepsToday = steps
            }
        }
        
        fetchHeartRate(from: startOfDay, to: endOfDay) { [weak self] heartRate in
            DispatchQueue.main.async {
                self?.heartRateToday = heartRate
            }
        }
        
        fetchActiveEnergyBurned(from: startOfDay, to: endOfDay) { [weak self] energy in
            DispatchQueue.main.async {
                self?.activeEnergyBurned = energy
            }
        }
        
        fetchWalkingDistance(from: startOfDay, to: endOfDay) { [weak self] distance in
            DispatchQueue.main.async {
                self?.walkingDistance = distance
            }
        }
        
        fetchFlightsClimbed(from: startOfDay, to: endOfDay) { [weak self] flights in
            DispatchQueue.main.async {
                self?.flightsClimbed = flights
            }
        }
        
        fetchCurrentWeight { [weak self] weight in
            DispatchQueue.main.async {
                self?.currentWeight = weight
            }
        }
        
        fetchBodyFatPercentage { [weak self] bodyFat in
            DispatchQueue.main.async {
                self?.bodyFatPercentage = bodyFat
            }
        }
        
        fetchAverageHeartRate(from: startOfDay, to: endOfDay) { [weak self] avgHeartRate in
            DispatchQueue.main.async {
                self?.averageHeartRate = avgHeartRate
            }
        }
    }
    
    func fetchWeeklyData() {
        guard isAuthorized && isHealthKitEnabled else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let endOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.end ?? now
        
        fetchSteps(from: startOfWeek, to: endOfWeek) { [weak self] steps in
            DispatchQueue.main.async {
                self?.stepsThisWeek = steps
            }
        }
    }
    
    func fetchMonthlyData() {
        guard isAuthorized && isHealthKitEnabled else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let endOfMonth = calendar.dateInterval(of: .month, for: now)?.end ?? now
        
        fetchSteps(from: startOfMonth, to: endOfMonth) { [weak self] steps in
            DispatchQueue.main.async {
                self?.stepsThisMonth = steps
            }
        }
    }
    
    // MARK: - Private Fetch Methods
    
    private func fetchSteps(from startDate: Date, to endDate: Date, completion: @escaping (Int) -> Void) {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { 
            print("Step count type not available")
            completion(0)
            return 
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            if let error = error {
                print("Error fetching steps: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            guard let result = result, let sum = result.sumQuantity() else {
                print("No step data found for the specified time range")
                completion(0)
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            print("Fetched \(steps) steps")
            completion(steps)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchHeartRate(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .mostRecent) { _, result, error in
            guard let result = result, let heartRate = result.mostRecentQuantity() else {
                completion(0)
                return
            }
            completion(heartRate.doubleValue(for: HKUnit(from: "count/min")))
        }
        
        healthStore.execute(query)
    }
    
    func fetchActiveEnergyBurned(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.kilocalorie()))
        }
        
        healthStore.execute(query)
    }
    
    func fetchBasalEnergyBurned(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else { 
            // No basal energy data available - return 0 to indicate no real data
            completion(0)
            return 
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                // No data available - return 0 to indicate no real data
                completion(0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.kilocalorie()))
        }
        
        healthStore.execute(query)
    }
    
    private func fetchWalkingDistance(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.meter()))
        }
        
        healthStore.execute(query)
    }
    
    private func fetchFlightsClimbed(from startDate: Date, to endDate: Date, completion: @escaping (Int) -> Void) {
        guard let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) else { return }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: flightsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            completion(Int(sum.doubleValue(for: HKUnit.count())))
        }
        
        healthStore.execute(query)
    }
    
    private func fetchCurrentWeight(completion: @escaping (Double) -> Void) {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { 
            print("Body mass type not available")
            completion(0)
            return 
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("Error fetching weight: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else {
                print("No weight data found")
                completion(0)
                return
            }
            
            let weight = sample.quantity.doubleValue(for: HKUnit.pound())
            print("Fetched current weight: \(weight) lbs")
            completion(weight)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchBodyFatPercentage(completion: @escaping (Double) -> Void) {
        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { 
            print("Body fat percentage type not available")
            completion(0)
            return 
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: bodyFatType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("Error fetching body fat percentage: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            guard let sample = samples?.first as? HKQuantitySample else {
                print("No body fat percentage data found")
                completion(0)
                return
            }
            
            let bodyFat = sample.quantity.doubleValue(for: HKUnit.percent())
            print("Fetched body fat percentage: \(bodyFat)%")
            completion(bodyFat)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchAverageHeartRate(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { 
            print("Heart rate type not available")
            completion(0)
            return 
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, error in
            if let error = error {
                print("Error fetching average heart rate: \(error.localizedDescription)")
                completion(0)
                return
            }
            
            guard let result = result, let avgHeartRate = result.averageQuantity() else {
                print("No average heart rate data found for the specified time range")
                completion(0)
                return
            }
            
            let heartRate = avgHeartRate.doubleValue(for: HKUnit(from: "count/min"))
            print("Fetched average heart rate: \(heartRate) bpm")
            completion(heartRate)
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Public Methods
    
    func toggleHealthKit() {
        isHealthKitEnabled.toggle()
    }
    
    func refreshData() {
        guard isHealthKitEnabled else { return }
        fetchTodayData()
        fetchWeeklyData()
        fetchMonthlyData()
    }
    
    var formattedStepsToday: String {
        return "\(stepsToday.formatted()) steps"
    }
    
    var formattedStepsThisWeek: String {
        return "\(stepsThisWeek.formatted()) steps"
    }
    
    var formattedStepsThisMonth: String {
        return "\(stepsThisMonth.formatted()) steps"
    }
    
    var formattedHeartRate: String {
        return "\(Int(heartRateToday)) bpm"
    }
    
    var formattedActiveEnergy: String {
        return "\(Int(activeEnergyBurned)) cal"
    }
    
    var formattedWalkingDistance: String {
        let distanceInMiles = walkingDistance * 0.000621371
        return String(format: "%.2f mi", distanceInMiles)
    }
    
    var formattedFlightsClimbed: String {
        return "\(flightsClimbed) flights"
    }
    
    var formattedCurrentWeight: String {
        return String(format: "%.1f lbs", currentWeight)
    }
    
    var formattedBodyFatPercentage: String {
        return String(format: "%.1f%%", bodyFatPercentage)
    }
    
    var formattedLeanBodyMass: String {
        return String(format: "%.1f lbs", leanBodyMass)
    }
    
    var formattedAverageHeartRate: String {
        return "\(Int(averageHeartRate)) bpm"
    }
    
    // MARK: - Debug Methods
    
    func debugHealthKitStatus() {
        print("=== HealthKit Debug Status ===")
        print("HealthKit Available: \(HKHealthStore.isHealthDataAvailable())")
        print("HealthKit Enabled: \(isHealthKitEnabled)")
        print("Is Authorized: \(isAuthorized)")
        
        for readType in readTypes {
            let status = healthStore.authorizationStatus(for: readType)
            print("\(readType.identifier): \(status.rawValue) (\(status))")
        }
        
        print("Current Data:")
        print("Steps Today: \(stepsToday)")
        print("Heart Rate Today: \(heartRateToday)")
        print("Average Heart Rate: \(averageHeartRate)")
        print("Active Energy: \(activeEnergyBurned)")
        print("Walking Distance: \(walkingDistance)")
        print("Flights Climbed: \(flightsClimbed)")
        print("Current Weight: \(currentWeight)")
        print("Body Fat %: \(bodyFatPercentage)")
        print("=============================")
    }
    
    func checkAuthorizationStatusOnly() {
        // Check authorization status without changing HealthKit enabled state
        guard HKHealthStore.isHealthDataAvailable() else { 
            print("HealthKit is not available on this device")
            return 
        }
        
        var hasAnyAuthorization = false
        
        for readType in readTypes {
            let status = healthStore.authorizationStatus(for: readType)
            if status == .sharingAuthorized {
                hasAnyAuthorization = true
                break
            }
        }
        
        DispatchQueue.main.async {
            if hasAnyAuthorization {
                self.isAuthorized = true
                self.fetchTodayData()
                print("HealthKit authorization found")
            } else {
                self.isAuthorized = false
                // Only print this if we haven't already requested recently
                if self.shouldShowPermissionMessage() {
                    print("No HealthKit authorization found")
                }
            }
        }
    }
    
    private func shouldShowPermissionMessage() -> Bool {
        let lastRequestTime = userDefaults.double(forKey: "HealthKitLastRequestTime")
        let currentTime = Date().timeIntervalSince1970
        let timeSinceLastRequest = currentTime - lastRequestTime
        
        // Only show message if we haven't requested in the last 5 minutes
        return timeSinceLastRequest > 300
    }
    
    // MARK: - Sample Data Generation (for Simulator)
    
    private func generateSampleWeightData(from startDate: Date, to endDate: Date) -> [HealthKitDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [HealthKitDataPoint] = []
        
        // Generate sample weight data over the time range
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let numberOfSamples = min(daysBetween, 30) // Max 30 samples
        
        for i in 0..<numberOfSamples {
            let date = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
            // Generate realistic weight data with some variation
            let baseWeight = 150.0 + Double(i) * 0.1 // Slight upward trend
            let variation = Double.random(in: -2.0...2.0) // Random variation
            let weight = baseWeight + variation
            
            dataPoints.append(HealthKitDataPoint(date: date, value: weight))
        }
        
        print("Generated \(dataPoints.count) sample weight data points")
        return dataPoints
    }
    
    private func generateSampleStepsData(from startDate: Date, to endDate: Date) -> [HealthKitDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [HealthKitDataPoint] = []
        
        // Generate sample steps data over the time range
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let numberOfSamples = min(daysBetween, 30) // Max 30 samples
        
        for i in 0..<numberOfSamples {
            let date = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
            let isToday = calendar.isDateInToday(date)
            
            // Generate realistic steps data with higher base counts
            let baseSteps: Double
            if isToday {
                // Today gets a higher step count (closer to your 14,000)
                baseSteps = 14000.0 + Double.random(in: -2000.0...2000.0)
            } else {
                baseSteps = 12000.0 + Double(i) * 100 // Higher base with upward trend
            }
            
            let variation = Double.random(in: -3000.0...3000.0) // More variation
            let steps = max(5000, baseSteps + variation) // Ensure minimum reasonable steps
            
            dataPoints.append(HealthKitDataPoint(date: date, value: steps))
        }
        
        print("Generated \(dataPoints.count) sample steps data points")
        return dataPoints
    }
    
    // MARK: - Simulator Sample Data Injection
    
    func addSampleDataToSimulator() {
        #if targetEnvironment(simulator)
        print("=== ADDING SAMPLE DATA TO SIMULATOR ===")
        print("HealthKit available: \(HKHealthStore.isHealthDataAvailable())")
        
        // Add sample steps data
        addSampleStepsToHealthStore()
        
        // Add sample weight data
        addSampleWeightToHealthStore()
        
        // Add sample active energy data
        addSampleActiveEnergyToHealthStore()
        
        // Add sample body fat percentage data
        addSampleBodyFatToHealthStore()
        
        // Add sample lean body mass data
        addSampleLeanBodyMassToHealthStore()
        
        // Add sample total calories data
        addSampleTotalCaloriesToHealthStore()
        #endif
    }
    
    // Manual trigger for testing
    func forceAddSampleData() {
        #if targetEnvironment(simulator)
        print("=== FORCE ADDING SAMPLE DATA ===")
        addSampleDataToSimulator()
        #endif
    }
    
    #if targetEnvironment(simulator)
    private func addSampleStepsToHealthStore() {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { 
            print("Steps type not available")
            return 
        }
        
        print("=== ADDING SAMPLE STEPS DATA ===")
        let calendar = Calendar.current
        let now = Date()
        
        // Add data for the last 30 days
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let isToday = calendar.isDateInToday(date)
            
            let baseSteps: Double
            if isToday {
                baseSteps = 14000.0 + Double.random(in: -2000.0...2000.0)
            } else {
                baseSteps = 12000.0 + Double(30-i) * 50
            }
            
            let variation = Double.random(in: -3000.0...3000.0)
            let steps = max(5000, baseSteps + variation)
            
            let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: steps)
            let sample = HKQuantitySample(type: stepsType, quantity: quantity, start: date, end: date)
            
            healthStore.save(sample) { success, error in
                if success {
                    print("✅ Saved sample steps data: \(Int(steps)) steps on \(date)")
                } else {
                    print("❌ Error saving steps data: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        print("=== SAMPLE STEPS DATA INJECTION COMPLETE ===")
    }
    
    private func addSampleWeightToHealthStore() {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Add weight data for the last 30 days
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            
            let baseWeight = 150.0 + Double(30-i) * 0.1
            let variation = Double.random(in: -2.0...2.0)
            let weight = baseWeight + variation
            
            let quantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weight)
            let sample = HKQuantitySample(type: weightType, quantity: quantity, start: date, end: date)
            
            healthStore.save(sample) { success, error in
                if success {
                    print("Saved sample weight data: \(weight) kg on \(date)")
                } else {
                    print("Error saving weight data: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func addSampleActiveEnergyToHealthStore() {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Add active energy data for the last 30 days
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            
            let baseEnergy = 400.0 + Double(30-i) * 5
            let variation = Double.random(in: -100.0...100.0)
            let energy = max(200, baseEnergy + variation)
            
            let quantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: energy)
            let sample = HKQuantitySample(type: energyType, quantity: quantity, start: date, end: date)
            
            healthStore.save(sample) { success, error in
                if success {
                    print("Saved sample active energy data: \(energy) kcal on \(date)")
                } else {
                    print("Error saving active energy data: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    #endif
    
    private func generateSampleActiveEnergyData(from startDate: Date, to endDate: Date) -> [HealthKitDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [HealthKitDataPoint] = []
        
        // Generate sample active energy data over the time range
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let numberOfSamples = min(daysBetween, 30) // Max 30 samples
        
        for i in 0..<numberOfSamples {
            let date = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
            // Generate realistic active energy data
            let baseEnergy = 400.0 + Double(i) * 5 // Slight upward trend
            let variation = Double.random(in: -100.0...100.0) // Random variation
            let energy = max(0, baseEnergy + variation) // Ensure non-negative
            
            dataPoints.append(HealthKitDataPoint(date: date, value: energy))
        }
        
        print("Generated \(dataPoints.count) sample active energy data points")
        return dataPoints
    }
    
    // MARK: - Historical Data Fetching
    
    func fetchHistoricalWeightData(from startDate: Date, to endDate: Date, completion: @escaping ([HealthKitDataPoint]) -> Void) {
        print("=== FETCHING HISTORICAL WEIGHT DATA ===")
        print("Start date: \(startDate)")
        print("End date: \(endDate)")
        
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            completion([])
            return
        }
        
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            print("Weight type not available")
            completion([])
            return
        }
        
        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: weightType)
        print("Weight authorization status: \(authStatus.rawValue)")
        
        if authStatus == .notDetermined {
            print("Weight not authorized, requesting authorization")
            healthStore.requestAuthorization(toShare: [], read: [weightType]) { success, error in
                if success {
                    print("Weight authorization granted")
                    // Retry the query after authorization
                    self.fetchHistoricalWeightData(from: startDate, to: endDate, completion: completion)
                } else {
                    print("Weight authorization denied: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                }
            }
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: weightType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("Error fetching historical weight data: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                print("No weight samples found or wrong type")
                completion([])
                return
            }
            
            print("Found \(samples.count) weight samples")
            
        // Group weight by day and take the latest reading for each day
        let calendar = Calendar.current
        var dailyWeight: [Date: Double] = [:]
        
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            let weight = sample.quantity.doubleValue(for: HKUnit.pound())
            // Keep the latest weight reading for each day
            if dailyWeight[day] == nil || sample.startDate > calendar.date(byAdding: .hour, value: 12, to: day)! {
                dailyWeight[day] = weight
            }
        }
        
        let dataPoints = dailyWeight.map { (date, weight) in
            HealthKitDataPoint(date: date, value: weight)
        }.sorted { $0.date < $1.date }
            
            print("Created \(dataPoints.count) data points")
            
            DispatchQueue.main.async {
                completion(dataPoints)
            }
        }
        
        healthStore.execute(query)
    }
    
    func fetchHistoricalStepsData(from startDate: Date, to endDate: Date, completion: @escaping ([HealthKitDataPoint]) -> Void) {
        print("=== FETCHING HISTORICAL STEPS DATA ===")
        print("Start date: \(startDate)")
        print("End date: \(endDate)")
        
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            completion([])
            return
        }
        
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            print("Steps type not available")
            completion([])
            return
        }
        
        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: stepsType)
        print("Steps authorization status: \(authStatus.rawValue)")
        
        if authStatus == .notDetermined {
            print("Steps not authorized, requesting authorization")
            healthStore.requestAuthorization(toShare: [], read: [stepsType]) { success, error in
                print("Authorization result: success=\(success), error=\(error?.localizedDescription ?? "none")")
                if success {
                    print("Steps authorization granted, executing query")
                    // Continue with the query after authorization
                    DispatchQueue.main.async {
                        self.executeStepsQuery(stepsType: stepsType, startDate: startDate, endDate: endDate, completion: completion)
                    }
                } else {
                    print("Steps authorization denied: \(error?.localizedDescription ?? "Unknown error")")
                    // Even if denied, try to execute query in case there's sample data
                    DispatchQueue.main.async {
                        self.executeStepsQuery(stepsType: stepsType, startDate: startDate, endDate: endDate, completion: completion)
                    }
                }
            }
            return
        }
        
        // Execute the query directly
        executeStepsQuery(stepsType: stepsType, startDate: startDate, endDate: endDate, completion: completion)
    }
    
    private func executeStepsQuery(stepsType: HKQuantityType, startDate: Date, endDate: Date, completion: @escaping ([HealthKitDataPoint]) -> Void) {
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: stepsType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("Error fetching historical steps data: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            
        // Group steps by day and sum them up
        let calendar = Calendar.current
        var dailySteps: [Date: Double] = [:]
        
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            let steps = sample.quantity.doubleValue(for: HKUnit.count())
            dailySteps[day, default: 0] += steps
        }
        
        let dataPoints = dailySteps.map { (date, totalSteps) in
            HealthKitDataPoint(date: date, value: totalSteps)
        }.sorted { $0.date < $1.date }
            
            print("Found \(dataPoints.count) real step data points")
            
            // If no real data found, fall back to sample data for demonstration
            if dataPoints.isEmpty {
                print("No real step data found, using sample data")
                #if targetEnvironment(simulator)
                let sampleData = self.generateSampleStepsData(from: startDate, to: endDate)
                DispatchQueue.main.async {
                    completion(sampleData)
                }
                return
                #endif
            }
            
            DispatchQueue.main.async {
                completion(dataPoints)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Body Fat Percentage Data
    
    func fetchHistoricalBodyFatPercentageData(from startDate: Date, to endDate: Date, completion: @escaping ([HealthKitDataPoint]) -> Void) {
        print("=== FETCHING HISTORICAL BODY FAT PERCENTAGE DATA ===")
        print("Start date: \(startDate)")
        print("End date: \(endDate)")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            completion([])
            return
        }
        
        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else {
            print("Body fat percentage type not available")
            completion([])
            return
        }
        
        let authStatus = healthStore.authorizationStatus(for: bodyFatType)
        print("Body fat percentage authorization status: \(authStatus.rawValue)")
        
        if authStatus == .notDetermined {
            print("Body fat percentage not authorized, requesting authorization")
            healthStore.requestAuthorization(toShare: [], read: [bodyFatType]) { success, error in
                if success {
                    print("Body fat percentage authorization granted")
                    DispatchQueue.main.async {
                        self.executeBodyFatQuery(bodyFatType: bodyFatType, startDate: startDate, endDate: endDate, completion: completion)
                    }
                } else {
                    print("Body fat percentage authorization denied: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                }
            }
            return
        }
        
        executeBodyFatQuery(bodyFatType: bodyFatType, startDate: startDate, endDate: endDate, completion: completion)
    }
    
    private func executeBodyFatQuery(bodyFatType: HKQuantityType, startDate: Date, endDate: Date, completion: @escaping ([HealthKitDataPoint]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: bodyFatType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("Error fetching historical body fat percentage data: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            
            // Group body fat percentage by day and take the latest reading for each day
            let calendar = Calendar.current
            var dailyBodyFat: [Date: Double] = [:]
            
            for sample in samples {
                let day = calendar.startOfDay(for: sample.startDate)
                let bodyFat = sample.quantity.doubleValue(for: HKUnit.percent())
                // Keep the latest body fat reading for each day
                if dailyBodyFat[day] == nil || sample.startDate > calendar.date(byAdding: .hour, value: 12, to: day)! {
                    dailyBodyFat[day] = bodyFat
                }
            }
            
            let dataPoints = dailyBodyFat.map { (date, bodyFat) in
                HealthKitDataPoint(date: date, value: bodyFat)
            }.sorted { $0.date < $1.date }
            
            print("Found \(dataPoints.count) real body fat percentage data points")
            
            if dataPoints.isEmpty {
                print("No real body fat percentage data found, using sample data")
                #if targetEnvironment(simulator)
                let sampleData = self.generateSampleBodyFatData(from: startDate, to: endDate)
                DispatchQueue.main.async {
                    completion(sampleData)
                }
                return
                #endif
            }
            
            DispatchQueue.main.async {
                completion(dataPoints)
            }
        }
        healthStore.execute(query)
    }
    
    // MARK: - Lean Body Mass Data
    
    func fetchHistoricalLeanBodyMassData(from startDate: Date, to endDate: Date, completion: @escaping ([HealthKitDataPoint]) -> Void) {
        print("=== FETCHING HISTORICAL LEAN BODY MASS DATA ===")
        print("Start date: \(startDate)")
        print("End date: \(endDate)")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            completion([])
            return
        }
        
        guard let leanBodyMassType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) else {
            print("Lean body mass type not available")
            completion([])
            return
        }
        
        let authStatus = healthStore.authorizationStatus(for: leanBodyMassType)
        print("Lean body mass authorization status: \(authStatus.rawValue)")
        
        if authStatus == .notDetermined {
            print("Lean body mass not authorized, requesting authorization")
            healthStore.requestAuthorization(toShare: [], read: [leanBodyMassType]) { success, error in
                if success {
                    print("Lean body mass authorization granted")
                    DispatchQueue.main.async {
                        self.executeLeanBodyMassQuery(leanBodyMassType: leanBodyMassType, startDate: startDate, endDate: endDate, completion: completion)
                    }
                } else {
                    print("Lean body mass authorization denied: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                }
            }
            return
        }
        
        executeLeanBodyMassQuery(leanBodyMassType: leanBodyMassType, startDate: startDate, endDate: endDate, completion: completion)
    }
    
    private func executeLeanBodyMassQuery(leanBodyMassType: HKQuantityType, startDate: Date, endDate: Date, completion: @escaping ([HealthKitDataPoint]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: leanBodyMassType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("Error fetching historical lean body mass data: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            
            // Group lean body mass by day and take the latest reading for each day
            let calendar = Calendar.current
            var dailyLeanBodyMass: [Date: Double] = [:]
            
            for sample in samples {
                let day = calendar.startOfDay(for: sample.startDate)
                let leanBodyMass = sample.quantity.doubleValue(for: HKUnit.pound())
                // Keep the latest lean body mass reading for each day
                if dailyLeanBodyMass[day] == nil || sample.startDate > calendar.date(byAdding: .hour, value: 12, to: day)! {
                    dailyLeanBodyMass[day] = leanBodyMass
                }
            }
            
            let dataPoints = dailyLeanBodyMass.map { (date, leanBodyMass) in
                HealthKitDataPoint(date: date, value: leanBodyMass)
            }.sorted { $0.date < $1.date }
            
            print("Found \(dataPoints.count) real lean body mass data points")
            
            if dataPoints.isEmpty {
                print("No real lean body mass data found, using sample data")
                #if targetEnvironment(simulator)
                let sampleData = self.generateSampleLeanBodyMassData(from: startDate, to: endDate)
                DispatchQueue.main.async {
                    completion(sampleData)
                }
                return
                #endif
            }
            
            DispatchQueue.main.async {
                completion(dataPoints)
            }
        }
        healthStore.execute(query)
    }
    
    // MARK: - Total Calories Data (Active + Resting + Walking + Everything)
    
    func fetchHistoricalTotalCaloriesData(from startDate: Date, to endDate: Date, completion: @escaping ([HealthKitDataPoint]) -> Void) {
        print("=== FETCHING HISTORICAL TOTAL CALORIES DATA ===")
        print("Start date: \(startDate)")
        print("End date: \(endDate)")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            completion([])
            return
        }
        
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let basalEnergyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else {
            print("Calories types not available")
            completion([])
            return
        }
        
        let authStatus = healthStore.authorizationStatus(for: activeEnergyType)
        print("Total calories authorization status: \(authStatus.rawValue)")
        
        if authStatus == .notDetermined {
            print("Total calories not authorized, requesting authorization")
            healthStore.requestAuthorization(toShare: [], read: [activeEnergyType, basalEnergyType]) { success, error in
                if success {
                    print("Total calories authorization granted")
                    DispatchQueue.main.async {
                        self.executeTotalCaloriesQuery(activeEnergyType: activeEnergyType, basalEnergyType: basalEnergyType, startDate: startDate, endDate: endDate, completion: completion)
                    }
                } else {
                    print("Total calories authorization denied: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                }
            }
            return
        }
        
        executeTotalCaloriesQuery(activeEnergyType: activeEnergyType, basalEnergyType: basalEnergyType, startDate: startDate, endDate: endDate, completion: completion)
    }
    
    private func executeTotalCaloriesQuery(activeEnergyType: HKQuantityType, basalEnergyType: HKQuantityType, startDate: Date, endDate: Date, completion: @escaping ([HealthKitDataPoint]) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        // Fetch both active and basal energy
        let group = DispatchGroup()
        var activeEnergySamples: [HKQuantitySample] = []
        var basalEnergySamples: [HKQuantitySample] = []
        
        // Fetch active energy
        group.enter()
        let activeQuery = HKSampleQuery(sampleType: activeEnergyType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let samples = samples as? [HKQuantitySample] {
                activeEnergySamples = samples
            }
            group.leave()
        }
        healthStore.execute(activeQuery)
        
        // Fetch basal energy
        group.enter()
        let basalQuery = HKSampleQuery(sampleType: basalEnergyType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let samples = samples as? [HKQuantitySample] {
                basalEnergySamples = samples
            }
            group.leave()
        }
        healthStore.execute(basalQuery)
        
        group.notify(queue: .main) {
            // Combine active and basal energy by day
            let calendar = Calendar.current
            var dailyTotalCalories: [Date: Double] = [:]
            
            // Process active energy
            for sample in activeEnergySamples {
                let day = calendar.startOfDay(for: sample.startDate)
                let calories = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                dailyTotalCalories[day, default: 0] += calories
            }
            
            // Process basal energy
            for sample in basalEnergySamples {
                let day = calendar.startOfDay(for: sample.startDate)
                let calories = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
                dailyTotalCalories[day, default: 0] += calories
            }
            
            let dataPoints = dailyTotalCalories.map { (date, totalCalories) in
                HealthKitDataPoint(date: date, value: totalCalories)
            }.sorted { $0.date < $1.date }
            
            print("Found \(dataPoints.count) real total calories data points")
            
            if dataPoints.isEmpty {
                print("No real total calories data found, using sample data")
                #if targetEnvironment(simulator)
                let sampleData = self.generateSampleTotalCaloriesData(from: startDate, to: endDate)
                completion(sampleData)
                return
                #endif
            }
            
            completion(dataPoints)
        }
    }
    
    func fetchHistoricalActiveEnergyData(from startDate: Date, to endDate: Date, completion: @escaping ([HealthKitDataPoint]) -> Void) {
        print("=== FETCHING HISTORICAL ACTIVE ENERGY DATA ===")
        print("Start date: \(startDate)")
        print("End date: \(endDate)")
        
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            completion([])
            return
        }
        
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            print("Active energy type not available")
            completion([])
            return
        }
        
        // Check authorization status
        let authStatus = healthStore.authorizationStatus(for: energyType)
        print("Active energy authorization status: \(authStatus.rawValue)")
        
        if authStatus == .notDetermined {
            print("Active energy not authorized, requesting authorization")
            healthStore.requestAuthorization(toShare: [], read: [energyType]) { success, error in
                if success {
                    print("Active energy authorization granted")
                    // Retry the query after authorization
                    self.fetchHistoricalActiveEnergyData(from: startDate, to: endDate, completion: completion)
                } else {
                    print("Active energy authorization denied: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                }
            }
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: energyType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { _, samples, error in
            if let error = error {
                print("Error fetching historical active energy data: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else {
                completion([])
                return
            }
            
        // Group active energy by day and sum them up
        let calendar = Calendar.current
        var dailyEnergy: [Date: Double] = [:]
        
        for sample in samples {
            let day = calendar.startOfDay(for: sample.startDate)
            let energy = sample.quantity.doubleValue(for: HKUnit.kilocalorie())
            dailyEnergy[day, default: 0] += energy
        }
        
        let dataPoints = dailyEnergy.map { (date, totalEnergy) in
            HealthKitDataPoint(date: date, value: totalEnergy)
        }.sorted { $0.date < $1.date }
            
            DispatchQueue.main.async {
                completion(dataPoints)
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - Sample Data Generation for New Metrics
    
    #if targetEnvironment(simulator)
    private func generateSampleBodyFatData(from startDate: Date, to endDate: Date) -> [HealthKitDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [HealthKitDataPoint] = []
        
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let numberOfSamples = min(daysBetween, 30) // Max 30 samples
        
        for i in 0..<numberOfSamples {
            let date = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
            
            // Generate realistic body fat percentage (12-20% range)
            let baseBodyFat = 15.0 + Double(i) * 0.1
            let variation = Double.random(in: -2.0...2.0)
            let bodyFat = max(10.0, min(25.0, baseBodyFat + variation))
            
            dataPoints.append(HealthKitDataPoint(date: date, value: bodyFat))
        }
        
        print("Generated \(dataPoints.count) sample body fat data points")
        return dataPoints
    }
    
    private func generateSampleLeanBodyMassData(from startDate: Date, to endDate: Date) -> [HealthKitDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [HealthKitDataPoint] = []
        
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let numberOfSamples = min(daysBetween, 30) // Max 30 samples
        
        for i in 0..<numberOfSamples {
            let date = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
            
            // Generate realistic lean body mass (140-180 lbs range)
            let baseLeanBodyMass = 160.0 + Double(i) * 0.5
            let variation = Double.random(in: -5.0...5.0)
            let leanBodyMass = max(130.0, min(200.0, baseLeanBodyMass + variation))
            
            dataPoints.append(HealthKitDataPoint(date: date, value: leanBodyMass))
        }
        
        print("Generated \(dataPoints.count) sample lean body mass data points")
        return dataPoints
    }
    
    private func generateSampleTotalCaloriesData(from startDate: Date, to endDate: Date) -> [HealthKitDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [HealthKitDataPoint] = []
        
        let daysBetween = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        let numberOfSamples = min(daysBetween, 30) // Max 30 samples
        
        for i in 0..<numberOfSamples {
            let date = calendar.date(byAdding: .day, value: i, to: startDate) ?? startDate
            let isToday = calendar.isDateInToday(date)
            
            // Generate realistic total calories (2000-3000 range)
            let baseCalories: Double
            if isToday {
                baseCalories = 2500.0 + Double.random(in: -200.0...200.0)
            } else {
                baseCalories = 2200.0 + Double(i) * 10
            }
            
            let variation = Double.random(in: -300.0...300.0)
            let totalCalories = max(1500.0, baseCalories + variation)
            
            dataPoints.append(HealthKitDataPoint(date: date, value: totalCalories))
        }
        
        print("Generated \(dataPoints.count) sample total calories data points")
        return dataPoints
    }
    
    private func addSampleBodyFatToHealthStore() {
        guard let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Add body fat data for the last 30 days
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            
            let baseBodyFat = 15.0 + Double(30-i) * 0.1
            let variation = Double.random(in: -2.0...2.0)
            let bodyFat = max(10.0, min(25.0, baseBodyFat + variation))
            
            let quantity = HKQuantity(unit: HKUnit.percent(), doubleValue: bodyFat / 100.0)
            let sample = HKQuantitySample(type: bodyFatType, quantity: quantity, start: date, end: date)
            
            healthStore.save(sample) { success, error in
                if success {
                    print("Saved sample body fat data: \(bodyFat)% on \(date)")
                } else {
                    print("Error saving body fat data: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func addSampleLeanBodyMassToHealthStore() {
        guard let leanBodyMassType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Add lean body mass data for the last 30 days
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            
            let baseLeanBodyMass = 160.0 + Double(30-i) * 0.5
            let variation = Double.random(in: -5.0...5.0)
            let leanBodyMass = max(130.0, min(200.0, baseLeanBodyMass + variation))
            
            let quantity = HKQuantity(unit: HKUnit.pound(), doubleValue: leanBodyMass)
            let sample = HKQuantitySample(type: leanBodyMassType, quantity: quantity, start: date, end: date)
            
            healthStore.save(sample) { success, error in
                if success {
                    print("Saved sample lean body mass data: \(leanBodyMass) lbs on \(date)")
                } else {
                    print("Error saving lean body mass data: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func addSampleTotalCaloriesToHealthStore() {
        guard let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let basalEnergyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Add total calories data for the last 30 days
        for i in 0..<30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            
            let baseActiveEnergy = 400.0 + Double(30-i) * 5
            let baseBasalEnergy = 1500.0 + Double(30-i) * 10
            let activeVariation = Double.random(in: -100.0...100.0)
            let basalVariation = Double.random(in: -200.0...200.0)
            
            let activeEnergy = max(200, baseActiveEnergy + activeVariation)
            let basalEnergy = max(1200, baseBasalEnergy + basalVariation)
            
            // Save active energy
            let activeQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: activeEnergy)
            let activeSample = HKQuantitySample(type: activeEnergyType, quantity: activeQuantity, start: date, end: date)
            
            healthStore.save(activeSample) { success, error in
                if success {
                    print("Saved sample active energy data: \(activeEnergy) kcal on \(date)")
                }
            }
            
            // Save basal energy
            let basalQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: basalEnergy)
            let basalSample = HKQuantitySample(type: basalEnergyType, quantity: basalQuantity, start: date, end: date)
            
            healthStore.save(basalSample) { success, error in
                if success {
                    print("Saved sample basal energy data: \(basalEnergy) kcal on \(date)")
                }
            }
        }
    }
    #endif
}
