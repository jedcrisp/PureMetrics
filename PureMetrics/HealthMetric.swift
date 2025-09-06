import Foundation

// MARK: - Health Metric Types

enum MetricType: String, CaseIterable, Codable {
    case bloodPressure = "Blood Pressure"
    case weight = "Weight"
    case bloodSugar = "Blood Sugar"
    case heartRate = "Heart Rate"
    
    var unit: String {
        switch self {
        case .bloodPressure: return "mmHg"
        case .weight: return "lbs"
        case .bloodSugar: return "mg/dL"
        case .heartRate: return "bpm"
        }
    }
    
    var color: String {
        switch self {
        case .bloodPressure: return "blue"
        case .weight: return "green"
        case .bloodSugar: return "orange"
        case .heartRate: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .bloodPressure: return "heart.fill"
        case .weight: return "scalemass.fill"
        case .bloodSugar: return "drop.fill"
        case .heartRate: return "heart.circle.fill"
        }
    }
    
    var placeholder: String {
        switch self {
        case .bloodPressure: return "120/80"
        case .weight: return "150"
        case .bloodSugar: return "100"
        case .heartRate: return "72"
        }
    }
}

// MARK: - Health Metric Model

struct HealthMetric: Codable, Identifiable {
    let id = UUID()
    let type: MetricType
    let value: Double
    let timestamp: Date
    
    init(type: MetricType, value: Double, timestamp: Date? = nil) {
        self.type = type
        self.value = value
        self.timestamp = timestamp ?? Date()
    }
    
    var isValid: Bool {
        switch type {
        case .bloodPressure:
            return value >= 50 && value <= 300
        case .weight:
            return value >= 50 && value <= 500
        case .bloodSugar:
            return value >= 20 && value <= 600
        case .heartRate:
            return value >= 30 && value <= 200
        }
    }
    
    var displayString: String {
        switch type {
        case .bloodPressure:
            return "\(Int(value)) \(type.unit)"
        case .weight, .bloodSugar, .heartRate:
            return "\(Int(value)) \(type.unit)"
        }
    }
    
    var formattedValue: String {
        if type == .bloodPressure {
            return "\(Int(value))"
        } else if type == .weight || type == .bloodSugar {
            return String(format: "%.1f", value)
        } else {
            return "\(Int(value))"
        }
    }
}

// MARK: - Blood Pressure Reading (Enhanced)

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
