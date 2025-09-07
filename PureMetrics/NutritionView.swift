import SwiftUI

struct NutritionView: View {
    @ObservedObject var dataManager: BPDataManager
    @State private var selectedDate = Date()
    @State private var showingAddEntry = false
    @State private var showingGoals = false
    @State private var showingHistory = false
    
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
                        
                        // Content
                        VStack(spacing: 24) {
                            // Date Selector
                            dateSelector
                            
                            // Today's Summary
                            todaysSummarySection
                            
                            // Quick Add Buttons
                            quickAddSection
                            
                            // Recent Entries
                            recentEntriesSection
                            
                            // Goals Progress
                            goalsProgressSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingAddEntry) {
            AddNutritionEntryView(
                selectedDate: selectedDate,
                onSave: { entry in
                    dataManager.addNutritionEntry(entry)
                }
            )
        }
        .sheet(isPresented: $showingGoals) {
            NutritionGoalsView(
                goals: dataManager.nutritionGoals,
                onSave: { goals in
                    dataManager.updateNutritionGoals(goals)
                }
            )
        }
        .sheet(isPresented: $showingHistory) {
            NutritionHistoryView(dataManager: dataManager)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 0) {
            // Top gradient header
            LinearGradient(
                colors: [
                    Color.green.opacity(0.9),
                    Color.green.opacity(0.7),
                    Color.blue.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 100)
            .overlay(
                VStack(spacing: 0) {
                    // Top section with app name and buttons
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Nutrition")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            // Goals Button
                            Button(action: {
                                showingGoals = true
                            }) {
                                Image(systemName: "target")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                            
                            // History Button
                            Button(action: {
                                showingHistory = true
                            }) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
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
    
    // MARK: - Date Selector
    
    private var dateSelector: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Select Date")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    selectedDate = Date()
                }) {
                    Text("Today")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
            
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
                .labelsHidden()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Today's Summary Section
    
    private var todaysSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    showingAddEntry = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Entry")
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green)
                    )
                }
            }
            
            if let summary = todaysSummary {
                NutritionSummaryCard(summary: summary, goals: dataManager.nutritionGoals)
            } else {
                emptySummaryView
            }
        }
    }
    
    // MARK: - Quick Add Section
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Add")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickAddButton(
                    icon: "flame.fill",
                    title: "Calories",
                    value: todaysSummary?.totalCalories ?? 0,
                    unit: "cal",
                    color: .orange
                ) {
                    showingAddEntry = true
                }
                
                QuickAddButton(
                    icon: "drop.fill",
                    title: "Water",
                    value: todaysSummary?.totalWater ?? 0,
                    unit: "oz",
                    color: .blue
                ) {
                    showingAddEntry = true
                }
                
                QuickAddButton(
                    icon: "scalemass.fill",
                    title: "Protein",
                    value: todaysSummary?.totalProtein ?? 0,
                    unit: "g",
                    color: .red
                ) {
                    showingAddEntry = true
                }
                
                QuickAddButton(
                    icon: "leaf.fill",
                    title: "Fiber",
                    value: todaysSummary?.totalFiber ?? 0,
                    unit: "g",
                    color: .green
                ) {
                    showingAddEntry = true
                }
            }
        }
    }
    
    // MARK: - Recent Entries Section
    
    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Entries")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("View All") {
                    showingHistory = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if todaysEntries.isEmpty {
                emptyEntriesView
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(todaysEntries.prefix(3), id: \.id) { entry in
                        NutritionEntryCard(entry: entry)
                    }
                }
            }
        }
    }
    
    // MARK: - Goals Progress Section
    
    private var goalsProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Daily Goals")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button("Edit Goals") {
                    showingGoals = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if let summary = todaysSummary {
                GoalsProgressCard(summary: summary, goals: dataManager.nutritionGoals)
            } else {
                emptyGoalsView
            }
        }
    }
    
    // MARK: - Empty Views
    
    private var emptySummaryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text("No Entries Today")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Start tracking your nutrition by adding your first entry")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    private var emptyEntriesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
            
            Text("No entries yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    private var emptyGoalsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
            
            Text("Set your nutrition goals to track progress")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Computed Properties
    
    private var todaysEntries: [NutritionEntry] {
        dataManager.nutritionEntries.filter { entry in
            Calendar.current.isDate(entry.date, inSameDayAs: selectedDate)
        }
    }
    
    private var todaysSummary: NutritionSummary? {
        let entries = todaysEntries
        guard !entries.isEmpty else { return nil }
        return NutritionSummary(entries: entries, date: selectedDate)
    }
}

// MARK: - Quick Add Button

struct QuickAddButton: View {
    let icon: String
    let title: String
    let value: Double
    let unit: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text("\(Int(value)) \(unit)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Nutrition Entry Card

struct NutritionEntryCard: View {
    let entry: NutritionEntry
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.date.formatted(date: .omitted, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                if entry.calories > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(entry.caloriesString)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        Text("calories")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if entry.water > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(entry.waterString)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Text("water")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    NutritionView(dataManager: BPDataManager())
}
