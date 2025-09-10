import SwiftUI

struct HealthMetricsListView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var searchText = ""
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with time range selector
                headerSection
                
                // Search bar
                searchSection
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Blood Pressure Section
                        if !filteredBloodPressureReadings.isEmpty {
                            healthMetricSection(
                                title: "Blood Pressure",
                                icon: "heart.fill",
                                color: .red,
                                data: bloodPressureData
                            )
                        }
                        
                        // Heart Rate Section
                        if !filteredHeartRateData.isEmpty {
                            healthMetricSection(
                                title: "Heart Rate",
                                icon: "heart.circle.fill",
                                color: .pink,
                                data: heartRateData
                            )
                        }
                        
                        // Weight Section
                        if !filteredWeightData.isEmpty {
                            healthMetricSection(
                                title: "Weight",
                                icon: "scalemass.fill",
                                color: .blue,
                                data: weightData
                            )
                        }
                        
                        // Blood Sugar Section
                        if !filteredBloodSugarData.isEmpty {
                            healthMetricSection(
                                title: "Blood Sugar",
                                icon: "drop.fill",
                                color: .green,
                                data: bloodSugarData
                            )
                        }
                        
                        // Fitness Section
                        if !filteredFitnessData.isEmpty {
                            fitnessSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Health Metrics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Time Range")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Search Section
    
    private var searchSection: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search metrics...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
    
    // MARK: - Health Metric Section
    
    private func healthMetricSection(title: String, icon: String, color: Color, data: [HealthMetricData]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(data.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(data.prefix(5), id: \.id) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.formattedValue)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text(item.formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if let notes = item.notes, !notes.isEmpty {
                            Image(systemName: "note.text")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                if data.count > 5 {
                    Text("+ \(data.count - 5) more entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Fitness Section
    
    private var fitnessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Fitness")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(filteredFitnessData.count) workouts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 8) {
                ForEach(filteredFitnessData.prefix(5), id: \.id) { workout in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.exerciseType.rawValue)
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("\(workout.exerciseCount) exercises • \(workout.duration) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(workout.formattedDate)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                if filteredFitnessData.count > 5 {
                    Text("+ \(filteredFitnessData.count - 5) more workouts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Data Models
    
    struct HealthMetricData: Identifiable {
        let id = UUID()
        let value: Double
        let date: Date
        let notes: String?
        
        var formattedValue: String {
            if value.truncatingRemainder(dividingBy: 1) == 0 {
                return "\(Int(value))"
            } else {
                return String(format: "%.1f", value)
            }
        }
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    struct FitnessData: Identifiable {
        let id = UUID()
        let exerciseType: ExerciseType
        let exerciseCount: Int
        let duration: Int
        let date: Date
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredBloodPressureReadings: [BloodPressureReading] {
        let readings = dataManager.sessions.flatMap { $0.readings }
        let filtered = filterByTimeRange(readings)
        return searchText.isEmpty ? filtered : filtered.filter { reading in
            reading.displayString.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredHeartRateData: [HealthMetricData] {
        let data = dataManager.healthMetrics.filter { $0.type == .heartRate }.map { metric in
            HealthMetricData(value: metric.value, date: metric.timestamp, notes: nil)
        }
        let filtered = filterByTimeRange(data)
        return searchText.isEmpty ? filtered : filtered.filter { item in
            item.formattedValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredWeightData: [HealthMetricData] {
        let data = dataManager.healthMetrics.filter { $0.type == .weight }.map { metric in
            HealthMetricData(value: metric.value, date: metric.timestamp, notes: nil)
        }
        let filtered = filterByTimeRange(data)
        return searchText.isEmpty ? filtered : filtered.filter { item in
            item.formattedValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredBloodSugarData: [HealthMetricData] {
        let data = dataManager.healthMetrics.filter { $0.type == .bloodSugar }.map { metric in
            HealthMetricData(value: metric.value, date: metric.timestamp, notes: nil)
        }
        let filtered = filterByTimeRange(data)
        return searchText.isEmpty ? filtered : filtered.filter { item in
            item.formattedValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredFitnessData: [FitnessData] {
        let data = dataManager.fitnessSessions.map { session in
            FitnessData(
                exerciseType: .benchPress, // You might want to track this in your fitness session
                exerciseCount: session.exerciseSessions.count,
                duration: Int(session.duration / 60), // Convert to minutes
                date: session.startTime
            )
        }
        return filterByTimeRange(data)
    }
    
    private var bloodPressureData: [HealthMetricData] {
        filteredBloodPressureReadings.map { reading in
            HealthMetricData(
                value: Double(reading.systolic),
                date: reading.timestamp,
                notes: nil
            )
        }
    }
    
    private var heartRateData: [HealthMetricData] {
        filteredHeartRateData
    }
    
    private var weightData: [HealthMetricData] {
        filteredWeightData
    }
    
    private var bloodSugarData: [HealthMetricData] {
        filteredBloodSugarData
    }
    
    // MARK: - Helper Methods
    
    private func filterByTimeRange<T>(_ data: [T]) -> [T] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .week:
            let weekAgo = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            return data.filter { item in
                if let reading = item as? BloodPressureReading {
                    return reading.timestamp >= weekAgo
                } else if let healthData = item as? HealthMetricData {
                    return healthData.date >= weekAgo
                } else if let fitnessData = item as? FitnessData {
                    return fitnessData.date >= weekAgo
                }
                return true
            }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return data.filter { item in
                if let reading = item as? BloodPressureReading {
                    return reading.timestamp >= monthAgo
                } else if let healthData = item as? HealthMetricData {
                    return healthData.date >= monthAgo
                } else if let fitnessData = item as? FitnessData {
                    return fitnessData.date >= monthAgo
                }
                return true
            }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return data.filter { item in
                if let reading = item as? BloodPressureReading {
                    return reading.timestamp >= yearAgo
                } else if let healthData = item as? HealthMetricData {
                    return healthData.date >= yearAgo
                } else if let fitnessData = item as? FitnessData {
                    return fitnessData.date >= yearAgo
                }
                return true
            }
        case .all:
            return data
        }
    }
}

#Preview {
    HealthMetricsListView(dataManager: BPDataManager())
}
