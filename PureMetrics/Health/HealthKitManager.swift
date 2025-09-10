import Foundation
import HealthKit
import SwiftUI

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
                // Don't automatically request authorization when toggling on
                // Let the user manually trigger it via the UI
                print("HealthKit enabled, waiting for user to grant permissions")
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
    
    // Health data types we want to read
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
        HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKObjectType.quantityType(forIdentifier: .flightsClimbed)!
    ]
    
    init() {
        // Load user's HealthKit preference
        self.isHealthKitEnabled = userDefaults.bool(forKey: healthKitEnabledKey)
        
        checkHealthKitAvailability()
        
        // If HealthKit is enabled, check authorization status
        if isHealthKitEnabled {
            // Add a delay to prevent immediate authorization check
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.checkAuthorizationStatus()
            }
        }
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
                // This type is denied, but others might be authorized
                continue
            @unknown default:
                print("Unknown authorization status: \(status.rawValue)")
            }
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
    
    private func fetchActiveEnergyBurned(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
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
        print("Active Energy: \(activeEnergyBurned)")
        print("Walking Distance: \(walkingDistance)")
        print("Flights Climbed: \(flightsClimbed)")
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
                print("No HealthKit authorization found")
            }
        }
    }
}
