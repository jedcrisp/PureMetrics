import Foundation

struct BloodPressureReading: Codable, Identifiable {
    let id = UUID()
    let systolic: Int
    let diastolic: Int
    let heartRate: Int?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case systolic, diastolic, heartRate, timestamp
    }
    
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
    
    // Convert to HealthMetric for unified handling
    func toHealthMetrics() -> [HealthMetric] {
        var metrics: [HealthMetric] = []
        
        // Add systolic as a metric
        metrics.append(HealthMetric(type: .bloodPressure, value: Double(systolic), timestamp: timestamp))
        
        // Add diastolic as a metric
        metrics.append(HealthMetric(type: .bloodPressure, value: Double(diastolic), timestamp: timestamp))
        
        // Add heart rate if available
        if let heartRate = heartRate {
            metrics.append(HealthMetric(type: .heartRate, value: Double(heartRate), timestamp: timestamp))
        }
        
        return metrics
    }
}
