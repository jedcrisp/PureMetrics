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
    @State private var bodyFat = ""
    
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
                        VStack(spacing: 16) {
                            // Entry Form - Made more prominent
                            entryFormSection
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
            .frame(height: 80)
            .overlay(
                VStack(spacing: 0) {
                    // Top section with app name and subtitle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PureMetrics")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            
                            Text("Health")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(useManualTime ? manualDate : Date(), style: .date)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
                            
                            Text(useManualTime ? manualTime : Date(), style: .time)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
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
        VStack(spacing: 12) {
            // Header with improved design
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Add Health Reading")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Select a metric type and enter your values")
                            .font(.caption)
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
            VStack(spacing: 12) {
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
                    VStack(spacing: 8) {
                        HStack {
                            Text("Heart Rate")
                                .font(.subheadline)
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
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .padding(.vertical, 12)
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Use Manual Date/Time", isOn: $useManualTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if useManualTime {
                    VStack(spacing: 8) {
                        DatePicker("Date", selection: $manualDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                        
                        DatePicker("Time", selection: $manualTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
            }
            
            // Health Notes Section
            healthNotesSection
            
            // Add Reading Button
            Button(action: addReading) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Add Reading")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            canAddReading ? 
                            LinearGradient(colors: [Color.blue, Color.blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.gray, Color.gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .foregroundColor(.white)
                .shadow(color: canAddReading ? .blue.opacity(0.3) : .clear, radius: 6, x: 0, y: 3)
            }
            .disabled(!canAddReading)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
    }
    
    
    
    
    // MARK: - Computed Properties
    
    private var canAddReading: Bool {
        if selectedMetricType == .bloodPressure {
            guard let systolicInt = Int(systolic),
                  let diastolicInt = Int(diastolic) else { return false }
            
            let heartRateInt = heartRate.isEmpty ? nil : Int(heartRate)
            
            return dataManager.isValidReading(systolic: systolicInt, diastolic: diastolicInt, heartRate: heartRateInt)
        } else {
            // For other health metrics, just check if we have a valid value
            let valueString = bindingForMetricType(selectedMetricType).wrappedValue
            guard let value = Double(valueString) else { return false }
            
            let metric = HealthMetric(type: selectedMetricType, value: value)
            return metric.isValid
        }
    }
    
    
    
    // MARK: - Actions
    
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
                dismissKeyboard()
            } else {
                showAlert("Invalid reading values. Please check your input.")
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
                dismissKeyboard()
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
        case .bodyFat: return .purple
        }
    }
    
    private func bindingForMetricType(_ type: MetricType) -> Binding<String> {
        switch type {
        case .weight: return Binding(
            get: { weight },
            set: { weight = $0 }
        )
        case .bloodSugar: return Binding(
            get: { bloodSugar },
            set: { bloodSugar = $0 }
        )
        case .heartRate: return Binding(
            get: { additionalHeartRate },
            set: { additionalHeartRate = $0 }
        )
        case .bodyFat: return Binding(
            get: { bodyFat },
            set: { bodyFat = $0 }
        )
        case .bloodPressure: return Binding(
            get: { systolic },
            set: { systolic = $0 }
        )
        }
    }
    
    private func clearInputs() {
        systolic = ""
        diastolic = ""
        heartRate = ""
        weight = ""
        bloodSugar = ""
        additionalHeartRate = ""
        bodyFat = ""
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Health Notes Section
    
    private var healthNotesSection: some View {
        HealthNotesView(
            metricType: selectedMetricType.rawValue,
            date: useManualTime ? manualDate : Date(),
            dataManager: dataManager
        )
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}
