import SwiftUI
import UniformTypeIdentifiers

struct DataHistoryView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedDataType: DataType = .all
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    @State private var showingShareSheet = false
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case all = "All Time"
    }
    
    enum DataType: String, CaseIterable {
        case all = "All Data"
        case bloodPressure = "Blood Pressure"
        case fitness = "Fitness"
        case nutrition = "Nutrition"
        case healthKit = "Health Data"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with filters
                headerSection
                
                // Content
                ScrollView {
                    LazyVStack(spacing: 16) {
                        // Blood Pressure Section
                        if selectedDataType == .all || selectedDataType == .bloodPressure {
                            bloodPressureSection
                        }
                        
                        // Fitness Section
                        if selectedDataType == .all || selectedDataType == .fitness {
                            fitnessSection
                        }
                        
                        // Nutrition Section
                        if selectedDataType == .all || selectedDataType == .nutrition {
                            nutritionSection
                        }
                        
                        // HealthKit Section
                        if selectedDataType == .all || selectedDataType == .healthKit {
                            healthKitSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Data History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export CSV") {
                        exportToCSV()
                    }
                    .disabled(filteredData.isEmpty)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let exportData = exportData {
                    ShareSheet(activityItems: [exportData])
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Time Range Picker
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Data Type Picker
            Picker("Data Type", selection: $selectedDataType) {
                ForEach(DataType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    // MARK: - Blood Pressure Section
    
    private var bloodPressureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("Blood Pressure")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(filteredBloodPressureReadings.count) readings")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if filteredBloodPressureReadings.isEmpty {
                Text("No blood pressure readings found")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredBloodPressureReadings) { reading in
                        BloodPressureRow(reading: reading)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Fitness Section
    
    private var fitnessSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(.blue)
                Text("Fitness Sessions")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(filteredFitnessSessions.count) sessions")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if filteredFitnessSessions.isEmpty {
                Text("No fitness sessions found")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredFitnessSessions) { session in
                        NavigationLink(destination: WorkoutDetailView(workout: session)
                            .environmentObject(dataManager)) {
                            FitnessSessionRow(session: session)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Nutrition Section
    
    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "fork.knife")
                    .foregroundColor(.green)
                Text("Nutrition Entries")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(filteredNutritionEntries.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if filteredNutritionEntries.isEmpty {
                Text("No nutrition entries found")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredNutritionEntries) { entry in
                        NutritionEntryRow(entry: entry)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - HealthKit Section
    
    private var healthKitSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                Text("Health Data")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("Today's data")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if dataManager.healthKitManager.isAuthorized {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    HealthDataCard(title: "Steps", value: dataManager.healthKitManager.formattedStepsToday, icon: "figure.walk")
                    HealthDataCard(title: "Distance", value: dataManager.healthKitManager.formattedWalkingDistance, icon: "location")
                    HealthDataCard(title: "Energy", value: dataManager.healthKitManager.formattedActiveEnergy, icon: "flame.fill")
                    HealthDataCard(title: "Heart Rate", value: dataManager.healthKitManager.formattedHeartRate, icon: "heart.fill")
                }
            } else {
                Text("Health data not available")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Computed Properties
    
    private var filteredBloodPressureReadings: [BloodPressureReading] {
        let readings = dataManager.sessions.flatMap { $0.readings }
        return filterByTimeRange(readings)
    }
    
    private var filteredFitnessSessions: [FitnessSession] {
        let sessions = dataManager.fitnessSessions
        return filterByTimeRange(sessions)
    }
    
    private var filteredNutritionEntries: [NutritionEntry] {
        let entries = dataManager.nutritionEntries
        return filterByTimeRange(entries)
    }
    
    private var filteredData: [Any] {
        var data: [Any] = []
        
        if selectedDataType == .all || selectedDataType == .bloodPressure {
            data.append(contentsOf: filteredBloodPressureReadings)
        }
        if selectedDataType == .all || selectedDataType == .fitness {
            data.append(contentsOf: filteredFitnessSessions)
        }
        if selectedDataType == .all || selectedDataType == .nutrition {
            data.append(contentsOf: filteredNutritionEntries)
        }
        
        return data
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
                } else if let session = item as? FitnessSession {
                    return session.startTime >= weekAgo
                } else if let entry = item as? NutritionEntry {
                    return entry.date >= weekAgo
                }
                return true
            }
        case .month:
            let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            return data.filter { item in
                if let reading = item as? BloodPressureReading {
                    return reading.timestamp >= monthAgo
                } else if let session = item as? FitnessSession {
                    return session.startTime >= monthAgo
                } else if let entry = item as? NutritionEntry {
                    return entry.date >= monthAgo
                }
                return true
            }
        case .year:
            let yearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            return data.filter { item in
                if let reading = item as? BloodPressureReading {
                    return reading.timestamp >= yearAgo
                } else if let session = item as? FitnessSession {
                    return session.startTime >= yearAgo
                } else if let entry = item as? NutritionEntry {
                    return entry.date >= yearAgo
                }
                return true
            }
        case .all:
            return data
        }
    }
    
    private func exportToCSV() {
        var csvContent = "Date,Type,Details\n"
        
        // Add Blood Pressure data
        for reading in filteredBloodPressureReadings {
            let date = DateFormatter.iso8601.string(from: reading.timestamp)
            csvContent += "\(date),Blood Pressure,\"Systolic: \(reading.systolic), Diastolic: \(reading.diastolic), Heart Rate: \(reading.heartRate ?? 0)\"\n"
        }
        
        // Add Fitness data
        for session in filteredFitnessSessions {
            let date = DateFormatter.iso8601.string(from: session.startTime)
            let duration = session.endTime?.timeIntervalSince(session.startTime) ?? 0
            csvContent += "\(date),Fitness Session,\"Duration: \(Int(duration/60)) min, Exercises: \(session.exerciseSessions.count)\"\n"
        }
        
        // Add Nutrition data
        for entry in filteredNutritionEntries {
            let date = DateFormatter.iso8601.string(from: entry.date)
            csvContent += "\(date),Nutrition,\"Calories: \(entry.calories), Protein: \(entry.protein)g, Carbs: \(entry.carbohydrates)g, Fat: \(entry.fat)g\"\n"
        }
        
        exportData = csvContent.data(using: .utf8)
        showingShareSheet = true
    }
}

// MARK: - Row Views

struct BloodPressureRow: View {
    let reading: BloodPressureReading
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(reading.systolic)/\(reading.diastolic) mmHg")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let heartRate = reading.heartRate {
                    Text("HR: \(heartRate) bpm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(DateFormatter.shortDate.string(from: reading.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(DateFormatter.shortTime.string(from: reading.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FitnessSessionRow: View {
    let session: FitnessSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fitness Session")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !session.exerciseSessions.isEmpty {
                    Text("\(session.exerciseSessions.count) exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Show exercise types
                    let exerciseTypes = session.exerciseSessions.map { $0.exerciseType.rawValue }
                    Text(exerciseTypes.joined(separator: ", "))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text("No exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(DateFormatter.shortDate.string(from: session.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let endTime = session.endTime {
                    let duration = Int(endTime.timeIntervalSince(session.startTime) / 60)
                    Text("\(duration) min")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("Incomplete")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
                
                // Show total sets
                let totalSets = session.exerciseSessions.reduce(0) { $0 + $1.sets.count }
                if totalSets > 0 {
                    Text("\(totalSets) sets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Add chevron to indicate it's clickable
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
}

struct NutritionEntryRow: View {
    let entry: NutritionEntry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Nutrition Entry")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(Int(entry.calories)) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(DateFormatter.shortDate.string(from: entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(DateFormatter.shortTime.string(from: entry.date))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct HealthDataCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Date Formatters

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()
    
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    DataHistoryView(dataManager: BPDataManager())
}
