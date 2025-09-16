import SwiftUI

struct MyNutritionEntriesView: View {
    @ObservedObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var showingReuseAlert: NutritionEntry? = nil
    @State private var showingEditSheet: NutritionEntry? = nil
    @State private var showingDeleteAlert: NutritionEntry? = nil
    @State private var showingSuccess = false
    @State private var successMessage = ""
    
    var filteredEntries: [NutritionEntry] {
        let entries = dataManager.nutritionEntries
        
        if searchText.isEmpty {
            return entries.sorted { $0.date > $1.date }
        } else {
            return entries.filter { entry in
                (entry.label?.localizedCaseInsensitiveContains(searchText) == true) ||
                (entry.notes?.localizedCaseInsensitiveContains(searchText) == true)
            }.sorted { $0.date > $1.date }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search foods...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    
                    // Entry Count
                    HStack {
                        Text("\(filteredEntries.count) foods")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // Entries List
                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredEntries) { entry in
                                MyNutritionEntryRow(
                                    entry: entry,
                                    onReuse: {
                                        showingReuseAlert = entry
                                    },
                                    onEdit: {
                                        showingEditSheet = entry
                                    },
                                    onDelete: {
                                        showingDeleteAlert = entry
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("My Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(item: $showingEditSheet) { entry in
            EditNutritionEntryView(
                entry: entry,
                onSave: { updatedEntry in
                    dataManager.updateNutritionEntry(updatedEntry)
                }
            )
        }
        .alert("Reuse Food Entry", isPresented: Binding<Bool>(
            get: { showingReuseAlert != nil },
            set: { if !$0 { showingReuseAlert = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                showingReuseAlert = nil
            }
            Button("Reuse") {
                if let entry = showingReuseAlert {
                    reuseNutritionEntry(entry)
                }
                showingReuseAlert = nil
            }
        } message: {
            if let entry = showingReuseAlert {
                Text("Add '\(entry.label ?? "this food")' to today's nutrition?")
            }
        }
        .alert("Delete Food Entry", isPresented: Binding<Bool>(
            get: { showingDeleteAlert != nil },
            set: { if !$0 { showingDeleteAlert = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                showingDeleteAlert = nil
            }
            Button("Delete", role: .destructive) {
                if let entry = showingDeleteAlert {
                    dataManager.deleteNutritionEntry(entry)
                }
                showingDeleteAlert = nil
            }
        } message: {
            if let entry = showingDeleteAlert {
                Text("Are you sure you want to delete '\(entry.label ?? "this food")'? This action cannot be undone.")
            }
        }
        .alert("Success", isPresented: $showingSuccess) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Foods Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("No nutrition entries found. Add some food entries first to see them here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func reuseNutritionEntry(_ entry: NutritionEntry) {
        // Create a new entry with today's date but same nutrition values
        let newEntry = NutritionEntry(
            date: Date(),
            calories: entry.calories,
            protein: entry.protein,
            carbohydrates: entry.carbohydrates,
            fat: entry.fat,
            sodium: entry.sodium,
            sugar: entry.sugar,
            addedSugar: entry.addedSugar,
            fiber: entry.fiber,
            cholesterol: entry.cholesterol,
            water: entry.water,
            notes: entry.notes,
            label: entry.label
        )
        
        dataManager.addNutritionEntry(newEntry)
        
        // Show success message
        successMessage = "Food added to summary!"
        showingSuccess = true
    }
}

struct MyNutritionEntryRow: View {
    let entry: NutritionEntry
    let onReuse: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Entry Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Entry Info
            VStack(alignment: .leading, spacing: 6) {
                Text(entry.label ?? "Nutrition Entry")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Time
                Text(entry.date, style: .time)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray6))
                    )
                
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                // Reuse Button
                Button(action: onReuse) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Edit Button
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

#Preview {
    MyNutritionEntriesView(dataManager: BPDataManager())
}
