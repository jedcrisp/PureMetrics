import Foundation

struct BPSession: Codable, Identifiable {
    let id: UUID
    var readings: [BloodPressureReading]
    var healthMetrics: [HealthMetric] // New: support for additional health metrics
    let startTime: Date
    var endTime: Date?
    var isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, readings, healthMetrics, startTime, endTime, isActive
    }
    
    init() {
        self.id = UUID()
        self.readings = []
        self.healthMetrics = []
        self.startTime = Date()
        self.endTime = nil
        self.isActive = false
    }
    
    init(startTime: Date) {
        self.id = UUID()
        self.readings = []
        self.healthMetrics = []
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
    
    // MARK: - Health Metrics Management
    
    mutating func addHealthMetric(_ metric: HealthMetric) {
        healthMetrics.append(metric)
    }
    
    mutating func removeHealthMetric(at index: Int) {
        guard index < healthMetrics.count else { return }
        healthMetrics.remove(at: index)
    }
    
    func getMetricsForType(_ type: MetricType) -> [HealthMetric] {
        return healthMetrics.filter { $0.type == type }
    }
    
    func getAverageForType(_ type: MetricType) -> Double? {
        let metrics = getMetricsForType(type)
        guard !metrics.isEmpty else { return nil }
        return metrics.map { $0.value }.reduce(0, +) / Double(metrics.count)
    }
    
    var allMetrics: [HealthMetric] {
        var all: [HealthMetric] = []
        
        // Add BP readings as health metrics
        for reading in readings {
            all.append(contentsOf: reading.toHealthMetrics())
        }
        
        // Add additional health metrics
        all.append(contentsOf: healthMetrics)
        
        return all.sorted { $0.timestamp < $1.timestamp }
    }
}
