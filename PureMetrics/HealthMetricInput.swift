import SwiftUI

// MARK: - Health Metric Input Component

struct HealthMetricInput: View {
    let type: MetricType
    @Binding var value: String
    @State private var isFocused = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(type.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForType(type))
                
                Spacer()
                
                Text(type.unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            TextField(type.placeholder, text: $value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .keyboardType(keyboardTypeForType(type))
                .padding(.vertical, 20)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorForType(type).opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isFocused ? colorForType(type) : colorForType(type).opacity(0.2),
                                    lineWidth: isFocused ? 2 : 1.5
                                )
                        )
                )
                .onTapGesture {
                    isFocused = true
                }
        }
    }
    
    private func colorForType(_ type: MetricType) -> Color {
        switch type {
        case .bloodPressure: return .blue
        case .weight: return .green
        case .bloodSugar: return .orange
        case .heartRate: return .red
        }
    }
    
    private func keyboardTypeForType(_ type: MetricType) -> UIKeyboardType {
        switch type {
        case .bloodPressure, .heartRate:
            return .numberPad
        case .weight, .bloodSugar:
            return .decimalPad
        }
    }
}

// MARK: - Blood Pressure Input (Special Case)

struct BloodPressureInput: View {
    @Binding var systolic: String
    @Binding var diastolic: String
    @State private var systolicFocused = false
    @State private var diastolicFocused = false
    
    var body: some View {
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
                                    .stroke(
                                        systolicFocused ? Color.red : Color.red.opacity(0.2),
                                        lineWidth: systolicFocused ? 2 : 1.5
                                    )
                            )
                    )
                    .onTapGesture {
                        systolicFocused = true
                        diastolicFocused = false
                    }
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
                                    .stroke(
                                        diastolicFocused ? Color.blue : Color.blue.opacity(0.2),
                                        lineWidth: diastolicFocused ? 2 : 1.5
                                    )
                            )
                    )
                    .onTapGesture {
                        diastolicFocused = true
                        systolicFocused = false
                    }
            }
        }
    }
}

// MARK: - Metric Type Selector

struct MetricTypeSelector: View {
    @Binding var selectedType: MetricType
    let availableTypes: [MetricType]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableTypes, id: \.self) { type in
                    Button(action: { selectedType = type }) {
                        HStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.subheadline)
                            Text(type.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(selectedType == type ? .white : colorForType(type))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedType == type ? colorForType(type) : colorForType(type).opacity(0.1))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func colorForType(_ type: MetricType) -> Color {
        switch type {
        case .bloodPressure: return .blue
        case .weight: return .green
        case .bloodSugar: return .orange
        case .heartRate: return .red
        }
    }
}

// MARK: - Preview

struct HealthMetricInput_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HealthMetricInput(type: .weight, value: .constant("150"))
            HealthMetricInput(type: .bloodSugar, value: .constant("100"))
            BloodPressureInput(systolic: .constant("120"), diastolic: .constant("80"))
        }
        .padding()
    }
}
