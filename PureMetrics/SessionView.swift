import SwiftUI

struct SessionView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var systolic = ""
    @State private var diastolic = ""
    @State private var heartRate = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var useManualTime = false
    @State private var manualDate = Date()
    @State private var manualTime = Date()
    
    // New health metrics state
    @State private var selectedMetricType: MetricType = .bloodPressure
    @State private var weight = ""
    @State private var bloodSugar = ""
    @State private var additionalHeartRate = ""
    
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
                        
                        // Session Content (always visible)
                        VStack(spacing: 24) {
                            // Entry Form - Made more prominent
                            entryFormSection
                            
                            
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
            .navigationTitle("")
            .navigationBarHidden(true)
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
            // Top gradient header with improved design
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.9),
                    Color.blue.opacity(0.7),
                    Color.purple.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 100)
            .overlay(
                VStack(spacing: 0) {
                    // Top section with app name, status, and New Session button
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PureMetrics")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                        
                        Spacer()
                        
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    
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
    
    
    
    // MARK: - Entry Form Section
    
    private var entryFormSection: some View {
        VStack(spacing: 24) {
            // Header with improved design
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Add Health Reading")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Select a metric type and enter your values")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            // Metric Type Selector
            MetricTypeSelector(
                selectedType: $selectedMetricType,
                availableTypes: [.bloodPressure, .weight, .bloodSugar, .heartRate]
            )
            .padding(.horizontal, 4)
            
            // Dynamic Input Fields based on selected metric type
            VStack(spacing: 20) {
                if selectedMetricType == .bloodPressure {
                    BloodPressureInput(systolic: $systolic, diastolic: $diastolic)
                } else {
                    HealthMetricInput(
                        type: selectedMetricType,
                        value: bindingForMetricType(selectedMetricType)
                    )
                }
                
                // Heart Rate (only for Blood Pressure)
                if selectedMetricType == .bloodPressure {
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
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
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
        VStack(spacing: 12) {
            if dataManager.currentSession.isActive {
                HStack(spacing: 12) {
                    Button(action: stopSession) {
                        HStack(spacing: 8) {
                            Image(systemName: "stop.circle.fill")
                            Text("Stop Session")
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
            }
            
            if !dataManager.currentSession.readings.isEmpty {
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
        }
    }
    
    // MARK: - Computed Properties
    
    private var canAddReading: Bool {
        if selectedMetricType == .bloodPressure {
            guard let systolicInt = Int(systolic),
                  let diastolicInt = Int(diastolic) else { return false }
            
            let heartRateInt = heartRate.isEmpty ? nil : Int(heartRate)
            
            return dataManager.isValidReading(systolic: systolicInt, diastolic: diastolicInt, heartRate: heartRateInt) &&
                   dataManager.canAddReading()
        } else {
            // For other health metrics, just check if we have a valid value
            let valueString = bindingForMetricType(selectedMetricType).wrappedValue
            guard let value = Double(valueString) else { return false }
            
            let metric = HealthMetric(type: selectedMetricType, value: value)
            return metric.isValid && dataManager.canAddReading()
        }
    }
    
    private var canSaveSession: Bool {
        return !dataManager.currentSession.readings.isEmpty
    }
    
    
    // MARK: - Actions
    
    private func startSession() {
        dataManager.startSession()
    }
    
    private func startNewSession() {
        if dataManager.currentSession.isActive {
            // If there are readings, save them first
            if !dataManager.currentSession.readings.isEmpty {
                dataManager.saveCurrentSession()
            } else {
                dataManager.clearCurrentSession()
            }
        }
        dataManager.startSession()
    }
    
    private func stopSession() {
        dataManager.stopSession()
    }
    
    private func addReading() {
        let timestamp = useManualTime ? combineDateAndTime(manualDate, manualTime) : nil
        
        if selectedMetricType == .bloodPressure {
            // Handle blood pressure reading
            guard let systolicInt = Int(systolic),
                  let diastolicInt = Int(diastolic) else {
                showAlert("Please enter valid numbers for systolic and diastolic values.")
                return
            }
            
            let heartRateInt = heartRate.isEmpty ? nil : Int(heartRate)
            
            if dataManager.addReading(systolic: systolicInt, diastolic: diastolicInt, heartRate: heartRateInt, timestamp: timestamp) {
                clearForm()
            } else {
                if dataManager.currentSession.readings.count >= 5 {
                    showAlert("Maximum 5 readings per session allowed.")
                } else {
                    showAlert("Invalid reading values. Please check your input.")
                }
            }
        } else {
            // Handle other health metrics
            let valueString = bindingForMetricType(selectedMetricType).wrappedValue
            guard let value = Double(valueString) else {
                showAlert("Please enter a valid number for \(selectedMetricType.rawValue.lowercased()).")
                return
            }
            
            if dataManager.addHealthMetric(type: selectedMetricType, value: value, timestamp: timestamp) {
                clearForm()
            } else {
                showAlert("Invalid \(selectedMetricType.rawValue.lowercased()) value. Please check your input.")
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
        clearInputs()
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
    
    
    // MARK: - Helper Functions for Health Metrics
    
    private func colorForMetricType(_ type: MetricType) -> Color {
        switch type {
        case .bloodPressure: return .blue
        case .weight: return .green
        case .bloodSugar: return .orange
        case .heartRate: return .red
        }
    }
    
    private func bindingForMetricType(_ type: MetricType) -> Binding<String> {
        switch type {
        case .weight: return $weight
        case .bloodSugar: return $bloodSugar
        case .heartRate: return $additionalHeartRate
        case .bloodPressure: return $systolic // This shouldn't be used
        }
    }
    
    private func clearInputs() {
        systolic = ""
        diastolic = ""
        heartRate = ""
        weight = ""
        bloodSugar = ""
        additionalHeartRate = ""
    }
}
