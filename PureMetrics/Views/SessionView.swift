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
                        
                        HStack(spacing: 8) {
                            // HealthKit Dashboard Button
                            NavigationLink(destination: HealthKitDashboard(healthKitManager: dataManager.healthKitManager)) {
                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("Health")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.2))
                                )
                            }
                            
                            // Health Metrics List Button
                            NavigationLink(destination: HealthMetricsListView(dataManager: dataManager)) {
                                HStack(spacing: 4) {
                                    Image(systemName: "list.bullet")
                                        .font(.system(size: 12, weight: .medium))
                                    Text("All Metrics")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white.opacity(0.2))
                                )
                            }
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
        VStack(spacing: 16) {
            // Header with improved design
            VStack(spacing: 12) {
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
            VStack(spacing: 16) {
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
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
