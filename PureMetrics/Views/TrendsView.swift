import SwiftUI
import Charts

struct TrendsView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetric: Metric = .systolic
    @State private var selectedExerciseType: ExerciseType = .benchPress
    
    
    enum Metric: String, CaseIterable {
        case systolic = "Systolic"
        case diastolic = "Diastolic"
        case heartRate = "Heart Rate"
        case weight = "Weight"
        case bloodSugar = "Blood Sugar"
        case fitness = "Fitness"
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
                            
                            // Exercise Type Selector (only for fitness metric)
                            if selectedMetric == .fitness {
                                exerciseTypeSelector
                            }
                            
                            // Daily Readings Section
                            dailyReadingsSection
                            
                            // Combined BP Chart (only show for BP metrics)
                            if !filteredSessions.isEmpty && (selectedMetric == .systolic || selectedMetric == .diastolic) {
                                combinedChartSection
                            }
                            
                            // Individual Metric Chart
                            if selectedMetric == .fitness {
                                if !fitnessChartData.isEmpty {
                                    fitnessChartSection
                                } else {
                                    fitnessEmptyStateView
                                }
                            } else if !chartData.isEmpty {
                                chartSection
                            } else {
                                emptyStateView
                            }
                            
                            // Rolling Averages (only for BP metrics)
                            if !dataManager.sessions.isEmpty && (selectedMetric == .systolic || selectedMetric == .diastolic) {
                                rollingAveragesSection
                            }
                            
                            // Statistics Summary
                            if selectedMetric == .fitness {
                                if !fitnessChartData.isEmpty {
                                    fitnessSummarySection
                                }
                            } else if !chartData.isEmpty {
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
            .onChange(of: availableExercises) { newExercises in
                if !newExercises.isEmpty && !newExercises.contains(selectedExerciseType) {
                    selectedExerciseType = newExercises.first!
                }
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
            .frame(height: 120)
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
                        
                        HStack(spacing: 16) {
                            // Data History Button
                            NavigationLink(destination: DataHistoryView(dataManager: dataManager)) {
                                HStack(spacing: 6) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("See History")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.2))
                                )
                            }
                            
                            if !filteredSessions.isEmpty {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Sessions")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text("\(filteredSessions.count)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }
                            }
                        }
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
    
    // MARK: - Exercise Type Selector
    
    private var exerciseTypeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                
                Text("Exercise Type")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(availableExercises.count) exercises")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if availableExercises.isEmpty {
                Text("No fitness data available. Start tracking workouts to see trends.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                Picker("Exercise Type", selection: $selectedExerciseType) {
                    ForEach(availableExercises, id: \.self) { exerciseType in
                        Text(exerciseType.rawValue).tag(exerciseType)
                    }
                }
                .pickerStyle(MenuPickerStyle())
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
            
            Chart {
                ForEach(chartData, id: \.date) { dataPoint in
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(selectedMetric.rawValue, dataPoint.value)
                    )
                    .foregroundStyle(chartColor)
                    .symbolSize(50)
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
                        if let intValue = value.as(Int.self) {
                            Text("\(intValue)")
                        }
                    }
                }
            }
            .chartYScale(domain: yAxisRange)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Fitness Chart Section
    
    private var fitnessChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("\(selectedExerciseType.rawValue) Progress")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
                
                // Trend indicator
                if let analysis = fitnessTrendAnalysis {
                    HStack(spacing: 4) {
                        Image(systemName: analysis.overallTrend.icon)
                            .foregroundColor(analysis.overallTrend.color)
                        Text(analysis.weightChangeString)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(analysis.overallTrend.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(analysis.overallTrend.color.opacity(0.1))
                    )
                }
            }
            
            Chart {
                ForEach(fitnessChartData, id: \.date) { dataPoint in
                    // Average Weight Points
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Average Weight", dataPoint.averageWeight)
                    )
                    .foregroundStyle(.orange)
                    .symbolSize(50)
                    
                    // Max Weight Points
                    if dataPoint.maxWeight > dataPoint.averageWeight {
                        PointMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Max Weight", dataPoint.maxWeight)
                        )
                        .foregroundStyle(.red)
                        .symbolSize(40)
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
                        .fill(Color.orange)
                        .frame(width: 12, height: 12)
                    Text("Average Weight")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                    Text("Max Weight")
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
    
    // MARK: - Empty State View
    
    // MARK: - Daily Readings Section
    
    private var dailyReadingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Daily Readings")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            DailyReadingsView(dataManager: dataManager)
                .frame(height: 300)
        }
        .padding(.horizontal, 20)
    }
    
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
    
    // MARK: - Fitness Empty State View
    
    private var fitnessEmptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.6))
            
            Text("No Fitness Data")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            if availableExercises.isEmpty {
                Text("Start tracking your workouts to see progress over time.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("No \(selectedExerciseType.rawValue.lowercased()) data in the selected time range. Try a different exercise or time period.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
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
                    title: selectedMetric == .weight || selectedMetric == .bloodSugar ? "Readings" : "Sessions",
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
    
    // MARK: - Fitness Summary Section
    
    private var fitnessSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dumbbell.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("\(selectedExerciseType.rawValue) Summary")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            if let analysis = fitnessTrendAnalysis {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    FitnessSummaryCard(
                        title: "Average Weight",
                        value: String(format: "%.1f", analysis.averageWeight),
                        subtitle: "lbs",
                        color: .orange
                    )
                    
                    FitnessSummaryCard(
                        title: "Max Weight",
                        value: String(format: "%.1f", analysis.maxWeight),
                        subtitle: "lbs",
                        color: .red
                    )
                    
                    FitnessSummaryCard(
                        title: "Weight Change",
                        value: analysis.weightChangeString,
                        subtitle: analysis.overallTrend.description,
                        color: analysis.overallTrend.color
                    )
                    
                    FitnessSummaryCard(
                        title: "Sessions",
                        value: "\(analysis.totalSessions)",
                        subtitle: "workouts",
                        color: .blue
                    )
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
        case .systolic, .diastolic, .heartRate:
            // Use BP session data for these metrics
            return filteredSessions.map { session in
                let value: Double
                switch selectedMetric {
                case .systolic:
                    value = session.averageSystolic
                case .diastolic:
                    value = session.averageDiastolic
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
            
        case .fitness:
            return [] // Fitness data is handled separately
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
        case .systolic:
            return .red
        case .diastolic:
            return .blue
        case .heartRate:
            return .green
        case .weight:
            return .purple
        case .bloodSugar:
            return .orange
        case .fitness:
            return .orange
        }
    }
    
    private var fitnessChartData: [FitnessTrendData] {
        dataManager.getFitnessTrends(for: selectedExerciseType, timeRange: selectedTimeRange)
    }
    
    private var fitnessTrendAnalysis: FitnessTrendAnalysis? {
        dataManager.getFitnessTrendAnalysis(for: selectedExerciseType, timeRange: selectedTimeRange)
    }
    
    private var availableExercises: [ExerciseType] {
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
        
        let filteredSessions = dataManager.fitnessSessions.filter { $0.startTime >= cutoffDate }
        let exerciseTypes = Set(filteredSessions.flatMap { $0.exerciseSessions.map { $0.exerciseType } })
        
        return Array(exerciseTypes).sorted { $0.rawValue < $1.rawValue }
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
        case .systolic, .diastolic:
            return 60...180
        case .heartRate:
            return 40...120
        case .weight:
            let minWeight = minValue > 0 ? minValue - 10 : 100
            let maxWeight = maxValue > 0 ? maxValue + 10 : 200
            return minWeight...maxWeight
        case .bloodSugar:
            return 60...200
        case .fitness:
            return 0...100
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedMetric {
        case .systolic, .diastolic, .heartRate:
            return "Start recording your blood pressure to see trends over time."
        case .weight:
            return "Start recording your weight to see trends over time."
        case .bloodSugar:
            return "Start recording your blood sugar to see trends over time."
        case .fitness:
            return "Start tracking your workouts to see progress over time."
        }
    }
    
    private var headerSubtitle: String {
        switch selectedMetric {
        case .systolic, .diastolic:
            return "Blood Pressure Analysis"
        case .heartRate:
            return "Heart Rate Tracking"
        case .weight:
            return "Weight Tracking"
        case .bloodSugar:
            return "Blood Sugar Monitoring"
        case .fitness:
            return "Fitness Progress"
        }
    }
    
    private func metricColor(_ metric: Metric) -> Color {
        switch metric {
        case .systolic:
            return .red
        case .diastolic:
            return .blue
        case .heartRate:
            return .green
        case .weight:
            return .purple
        case .bloodSugar:
            return .orange
        case .fitness:
            return .orange
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

// MARK: - Fitness Summary Card Component

struct FitnessSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(color)
                    .multilineTextAlignment(.center)
            }
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
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
