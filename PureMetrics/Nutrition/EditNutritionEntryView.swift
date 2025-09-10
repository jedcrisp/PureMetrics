import SwiftUI

struct EditNutritionEntryView: View {
    let entry: NutritionEntry
    let onSave: (NutritionEntry) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbohydrates: String = ""
    @State private var fat: String = ""
    @State private var sodium: String = ""
    @State private var sugar: String = ""
    @State private var fiber: String = ""
    @State private var water: String = ""
    @State private var notes: String = ""
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Edit Nutrition Entry")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Update your nutrition information")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Date Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(CompactDatePickerStyle())
                            .labelsHidden()
                    }
                    .padding(.horizontal, 20)
                    
                    // Nutrition Input Fields
                    VStack(spacing: 16) {
                        // Calories
                        NutritionEditInputField(
                            title: "Calories",
                            value: $calories,
                            unit: "cal",
                            icon: "flame.fill",
                            color: .orange
                        )
                        
                        // Protein
                        NutritionEditInputField(
                            title: "Protein",
                            value: $protein,
                            unit: "g",
                            icon: "scalemass.fill",
                            color: .red
                        )
                        
                        // Carbohydrates
                        NutritionEditInputField(
                            title: "Carbohydrates",
                            value: $carbohydrates,
                            unit: "g",
                            icon: "leaf.fill",
                            color: .yellow
                        )
                        
                        // Fat
                        NutritionEditInputField(
                            title: "Fat",
                            value: $fat,
                            unit: "g",
                            icon: "circle.fill",
                            color: .brown
                        )
                        
                        // Sodium
                        NutritionEditInputField(
                            title: "Sodium",
                            value: $sodium,
                            unit: "mg",
                            icon: "drop.triangle.fill",
                            color: .purple
                        )
                        
                        // Sugar
                        NutritionEditInputField(
                            title: "Sugar",
                            value: $sugar,
                            unit: "g",
                            icon: "drop.fill",
                            color: .pink
                        )
                        
                        // Fiber
                        NutritionEditInputField(
                            title: "Fiber",
                            value: $fiber,
                            unit: "g",
                            icon: "leaf.fill",
                            color: .green
                        )
                        
                        // Water
                        NutritionEditInputField(
                            title: "Water",
                            value: $water,
                            unit: "oz",
                            icon: "drop.fill",
                            color: .blue
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // Notes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        TextField("Add notes...", text: $notes, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .onAppear {
            loadEntryData()
        }
        .overlay(
            // Custom Navigation Bar
            VStack {
                HStack {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                    )
                    .disabled(!isValidEntry)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .shadow(radius: 1)
                
                Spacer()
            }
        )
    }
    
    // MARK: - Helper Functions
    
    private func loadEntryData() {
        calories = entry.calories > 0 ? String(Int(entry.calories)) : ""
        protein = entry.protein > 0 ? String(Int(entry.protein)) : ""
        carbohydrates = entry.carbohydrates > 0 ? String(Int(entry.carbohydrates)) : ""
        fat = entry.fat > 0 ? String(Int(entry.fat)) : ""
        sodium = entry.sodium > 0 ? String(Int(entry.sodium)) : ""
        sugar = entry.sugar > 0 ? String(Int(entry.sugar)) : ""
        fiber = entry.fiber > 0 ? String(Int(entry.fiber)) : ""
        water = entry.water > 0 ? String(Int(entry.water)) : ""
        notes = entry.notes ?? ""
        selectedDate = entry.date
    }
    
    private func saveEntry() {
        let updatedEntry = NutritionEntry(
            date: selectedDate,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbohydrates: Double(carbohydrates) ?? 0,
            fat: Double(fat) ?? 0,
            sodium: Double(sodium) ?? 0,
            sugar: Double(sugar) ?? 0,
            fiber: Double(fiber) ?? 0,
            water: Double(water) ?? 0,
            notes: notes.isEmpty ? nil : notes
        )
        
        onSave(updatedEntry)
    }
    
    private var isValidEntry: Bool {
        return !calories.isEmpty || !protein.isEmpty || !carbohydrates.isEmpty || 
               !fat.isEmpty || !sodium.isEmpty || !sugar.isEmpty || 
               !fiber.isEmpty || !water.isEmpty
    }
}

// MARK: - Nutrition Input Field

struct NutritionEditInputField: View {
    let title: String
    @Binding var value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            TextField("0", text: $value)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .multilineTextAlignment(.trailing)
                .keyboardType(.decimalPad)
                .frame(width: 80)
            
            Text(unit)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
        )
    }
}

#Preview {
    EditNutritionEntryView(
        entry: NutritionEntry(
            date: Date(),
            calories: 500,
            protein: 25,
            carbohydrates: 60,
            fat: 15,
            sodium: 800,
            sugar: 20,
            fiber: 8,
            water: 16,
            notes: "Sample entry"
        )
    ) { _ in }
}
