import SwiftUI

struct UnifiedEditView: View {
    @ObservedObject var dataManager: BPDataManager
    @Binding var isPresented: Bool
    let selectedDate: Date
    
    @State private var showingTodaysEntries = false
    @State private var showingGoals = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Edit Nutrition Data")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Manage your entries and goals for \(selectedDate, formatter: dateFormatter)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Action Buttons
                VStack(spacing: 16) {
                    // Edit Today's Entries
                    Button(action: {
                        showingTodaysEntries = true
                    }) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Edit Today's Entries")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("View, edit, or delete nutrition entries")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue)
                        )
                    }
                    
                    // Edit Daily Goals
                    Button(action: {
                        showingGoals = true
                    }) {
                        HStack {
                            Image(systemName: "target")
                                .font(.title2)
                                .foregroundColor(.white)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Edit Daily Goals")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("Set your daily nutrition targets")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green)
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    isPresented = false
                }
            )
        }
        .sheet(isPresented: $showingTodaysEntries) {
            TodaysEntriesView(
                dataManager: dataManager,
                selectedDate: selectedDate
            )
        }
        .sheet(isPresented: $showingGoals) {
            NutritionGoalsView(
                goals: dataManager.nutritionGoals,
                onSave: { newGoals in
                    dataManager.updateNutritionGoals(newGoals)
                }
            )
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

#Preview {
    UnifiedEditView(
        dataManager: BPDataManager(),
        isPresented: .constant(true),
        selectedDate: Date()
    )
}
