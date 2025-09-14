import SwiftUI

struct HistoryView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var showingDeleteAlert = false
    @State private var sessionToDelete: BPSession?
    @State private var showingAllSessions = false
    
    var body: some View {
        NavigationView {
            Group {
                if dataManager.sessions.isEmpty {
                    emptyStateView
                } else {
                    sessionsListView
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Delete Session", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let session = sessionToDelete {
                    deleteSession(session)
                }
            }
        } message: {
            Text("Are you sure you want to delete this session? This action cannot be undone.")
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square")
                .font(.system(size: 60))
                .foregroundColor(.blue.opacity(0.6))
            
            Text("No Sessions Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Start tracking your blood pressure by adding your first reading in the main view.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Sessions List View
    
    private var sessionsListView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(displayedSessions) { session in
                    sessionRow(session: session)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Delete", role: .destructive) {
                                sessionToDelete = session
                                showingDeleteAlert = true
                            }
                        }
                }
            }
            .listStyle(PlainListStyle())
            
            // Show "See All" button if there are more sessions
            if sortedSessions.count > 5 {
                Button(action: {
                    showingAllSessions.toggle()
                }) {
                    HStack {
                        Text(showingAllSessions ? "Show Less" : "See All (\(sortedSessions.count) sessions)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Image(systemName: showingAllSessions ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var sortedSessions: [BPSession] {
        dataManager.sessions.sorted { $0.startTime > $1.startTime }
    }
    
    private var displayedSessions: [BPSession] {
        if showingAllSessions {
            return sortedSessions
        } else {
            return Array(sortedSessions.prefix(5))
        }
    }
    
    // MARK: - Session Row
    
    private func sessionRow(session: BPSession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with date and time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.startTime, style: .date)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(session.startTime, style: .time)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(session.readings.count) reading\(session.readings.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let endTime = session.endTime {
                        Text("Duration: \(formatDuration(session.duration))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Average values
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Average")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("\(Int(session.averageSystolic.rounded()))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Systolic")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("/")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading) {
                            Text("\(Int(session.averageDiastolic.rounded()))")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text("Diastolic")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let avgHeartRate = session.averageHeartRate {
                            VStack(alignment: .leading) {
                                Text("\(Int(avgHeartRate.rounded()))")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)
                                Text("HR")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
            }
            
            // Individual readings (if more than 1)
            if session.readings.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Readings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(session.readings) { reading in
                                readingChip(reading: reading)
                            }
                        }
                        .padding(.horizontal, 1)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .gray.opacity(0.1), radius: 2, x: 0, y: 1)
        )
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
    
    // MARK: - Reading Chip
    
    private func readingChip(reading: BloodPressureReading) -> some View {
        VStack(spacing: 2) {
            Text(reading.displayString)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(reading.timestamp, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
        )
    }
    
    // MARK: - Helper Functions
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func deleteSession(_ session: BPSession) {
        dataManager.deleteSession(by: session.id)
    }
}

// MARK: - Preview

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = BPDataManager()
        
        // Add some sample data for preview
        let sampleSession1 = BPSession()
        var sampleSession2 = BPSession()
        
        // Add sample readings
        _ = dataManager.addReading(systolic: 120, diastolic: 80, heartRate: 72)
        _ = dataManager.addReading(systolic: 118, diastolic: 78, heartRate: 70)
        dataManager.saveCurrentSession()
        
        return HistoryView(dataManager: dataManager)
    }
}
