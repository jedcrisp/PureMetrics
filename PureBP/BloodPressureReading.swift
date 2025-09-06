import Foundation

struct BloodPressureReading: Codable, Identifiable {
    let id = UUID()
    let systolic: Int
    let diastolic: Int
    let heartRate: Int?
    let timestamp: Date
    
    init(systolic: Int, diastolic: Int, heartRate: Int? = nil, timestamp: Date? = nil) {
        self.systolic = systolic
        self.diastolic = diastolic
        self.heartRate = heartRate
        self.timestamp = timestamp ?? Date()
    }
    
    var isValid: Bool {
        return systolic >= 50 && systolic <= 300 &&
               diastolic >= 30 && diastolic <= 200 &&
               systolic > diastolic &&
               (heartRate == nil || (heartRate! >= 30 && heartRate! <= 200))
    }
    
    var displayString: String {
        var result = "\(systolic)/\(diastolic)"
        if let heartRate = heartRate {
            result += " • HR: \(heartRate)"
        }
        return result
    }
}
