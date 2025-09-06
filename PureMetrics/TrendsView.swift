import SwiftUI
import Charts

struct TrendsView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var selectedMetric: Metric = .systolic
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case threeMonths = "3 Months"
        case year = "Year"
    }
    
    enum Metric: String, CaseIterable {
        case systolic = "Systolic"
        case diastolic = "Diastolic"
        case heartRate = "Heart Rate"
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
                        VStack(spacing: 24) {
                            // Time Range Selector
                            timeRangeSelector
                            
                            // Metric Selector
                            metricSelector
                            
                            // Combined BP Chart
                            if !filteredSessions.isEmpty {
                                combinedChartSection
                            }
                            
                            // Individual Metric Chart
                            if !filteredSessions.isEmpty {
                                chartSection
                            } else {
                                emptyStateView
                            }
                            
                            // Statistics Summary
                            if !filteredSessions.isEmpty {
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
                            
                            Text("Blood Pressure Analysis")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
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
                
                Text("Metric")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Picker("Metric", selection: $selectedMetric) {
                ForEach(Metric.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
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
    
    // MARK: - Combined Chart Section
    
    private var combinedChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Systolic", dataPoint.systolic)
                    )
                    .foregroundStyle(.red)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Systolic", dataPoint.systolic)
                    )
                    .foregroundStyle(.red)
                    .symbolSize(50)
                    
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Diastolic", dataPoint.diastolic)
                    )
                    .foregroundStyle(.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
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
        VStack(alignment: .leading, spacing: 16) {
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
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value(selectedMetric.rawValue, dataPoint.value)
                    )
                    .foregroundStyle(chartColor)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
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
            
            Text("Start recording your blood pressure to see trends over time.")
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
    
    // MARK: - Statistics Summary
    
    private var statisticsSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    title: "Sessions",
                    value: "\(filteredSessions.count)",
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
        filteredSessions.map { session in
            let value: Double
            switch selectedMetric {
            case .systolic:
                value = session.averageSystolic
            case .diastolic:
                value = session.averageDiastolic
            case .heartRate:
                value = session.averageHeartRate ?? 0
            }
            
            return ChartDataPoint(
                date: session.startTime,
                value: value
            )
        }.sorted { $0.date < $1.date }
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

// MARK: - Preview

struct TrendsView_Previews: PreviewProvider {
    static var previews: some View {
        TrendsView(dataManager: BPDataManager())
    }
}
