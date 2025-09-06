import Foundation

struct BPSession: Codable, Identifiable {
    let id = UUID()
    var readings: [BloodPressureReading]
    let startTime: Date
    var endTime: Date?
    var isActive: Bool
    
    init() {
        self.readings = []
        self.startTime = Date()
        self.endTime = nil
        self.isActive = false
    }
    
    init(startTime: Date) {
        self.readings = []
        self.startTime = startTime
        self.endTime = nil
        self.isActive = true
    }
    
    var averageSystolic: Double {
        guard !readings.isEmpty else { return 0 }
        return Double(readings.map { $0.systolic }.reduce(0, +)) / Double(readings.count)
    }
    
    var averageDiastolic: Double {
        guard !readings.isEmpty else { return 0 }
        return Double(readings.map { $0.diastolic }.reduce(0, +)) / Double(readings.count)
    }
    
    var averageHeartRate: Double? {
        let heartRates = readings.compactMap { $0.heartRate }
        guard !heartRates.isEmpty else { return nil }
        return Double(heartRates.reduce(0, +)) / Double(heartRates.count)
    }
    
    var isComplete: Bool {
        return endTime != nil
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var displayString: String {
        let systolic = Int(averageSystolic.rounded())
        let diastolic = Int(averageDiastolic.rounded())
        var result = "\(systolic)/\(diastolic)"
        
        if let heartRate = averageHeartRate {
            result += " • HR: \(Int(heartRate.rounded()))"
        }
        
        return result
    }
    
    mutating func addReading(_ reading: BloodPressureReading) {
        readings.append(reading)
    }
    
    mutating func removeReading(at index: Int) {
        guard index < readings.count else { return }
        readings.remove(at: index)
    }
    
    mutating func complete() {
        endTime = Date()
        isActive = false
    }
    
    mutating func start() {
        isActive = true
    }
    
    mutating func stop() {
        isActive = false
    }
}
