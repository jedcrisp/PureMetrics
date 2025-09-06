import SwiftUI

struct SessionView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var systolic = ""
    @State private var diastolic = ""
    @State private var heartRate = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var sessionTimer: Timer?
    @State private var sessionDuration: TimeInterval = 0
    @State private var useManualTime = false
    @State private var manualDate = Date()
    @State private var manualTime = Date()
    
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
                        
                        // Session Control
                        sessionControlSection
                        
                        // Session Content
                        if dataManager.currentSession.isActive {
                            VStack(spacing: 24) {
                                // Session Info
                                sessionInfoSection
                                
                                // Entry Form - Made more prominent
                                entryFormSection
                                
                                // Current Readings
                                currentReadingsSection
                                
                                // Session Average
                                if !dataManager.currentSession.readings.isEmpty {
                                    sessionAverageSection
                                }
                                
                                // Action Buttons
                                actionButtonsSection
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            if dataManager.currentSession.isActive {
                startSessionTimer()
            }
        }
        .onDisappear {
            stopSessionTimer()
        }
        .onChange(of: dataManager.currentSession.isActive) { isActive in
            if isActive {
                startSessionTimer()
            } else {
                stopSessionTimer()
            }
        }
        .alert("Invalid Reading", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
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
                            Text("PureBP")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Blood Pressure Tracker")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        if dataManager.currentSession.isActive {
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Session Active")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(formatDuration(sessionDuration))
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
    
    // MARK: - Session Control Section
    
    private var sessionControlSection: some View {
        VStack(spacing: 20) {
            if !dataManager.currentSession.isActive {
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Ready to Track")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Start a new session to begin recording your blood pressure readings")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: startSession) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                            Text("Start New Session")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.green.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                        .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
                )
                .padding(.horizontal, 20)
            } else {
                HStack(spacing: 12) {
                    Button(action: stopSession) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red)
                        )
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                    
                    Button(action: saveSession) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save & Complete")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(canSaveSession ? Color.blue : Color.gray)
                        )
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                    }
                    .disabled(!canSaveSession)
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - Session Info Section
    
    private var sessionInfoSection: some View {
        HStack(spacing: 20) {
            // Readings Count
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Text("\(dataManager.currentSession.readings.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 2) {
                    Text("Readings")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("of 5")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Session Duration
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                }
                
                VStack(spacing: 2) {
                    Text("Duration")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(formatDuration(sessionDuration))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
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
    
    // MARK: - Entry Form Section
    
    private var entryFormSection: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    
                    Text("Add Blood Pressure Reading")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                Text("Enter your systolic and diastolic values")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // BP Input Fields
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    // Systolic
                    VStack(spacing: 12) {
                        HStack {
                            Text("Systolic")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            
                            Spacer()
                            
                            Text("mmHg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        TextField("120", text: $systolic)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.red.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.red.opacity(0.2), lineWidth: 1.5)
                                    )
                            )
                    }
                    
                    // Divider
                    VStack {
                        Spacer()
                        Text("/")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    // Diastolic
                    VStack(spacing: 12) {
                        HStack {
                            Text("Diastolic")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            
                            Spacer()
                            
                            Text("mmHg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        TextField("80", text: $diastolic)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .padding(.vertical, 20)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.blue.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.blue.opacity(0.2), lineWidth: 1.5)
                                    )
                            )
                    }
                }
                
                // Heart Rate
                VStack(spacing: 12) {
                    HStack {
                        Text("Heart Rate")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text("bpm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("(Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    TextField("72", text: $heartRate)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.green.opacity(0.2), lineWidth: 1.5)
                                )
                        )
                }
            }
            
            // Manual Date/Time Selection
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Use Manual Date/Time", isOn: $useManualTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if useManualTime {
                    VStack(spacing: 12) {
                        DatePicker("Date", selection: $manualDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        DatePicker("Time", selection: $manualTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            
            // Add Reading Button
            Button(action: addReading) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add Reading")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            canAddReading ? 
                            LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.gray, Color.gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .foregroundColor(.white)
                .shadow(color: canAddReading ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            }
            .disabled(!canAddReading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Current Readings Section
    
    private var currentReadingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text("Current Readings")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(dataManager.currentSession.readings.count)/5")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            
            if dataManager.currentSession.readings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "heart.text.square")
                        .font(.system(size: 32))
                        .foregroundColor(.gray.opacity(0.6))
                    
                    Text("No readings yet")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    Text("Add your first reading above to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(Array(dataManager.currentSession.readings.enumerated()), id: \.element.id) { index, reading in
                        readingRow(reading: reading, index: index)
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
    
    private func readingRow(reading: BloodPressureReading, index: Int) -> some View {
        HStack(spacing: 16) {
            // Reading number
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Text("\(index + 1)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            // Reading values
            VStack(alignment: .leading, spacing: 4) {
                Text(reading.displayString)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(reading.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Remove button
            Button(action: {
                dataManager.removeReading(at: index)
            }) {
                Image(systemName: "trash.circle.fill")
                    .foregroundColor(.red.opacity(0.7))
                    .font(.title3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Session Average Section
    
    private var sessionAverageSection: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text("Session Average")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(Int(dataManager.currentSession.averageSystolic.rounded()))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Systolic")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                    Text("mmHg")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Text("/")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                VStack(spacing: 8) {
                    Text("\(Int(dataManager.currentSession.averageDiastolic.rounded()))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Diastolic")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                    Text("mmHg")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                if let avgHeartRate = dataManager.currentSession.averageHeartRate {
                    VStack(spacing: 8) {
                        Text("\(Int(avgHeartRate.rounded()))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Heart Rate")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        Text("bpm")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .blue.opacity(0.3), radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        Button(action: clearSession) {
            HStack(spacing: 12) {
                Image(systemName: "trash.circle.fill")
                    .font(.title3)
                Text("Clear Session")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange)
            )
            .foregroundColor(.white)
            .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canAddReading: Bool {
        guard let systolicInt = Int(systolic),
              let diastolicInt = Int(diastolic) else { return false }
        
        let heartRateInt = heartRate.isEmpty ? nil : Int(heartRate)
        
        return dataManager.isValidReading(systolic: systolicInt, diastolic: diastolicInt, heartRate: heartRateInt) &&
               dataManager.canAddReading()
    }
    
    private var canSaveSession: Bool {
        return !dataManager.currentSession.readings.isEmpty
    }
    
    // MARK: - Actions
    
    private func startSession() {
        dataManager.startSession()
        startSessionTimer()
    }
    
    private func stopSession() {
        dataManager.stopSession()
        stopSessionTimer()
    }
    
    private func addReading() {
        guard let systolicInt = Int(systolic),
              let diastolicInt = Int(diastolic) else {
            showAlert("Please enter valid numbers for systolic and diastolic values.")
            return
        }
        
        let heartRateInt = heartRate.isEmpty ? nil : Int(heartRate)
        let timestamp = useManualTime ? combineDateAndTime(manualDate, manualTime) : nil
        
        if dataManager.addReading(systolic: systolicInt, diastolic: diastolicInt, heartRate: heartRateInt, timestamp: timestamp) {
            clearForm()
        } else {
            if dataManager.currentSession.readings.count >= 5 {
                showAlert("Maximum 5 readings per session allowed.")
            } else if !dataManager.currentSession.isActive {
                showAlert("Please start a session first.")
            } else {
                showAlert("Invalid reading values. Please check your input.")
            }
        }
    }
    
    private func combineDateAndTime(_ date: Date, _ time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = timeComponents.second
        
        return calendar.date(from: combinedComponents) ?? Date()
    }
    
    private func clearForm() {
        systolic = ""
        diastolic = ""
        heartRate = ""
        useManualTime = false
        manualDate = Date()
        manualTime = Date()
    }
    
    private func clearSession() {
        dataManager.clearCurrentSession()
        clearForm()
    }
    
    private func saveSession() {
        dataManager.saveCurrentSession()
        clearForm()
    }
    
    private func showAlert(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
    
    // MARK: - Timer Functions
    
    private func startSessionTimer() {
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            sessionDuration = Date().timeIntervalSince(dataManager.currentSession.startTime)
        }
    }
    
    private func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
