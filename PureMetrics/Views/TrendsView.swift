import SwiftUI
import Charts
import Combine

struct TrendsView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetric: Metric = .bloodPressure
    @State private var cancellables = Set<AnyCancellable>()
    
    
    enum Metric: String, CaseIterable {
        case bloodPressure = "Blood Pressure"
        case heartRate = "Heart Rate"
        case weight = "Weight"
        case bloodSugar = "Blood Sugar"
        case bodyFatPercentage = "Body Fat %"
        case leanBodyMass = "Lean Body Mass"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // Header Section
                        headerSection
                        
                        // Content
                        VStack(spacing: 16) {
                            // Time Range Selector
                            timeRangeSelector
                            
                            // Metric Selector
                            metricSelector
                            
                            
                            
                            // Combined BP Chart (only show for BP metrics)
                            if !filteredSessions.isEmpty && selectedMetric == .bloodPressure {
                                combinedChartSection
                            }
                            
                            // Individual Metric Chart
                            if !chartData.isEmpty {
                                chartSection
                            } else {
                                emptyStateView
                            }
                            
                            // Rolling Averages (only for BP metrics)
                            if !dataManager.sessions.isEmpty && selectedMetric == .bloodPressure {
                                rollingAveragesSection
                            }
                            
                            
                            // Statistics Summary
                            if !chartData.isEmpty {
                                statisticsSummary
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onChange(of: selectedMetric) { _ in
                if selectedMetric == .weight || selectedMetric == .bodyFatPercentage || selectedMetric == .leanBodyMass {
                    fetchHealthKitData()
                } else {
                    healthKitDataPoints = []
                }
            }
            .onChange(of: selectedTimeRange) { _ in
                if selectedMetric == .weight || selectedMetric == .bodyFatPercentage || selectedMetric == .leanBodyMass {
                    fetchHealthKitData()
                }
            }
            .onAppear {
                if selectedMetric == .weight || selectedMetric == .bodyFatPercentage || selectedMetric == .leanBodyMass {
                    fetchHealthKitData()
                }
                setupRealTimeWeightMonitoring()
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Top gradient header
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 80)
            .overlay(
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PureMetrics")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(headerSubtitle)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    Spacer()
                }
            )
            
            // White rounded bottom
            Rectangle()
                .fill(Color(.systemGroupedBackground))
                .frame(height: 20)
                .clipShape(
                    .rect(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 24,
                        bottomTrailingRadius: 24,
                        topTrailingRadius: 0
                    )
                )
        }
    }
    
    // MARK: - Time Range Selector
    
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Time Range")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Data History Button
                NavigationLink(destination: DataHistoryView(dataManager: dataManager)) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 14, weight: .medium))
                        Text("See History")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Metric Selector
    
    private var metricSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Health Metrics")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Metric.allCases, id: \.self) { metric in
                    MetricCard(
                        metric: metric,
                        isSelected: selectedMetric == metric,
                        color: metricColor(metric)
                    ) {
                        selectedMetric = metric
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    
    // MARK: - Combined Chart Section
    
    private var combinedChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Blood Pressure Overview")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
                Chart {
                    ForEach(combinedChartData, id: \.date) { dataPoint in
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Systolic", dataPoint.systolic)
                        )
                        .foregroundStyle(.red)
                        .symbolSize(50)

                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Diastolic", dataPoint.diastolic)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(50)
                    }
                }
            .frame(height: 250)
            .chartYScale(domain: 60...180)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                        }
                    }
                }
            }
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Text("Systolic")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 12, height: 12)
                    Text("Diastolic")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Chart Section
    
    private var chartView: some View {
        Chart {
            ForEach(chartData, id: \.date) { dataPoint in
                if selectedMetric == .bloodPressure || selectedMetric == .heartRate {
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(selectedMetric.rawValue, dataPoint.value)
                    )
                    .foregroundStyle(chartColor)
                    .symbolSize(50)
                } else {
                    BarMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(selectedMetric.rawValue, dataPoint.value)
                    )
                    .foregroundStyle(chartColor)
                    .cornerRadius(4)
                }
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(String(format: "%.0f", doubleValue))
                    }
                }
            }
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title2)
                    .foregroundColor(chartColor)
                
                Text("\(selectedMetric.rawValue) Trend")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            chartView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    
    // MARK: - Empty State View
    
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Data Available")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    
    // MARK: - Rolling Averages Section
    
    private var rollingAveragesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Rolling Averages")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            let rollingAverages = dataManager.getRollingAverages()
            
            if rollingAverages.isEmpty {
                Text("Not enough data for rolling averages")
                    .foregroundColor(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(rollingAverages) { average in
                        RollingAverageCard(average: average)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Statistics Summary
    
    private var statisticsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Summary")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                SummaryCard(
                    title: "Average",
                    value: String(format: "%.0f", averageValue),
                    color: chartColor
                )
                
                SummaryCard(
                    title: "Highest",
                    value: String(format: "%.0f", maxValue),
                    color: chartColor
                )
                
                SummaryCard(
                    title: "Lowest",
                    value: String(format: "%.0f", minValue),
                    color: chartColor
                )
                
                SummaryCard(
                    title: selectedMetric == .weight || selectedMetric == .bloodSugar ? "Readings" : 
                           selectedMetric == .bodyFatPercentage || selectedMetric == .leanBodyMass ? "Days Tracked" : "Sessions",
                    value: "\(chartData.count)",
                    color: chartColor
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    
    // MARK: - Computed Properties
    
    private var filteredSessions: [BPSession] {
        let calendar = Calendar.current
        let now = Date()
        
        let cutoffDate: Date
        switch selectedTimeRange {
        case .week:
            cutoffDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            cutoffDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            cutoffDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return dataManager.sessions.filter { $0.startTime >= cutoffDate }
    }
    
    private var chartData: [ChartDataPoint] {
        switch selectedMetric {
        case .bloodPressure, .heartRate:
            // Use BP session data for these metrics
            return filteredSessions.map { session in
                let value: Double
                switch selectedMetric {
                case .bloodPressure:
                    // For blood pressure, we'll use systolic as the primary value for the individual chart
                    // The combined chart will show both systolic and diastolic
                    value = session.averageSystolic
                case .heartRate:
                    value = session.averageHeartRate ?? 0
                default:
                    value = 0
                }
                
                return ChartDataPoint(
                    date: session.startTime,
                    value: value
                )
            }.sorted { $0.date < $1.date }
            
        case .weight, .bloodSugar:
            // Use health metrics data for these metrics
            let calendar = Calendar.current
            let now = Date()
            
            let cutoffDate: Date
            switch selectedTimeRange {
            case .week:
                cutoffDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            case .month:
                cutoffDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case .threeMonths:
                cutoffDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            case .year:
                cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
            }
            
            let metricType: MetricType
            switch selectedMetric {
            case .weight:
                metricType = .weight
            case .bloodSugar:
                metricType = .bloodSugar
            default:
                metricType = .weight
            }
            
            return dataManager.getHealthMetricsForDateRange(cutoffDate, now)
                .filter { $0.type == metricType }
                .map { metric in
                    ChartDataPoint(
                        date: metric.timestamp,
                        value: metric.value
                    )
                }.sorted { $0.date < $1.date }
            
        case .bodyFatPercentage, .leanBodyMass:
            // Use HealthKit data for these metrics
            return getHealthKitChartData()
        }
    }
    
    private var combinedChartData: [CombinedChartDataPoint] {
        filteredSessions.map { session in
            CombinedChartDataPoint(
                date: session.startTime,
                systolic: session.averageSystolic,
                diastolic: session.averageDiastolic
            )
        }.sorted { $0.date < $1.date }
    }
    
    private var chartColor: Color {
        switch selectedMetric {
        case .bloodPressure:
            return .red
        case .heartRate:
            return .green
        case .weight:
            return .purple
        case .bloodSugar:
            return .orange
        case .bodyFatPercentage:
            return .pink
        case .leanBodyMass:
            return .cyan
        }
    }
    
    
    private var averageValue: Double {
        guard !chartData.isEmpty else { return 0 }
        return chartData.map { $0.value }.reduce(0, +) / Double(chartData.count)
    }
    
    private var maxValue: Double {
        chartData.map { $0.value }.max() ?? 0
    }
    
    private var minValue: Double {
        chartData.map { $0.value }.min() ?? 0
    }
    
    private var yAxisRange: ClosedRange<Double> {
        switch selectedMetric {
        case .bloodPressure:
            return 60...180
        case .heartRate:
            return 40...120
        case .weight:
            let minWeight = minValue > 0 ? minValue - 10 : 100
            let maxWeight = maxValue > 0 ? maxValue + 10 : 200
            return minWeight...maxWeight
        case .bloodSugar:
            return 60...200
        case .bodyFatPercentage:
            let minBodyFat = minValue > 0 ? minValue - 2 : 0
            let maxBodyFat = maxValue > 0 ? maxValue + 2 : 25
            return minBodyFat...maxBodyFat
        case .leanBodyMass:
            let minLeanBodyMass = minValue > 0 ? minValue - 5 : 0
            let maxLeanBodyMass = maxValue > 0 ? maxValue + 5 : 200
            return minLeanBodyMass...maxLeanBodyMass
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedMetric {
        case .bloodPressure, .heartRate:
            return "Start recording your blood pressure to see trends over time."
        case .weight:
            return "Start recording your weight to see trends over time."
        case .bloodSugar:
            return "Start recording your blood sugar to see trends over time."
        case .bodyFatPercentage:
            return "Enable Apple Health integration to see your body fat trends."
        case .leanBodyMass:
            return "Enable Apple Health integration to see your lean body mass trends."
        }
    }
    
    private var headerSubtitle: String {
        return "Health Trends"
    }
    
    private func metricColor(_ metric: Metric) -> Color {
        switch metric {
        case .bloodPressure:
            return .red
        case .heartRate:
            return .green
        case .weight:
            return .purple
        case .bloodSugar:
            return .orange
        case .bodyFatPercentage:
            return .pink
        case .leanBodyMass:
            return .cyan
        }
    }
    
    // MARK: - HealthKit Status Section
    
    private var healthKitStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("Apple Health Status")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            if dataManager.healthKitManager.isHealthKitEnabled {
                if dataManager.healthKitManager.isAuthorized {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Connected to Apple Health")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        // Current values and data status
                        VStack(spacing: 12) {
                            if isLoadingHealthKitData {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Loading \(selectedMetric.rawValue.lowercased()) data...")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            } else if !healthKitDataPoints.isEmpty {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Found \(healthKitDataPoints.count) data points")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button("Refresh") {
                                        fetchHealthKitData()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            } else {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text("No \(selectedMetric.rawValue.lowercased()) data found in selected time range")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button("Refresh") {
                                        fetchHealthKitData()
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            
                            // Current day values
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                if selectedMetric == .weight {
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text("Current Weight")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            if dataManager.bmrManager.isWeightSyncingEnabled {
                                                Image(systemName: "arrow.triangle.2.circlepath")
                                                    .font(.caption2)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        
                                        Text(dataManager.healthKitManager.formattedCurrentWeight)
                                            .font(.title3)
                                            .fontWeight(.bold)
                                            .foregroundColor(.purple)
                                        
                                        if dataManager.bmrManager.isWeightSyncingEnabled {
                                            Text("Auto-syncing from Apple Health")
                                                .font(.caption2)
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Authorization Required")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Spacer()
                        }
                        
                        Text("Enable Apple Health access to view your \(selectedMetric.rawValue.lowercased()) trends.")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Button("Enable Health Access") {
                            dataManager.healthKitManager.requestAuthorization()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "heart.slash")
                            .foregroundColor(.gray)
                        Text("Apple Health Disabled")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    
                    Text("Enable Apple Health integration to view your \(selectedMetric.rawValue.lowercased()) trends.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Button("Enable Health Data") {
                        dataManager.healthKitManager.toggleHealthKit()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - HealthKit Status Card
    
    private var healthKitStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: dataManager.healthKitManager.isHealthKitEnabled ? "heart.fill" : "heart.slash")
                    .foregroundColor(dataManager.healthKitManager.isHealthKitEnabled ? .red : .gray)
                
                Text("Apple Health Integration")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if !dataManager.healthKitManager.isHealthKitEnabled {
                VStack(spacing: 8) {
                    Text("HealthKit is not enabled")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Enable Apple Health integration to view your health data trends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Enable HealthKit") {
                        dataManager.healthKitManager.isHealthKitEnabled = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else if !dataManager.healthKitManager.isAuthorized {
                VStack(spacing: 8) {
                    Text("HealthKit permissions needed")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Grant permissions to access your health data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Grant Permissions") {
                        dataManager.healthKitManager.requestAuthorization()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    Text("HealthKit connected")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    // MARK: - HealthKit Data Functions
    
    @State private var healthKitDataPoints: [ChartDataPoint] = []
    @State private var isLoadingHealthKitData = false
    
    private func getHealthKitChartData() -> [ChartDataPoint] {
        return healthKitDataPoints
    }
    
    private func fetchHealthKitData() {
        print("=== FETCH HEALTHKIT DATA CALLED ===")
        print("Selected metric: \(selectedMetric)")
        print("HealthKit authorized: \(dataManager.healthKitManager.isAuthorized)")
        print("HealthKit enabled: \(dataManager.healthKitManager.isHealthKitEnabled)")
        
        // For HealthKit metrics, always try to fetch data (simulator will return sample data)
        guard selectedMetric == .weight || selectedMetric == .bodyFatPercentage || selectedMetric == .leanBodyMass else {
            print("Not a HealthKit metric, returning")
            return
        }
        
        isLoadingHealthKitData = true
        
        let calendar = Calendar.current
        let now = Date()
        
        let cutoffDate: Date
        switch selectedTimeRange {
        case .week:
            cutoffDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            cutoffDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            cutoffDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        switch selectedMetric {
        case .weight:
            dataManager.healthKitManager.fetchHistoricalWeightData(from: cutoffDate, to: now) { dataPoints in
                self.healthKitDataPoints = dataPoints.map { point in
                    ChartDataPoint(date: point.date, value: point.value)
                }
                self.isLoadingHealthKitData = false
            }
        case .bodyFatPercentage:
            dataManager.healthKitManager.fetchHistoricalBodyFatPercentageData(from: cutoffDate, to: now) { dataPoints in
                self.healthKitDataPoints = dataPoints.map { point in
                    ChartDataPoint(date: point.date, value: point.value)
                }
                self.isLoadingHealthKitData = false
            }
        case .leanBodyMass:
            dataManager.healthKitManager.fetchHistoricalLeanBodyMassData(from: cutoffDate, to: now) { dataPoints in
                self.healthKitDataPoints = dataPoints.map { point in
                    ChartDataPoint(date: point.date, value: point.value)
                }
                self.isLoadingHealthKitData = false
            }
        default:
            healthKitDataPoints = []
            isLoadingHealthKitData = false
        }
    }
    
    private func setupRealTimeWeightMonitoring() {
        // Monitor weight changes and refresh trends when weight is selected
        dataManager.healthKitManager.$currentWeight
            .sink { weight in
                // Only refresh if weight metric is selected and we have a valid weight
                if self.selectedMetric == .weight && weight > 0 {
                    print("Weight changed to \(weight) lbs, refreshing trends...")
                    
                    // Add current weight as today's data point if it's not already there
                    self.addCurrentWeightToTrends()
                    
                    // Refresh the historical data to get the latest trends
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.fetchHealthKitData()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func addCurrentWeightToTrends() {
        let currentWeight = dataManager.healthKitManager.currentWeight
        guard currentWeight > 0 else { return }
        
        let today = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: today)
        
        // Check if we already have today's weight in the data
        let hasTodaysWeight = healthKitDataPoints.contains { dataPoint in
            calendar.isDate(dataPoint.date, inSameDayAs: today)
        }
        
        // Add today's weight if we don't have it yet
        if !hasTodaysWeight {
            let newDataPoint = ChartDataPoint(date: startOfDay, value: currentWeight)
            healthKitDataPoints.append(newDataPoint)
            
            // Sort by date to maintain chronological order
            healthKitDataPoints.sort { $0.date < $1.date }
            
            print("Added current weight (\(currentWeight) lbs) to trends data")
        }
    }
    
}

// MARK: - Chart Data Point

struct ChartDataPoint {
    let date: Date
    let value: Double
}

struct CombinedChartDataPoint {
    let date: Date
    let systolic: Double
    let diastolic: Double
}

// MARK: - Rolling Average Card Component

struct RollingAverageCard: View {
    let average: RollingAverage
    
    var body: some View {
        VStack(spacing: 8) {
            // Period Label
            Text(average.periodLabel)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            // BP Values
            Text(average.displayString)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // BP Category
            Text(average.bpCategory.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(average.bpCategory.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(average.bpCategory.color.opacity(0.1))
                )
            
            // Reading Count
            Text("\(average.readingCount) readings")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Summary Card Component

struct SummaryCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}


// MARK: - Metric Card Component

struct MetricCard: View {
    let metric: TrendsView.Metric
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                // Label
                Text(metric.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color, lineWidth: isSelected ? 0 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
}

// MARK: - Preview

struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        TrendsView(dataManager: BPDataManager())
    }
}
