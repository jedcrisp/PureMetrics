import SwiftUI

struct QuickInputView: View {
    @ObservedObject var dataManager: BPDataManager
    let selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedType: QuickInputType = .calories
    @State private var inputValue: String = ""
    @State private var foodName: String = ""
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Quick Add")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Fast nutrition entry")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Food Name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Food Name")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    TextField("Enter food name", text: $foodName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Nutrition Type Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Picker("Nutrition Type", selection: $selectedType) {
                        ForEach(QuickInputType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // Value Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if selectedType == .water {
                        // Water-specific quick add buttons
                        VStack(spacing: 8) {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 8) {
                                ForEach([8, 16, 32, 64], id: \.self) { amount in
                                    Button("\(amount) oz") {
                                        inputValue = "\(amount)"
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedType.color)
                                    )
                                }
                            }
                            
                            // Custom input field
                            HStack {
                                TextField("Enter amount", text: $inputValue)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                
                                Text(selectedType.unit)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .frame(minWidth: 30)
                            }
                        }
                    } else {
                        // Generic input for other types
                        HStack {
                            TextField("Enter amount", text: $inputValue)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text(selectedType.unit)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(minWidth: 30)
                        }
                    }
                }
                
                // Preview
                if !inputValue.isEmpty, let value = Double(inputValue), value > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack {
                            Image(systemName: selectedType.icon)
                                .foregroundColor(selectedType.color)
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(foodName.isEmpty ? "Quick Entry" : foodName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("\(String(format: "%.1f", value)) \(selectedType.unit) \(selectedType.rawValue)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: addQuickEntry) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Entry")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                    }
                    .disabled(inputValue.isEmpty || Double(inputValue) == nil)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray5))
                            )
                    }
                }
            }
            .padding()
            .navigationTitle("Quick Add")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .alert("Entry Added", isPresented: $showingSuccess) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your nutrition entry has been added successfully!")
        }
    }
    
    private func addQuickEntry() {
        guard let value = Double(inputValue), value > 0 else { return }
        
        let entry = NutritionEntry(
            date: selectedDate,
            calories: selectedType == .calories ? value : 0,
            protein: selectedType == .protein ? value : 0,
            carbohydrates: selectedType == .carbs ? value : 0,
            fat: selectedType == .fat ? value : 0,
            sodium: selectedType == .sodium ? value : 0,
            sugar: 0,
            fiber: selectedType == .fiber ? value : 0,
            cholesterol: selectedType == .cholesterol ? value : 0,
            water: selectedType == .water ? value : 0,
            notes: "Quick add: \(selectedType.rawValue)",
            label: foodName.isEmpty ? "Quick Entry" : foodName
        )
        
        dataManager.addNutritionEntry(entry)
        showingSuccess = true
    }
}

#Preview {
    QuickInputView(
        dataManager: BPDataManager(),
        selectedDate: Date()
    )
}
