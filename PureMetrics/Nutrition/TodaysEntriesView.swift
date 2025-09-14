import SwiftUI

struct TodaysEntriesView: View {
    @ObservedObject var dataManager: BPDataManager
    let selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    @State private var showingEditSheet: NutritionEntry? = nil
    @State private var showingDeleteAlert: NutritionEntry? = nil
    @State private var isLoading = false
    
    var todaysEntries: [NutritionEntry] {
        dataManager.nutritionEntries.filter { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: selectedDate)
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    loadingView
                } else if todaysEntries.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(todaysEntries) { entry in
                            TodaysEntryRow(
                                entry: entry,
                                onEdit: {
                                    print("Edit button tapped for entry: \(entry.label ?? "Unknown")")
                                    showingEditSheet = entry
                                },
                                onDelete: {
                                    print("Delete button tapped for entry: \(entry.label ?? "Unknown")")
                                    showingDeleteAlert = entry
                                }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Today's Entries")
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
        .alert("Delete Entry", isPresented: Binding<Bool>(
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
                Text("Are you sure you want to delete '\(entry.label ?? "this entry")'? This action cannot be undone.")
            }
        }
        .onAppear {
            // Load nutrition entries for the selected date from Firestore
            isLoading = true
            dataManager.loadNutritionEntriesForDate(selectedDate)
            // Add a small delay to show loading state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isLoading = false
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading Today's Entries...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Entries Today")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Add some food entries to track your nutrition for today.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct TodaysEntryRow: View {
    let entry: NutritionEntry
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Entry Info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.label ?? "Nutrition Entry")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Nutrition Summary
                HStack(spacing: 12) {
                    if entry.calories > 0 {
                        HStack(spacing: 2) {
                            Text("\(Int(entry.calories))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                            Text("cal")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if entry.protein > 0 {
                        HStack(spacing: 2) {
                            Text("\(String(format: "%.1f", entry.protein))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            Text("g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if entry.carbohydrates > 0 {
                        HStack(spacing: 2) {
                            Text("\(String(format: "%.1f", entry.carbohydrates))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                            Text("g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if entry.fat > 0 {
                        HStack(spacing: 2) {
                            Text("\(String(format: "%.1f", entry.fat))")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.brown)
                            Text("g")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Time
            Text(entry.date, style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Action Buttons
            HStack(spacing: 20) {
                // Edit Button - Pencil Icon
                Button(action: {
                    print("Pencil button tapped - calling onEdit")
                    onEdit()
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16))
                        .foregroundColor(.blue)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Delete Button - Trash Icon
                Button(action: {
                    print("Trash button tapped - calling onDelete")
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundColor(.red)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    TodaysEntriesView(
        dataManager: BPDataManager(),
        selectedDate: Date()
    )
}
