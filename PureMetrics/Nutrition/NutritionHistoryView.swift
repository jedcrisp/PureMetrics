import SwiftUI

struct NutritionHistoryView: View {
    @ObservedObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedDate = Date()
    @State private var searchText = ""
    @State private var sortOption: SortOption = .newest
    @State private var filterOption: FilterOption = .all
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case calories = "Most Calories"
        case water = "Most Water"
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All Entries"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Filter and Sort Controls
                filterSection
                
                // Entries List
                if filteredEntries.isEmpty {
                    emptyStateView
                } else {
                    entriesList
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nutrition History")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(filteredEntries.count) entries")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    // MARK: - Filter Section
    
    private var filterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search entries...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            
            // Filter and Sort Controls
            HStack(spacing: 12) {
                // Filter Picker
                Menu {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            filterOption = option
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(filterOption.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                
                // Sort Picker
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(option.rawValue) {
                            sortOption = option
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOption.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Entries List
    
    private var entriesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredEntries, id: \.id) { entry in
                    NutritionHistoryCard(entry: entry, dataManager: dataManager)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Nutrition Entries")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Start tracking your nutrition to see entries here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Computed Properties
    
    private var filteredEntries: [NutritionEntry] {
        var entries = dataManager.nutritionEntries
        
        // Apply search filter
        if !searchText.isEmpty {
            entries = entries.filter { entry in
                entry.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                "\(Int(entry.calories))".contains(searchText) ||
                "\(Int(entry.water))".contains(searchText)
            }
        }
        
        // Apply category filter
        switch filterOption {
        case .all:
            break
        case .today:
            let today = Date()
            entries = entries.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        case .thisWeek:
            let weekAgo = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: Date()) ?? Date()
            entries = entries.filter { $0.date >= weekAgo }
        case .thisMonth:
            let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
            entries = entries.filter { $0.date >= monthAgo }
        }
        
        // Apply sorting
        switch sortOption {
        case .newest:
            entries.sort { $0.date > $1.date }
        case .oldest:
            entries.sort { $0.date < $1.date }
        case .calories:
            entries.sort { $0.calories > $1.calories }
        case .water:
            entries.sort { $0.water > $1.water }
        }
        
        return entries
    }
}

// MARK: - Nutrition History Card

struct NutritionHistoryCard: View {
    let entry: NutritionEntry
    @ObservedObject var dataManager: BPDataManager
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if let notes = entry.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(entry.caloriesString)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text("Calories")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Edit and Delete Buttons
                    HStack(spacing: 8) {
                        Button(action: {
                            showingEditSheet = true
                        }) {
                            Image(systemName: "pencil")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .font(.title3)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            
            // Stats
            HStack(spacing: 20) {
                if entry.water > 0 {
                    StatItem(
                        icon: "drop.fill",
                        value: entry.waterString,
                        label: "Water",
                        color: .blue
                    )
                }
                
                if entry.protein > 0 {
                    StatItem(
                        icon: "scalemass.fill",
                        value: entry.proteinString,
                        label: "Protein",
                        color: .green
                    )
                }
                
                if entry.carbohydrates > 0 {
                    StatItem(
                        icon: "leaf.fill",
                        value: entry.carbsString,
                        label: "Carbs",
                        color: .orange
                    )
                }
                
                if entry.fat > 0 {
                    StatItem(
                        icon: "drop.fill",
                        value: entry.fatString,
                        label: "Fat",
                        color: .red
                    )
                }
            }
            
            // Additional Nutrients
            if entry.sodium > 0 || entry.sugar > 0 || entry.fiber > 0 {
                HStack(spacing: 16) {
                    if entry.sodium > 0 {
                        NutrientItem(
                            label: "Sodium",
                            value: entry.sodiumString,
                            color: .purple
                        )
                    }
                    
                    if entry.sugar > 0 {
                        NutrientItem(
                            label: "Sugar",
                            value: entry.sugarString,
                            color: .pink
                        )
                    }
                    
                    if entry.fiber > 0 {
                        NutrientItem(
                            label: "Fiber",
                            value: entry.fiberString,
                            color: .mint
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .sheet(isPresented: $showingEditSheet) {
            EditNutritionEntryView(
                entry: entry,
                onSave: { updatedEntry in
                    dataManager.updateNutritionEntry(updatedEntry)
                    showingEditSheet = false
                }
            )
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                dataManager.deleteNutritionEntry(entry)
            }
        } message: {
            Text("Are you sure you want to delete this nutrition entry? This action cannot be undone.")
        }
    }
}

#Preview {
    NutritionHistoryView(dataManager: BPDataManager())
}
