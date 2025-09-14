import Foundation

// MARK: - Health Metric Types

enum MetricType: String, CaseIterable, Codable {
    case bloodPressure = "Blood Pressure"
    case weight = "Weight"
    case bloodSugar = "Blood Sugar"
    case heartRate = "Heart Rate"
    case bodyFat = "Body Fat %"
    
    var unit: String {
        switch self {
        case .bloodPressure: return "mmHg"
        case .weight: return "lbs"
        case .bloodSugar: return "mg/dL"
        case .heartRate: return "bpm"
        case .bodyFat: return "%"
        }
    }
    
    var color: String {
        switch self {
        case .bloodPressure: return "blue"
        case .weight: return "green"
        case .bloodSugar: return "orange"
        case .heartRate: return "red"
        case .bodyFat: return "purple"
        }
    }
    
    var icon: String {
        switch self {
        case .bloodPressure: return "heart.fill"
        case .weight: return "scalemass.fill"
        case .bloodSugar: return "drop.fill"
        case .heartRate: return "heart.circle.fill"
        case .bodyFat: return "figure.arms.open"
        }
    }
    
    var placeholder: String {
        switch self {
        case .bloodPressure: return "120/80"
        case .weight: return "150"
        case .bloodSugar: return "100"
        case .heartRate: return "72"
        case .bodyFat: return "15.0"
        }
    }
}

// MARK: - Health Metric Model

struct HealthMetric: Codable, Identifiable {
    let id = UUID()
    let type: MetricType
    let value: Double
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case type, value, timestamp
    }
    
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
        case .bodyFat:
            return value >= 1 && value <= 50
        }
    }
    
    var displayString: String {
        switch type {
        case .bloodPressure:
            return "\(Int(value)) \(type.unit)"
        case .weight, .bloodSugar, .heartRate, .bodyFat:
            return "\(Int(value)) \(type.unit)"
        }
    }
    
    var formattedValue: String {
        if type == .bloodPressure {
            return "\(Int(value))"
        } else if type == .weight || type == .bloodSugar || type == .bodyFat {
            return String(format: "%.1f", value)
        } else {
            return "\(Int(value))"
        }
    }
}

