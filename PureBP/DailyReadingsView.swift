import SwiftUI

struct DailyReadingsView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var selectedDate = Date()
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Date Selector
                dateSelectorSection
                
                // Content
                if sessionsForSelectedDate.isEmpty {
                    emptyStateView
                } else {
                    sessionsListSection
                }
            }
            .navigationTitle("Daily Readings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
            }
        }
    }
    
    // MARK: - Date Selector Section
    
    private var dateSelectorSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { showingDatePicker = true }) {
                    HStack {
                        Image(systemName: "calendar")
                        Text(selectedDate, style: .date)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                Text("\(sessionsForSelectedDate.count) session\(sessionsForSelectedDate.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Quick date navigation
            HStack(spacing: 12) {
                Button(action: previousDay) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button("Today") {
                    selectedDate = Date()
                }
                .foregroundColor(.blue)
                
                Spacer()
                
                Button(action: nextDay) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Sessions on \(selectedDate, style: .date)")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Try selecting a different date or start a new session.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Sessions List Section
    
    private var sessionsListSection: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(sessionsForSelectedDate) { session in
                    SessionDetailCard(session: session)
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    
    private var sessionsForSelectedDate: [BPSession] {
        let calendar = Calendar.current
        return dataManager.sessions.filter { session in
            calendar.isDate(session.startTime, inSameDayAs: selectedDate)
        }.sorted { $0.startTime > $1.startTime }
    }
    
    // MARK: - Helper Functions
    
    private func previousDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
    }
    
    private func nextDay() {
        selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
    }
}

// MARK: - Session Detail Card

struct SessionDetailCard: View {
    let session: BPSession
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Session Header
            Button(action: { isExpanded.toggle() }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.startTime, style: .time)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("\(session.readings.count) reading\(session.readings.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(session.displayString)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        
                        if let endTime = session.endTime {
                            let duration = endTime.timeIntervalSince(session.startTime)
                            Text("Duration: \(formatDuration(duration))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content
            if isExpanded {
                Divider()
                
                VStack(spacing: 12) {
                    // Session Average
                    sessionAverageSection
                    
                    // Individual Readings
                    individualReadingsSection
                }
                .padding()
                .background(Color.gray.opacity(0.05))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Session Average Section
    
    private var sessionAverageSection: some View {
        VStack(spacing: 12) {
            Text("Session Average")
                .font(.headline)
                .foregroundColor(.primary)
            
            HStack(spacing: 24) {
                VStack {
                    Text("\(Int(session.averageSystolic.rounded()))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("Systolic")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("/")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                VStack {
                    Text("\(Int(session.averageDiastolic.rounded()))")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Diastolic")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let avgHeartRate = session.averageHeartRate {
                    VStack {
                        Text("\(Int(avgHeartRate.rounded()))")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("HR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    // MARK: - Individual Readings Section
    
    private var individualReadingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Individual Readings")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 8) {
                ForEach(session.readings) { reading in
                    ReadingDetailRow(reading: reading)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Reading Detail Row

struct ReadingDetailRow: View {
    let reading: BloodPressureReading
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reading.displayString)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(reading.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // BP Category Indicator
            BPCategoryIndicator(systolic: reading.systolic, diastolic: reading.diastolic)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 1, x: 0, y: 1)
        )
    }
}

// MARK: - BP Category Indicator

struct BPCategoryIndicator: View {
    let systolic: Int
    let diastolic: Int
    
    var body: some View {
        VStack(spacing: 2) {
            Text(category)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(categoryColor)
                )
        }
    }
    
    private var category: String {
        if systolic < 120 && diastolic < 80 {
            return "Normal"
        } else if systolic < 130 && diastolic < 80 {
            return "Elevated"
        } else if systolic < 140 || diastolic < 90 {
            return "Stage 1"
        } else if systolic < 180 || diastolic < 120 {
            return "Stage 2"
        } else {
            return "Crisis"
        }
    }
    
    private var categoryColor: Color {
        switch category {
        case "Normal":
            return .green
        case "Elevated":
            return .yellow
        case "Stage 1":
            return .orange
        case "Stage 2":
            return .red
        case "Crisis":
            return .purple
        default:
            return .gray
        }
    }
}

// MARK: - Date Picker Sheet

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct DailyReadingsView_Previews: PreviewProvider {
    static var previews: some View {
        DailyReadingsView(dataManager: BPDataManager())
    }
}
