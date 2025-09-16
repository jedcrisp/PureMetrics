import SwiftUI

struct CustomNutritionTemplatesView: View {
    @ObservedObject var dataManager: BPDataManager
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var showingAddTemplate = false
    @State private var showingEditTemplate: CustomNutritionTemplate? = nil
    @State private var showingDeleteAlert: CustomNutritionTemplate? = nil
    @State private var showingSuccess = false
    @State private var successMessage = ""
    
    var filteredTemplates: [CustomNutritionTemplate] {
        let templates = dataManager.searchCustomNutritionTemplates(searchText)
        print("🔍 DEBUG: CustomNutritionTemplatesView - Total templates: \(dataManager.customNutritionTemplates.count), Filtered: \(templates.count)")
        if let category = selectedCategory {
            return templates.filter { $0.category == category }
        }
        return templates
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
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
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button("All") {
                                selectedCategory = nil
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedCategory == nil ? Color.blue : Color(.systemGray5))
                            )
                            .foregroundColor(selectedCategory == nil ? .white : .primary)
                            
                            ForEach(NutritionTemplateCategory.allCases, id: \.self) { category in
                                Button(category.rawValue) {
                                    selectedCategory = category.rawValue
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedCategory == category.rawValue ? category.color : Color(.systemGray5))
                                )
                                .foregroundColor(selectedCategory == category.rawValue ? .white : .primary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // Templates List
                if filteredTemplates.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredTemplates) { template in
                                CustomNutritionTemplateRow(
                                    template: template,
                                    onEdit: {
                                        showingEditTemplate = template
                                    },
                                    onDelete: {
                                        showingDeleteAlert = template
                                    },
                                    onUse: {
                                        dataManager.useCustomNutritionTemplate(template)
                                        successMessage = "Food added to summary!"
                                        showingSuccess = true
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        showingAddTemplate = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            AddCustomNutritionTemplateView(dataManager: dataManager)
        }
        .sheet(item: $showingEditTemplate) { template in
            EditCustomNutritionTemplateView(template: template, dataManager: dataManager)
        }
        .alert("Delete Food", isPresented: Binding<Bool>(
            get: { showingDeleteAlert != nil },
            set: { if !$0 { showingDeleteAlert = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                showingDeleteAlert = nil
            }
            Button("Delete", role: .destructive) {
                if let template = showingDeleteAlert {
                    dataManager.deleteCustomNutritionTemplate(template)
                }
                showingDeleteAlert = nil
            }
        } message: {
            if let template = showingDeleteAlert {
                Text("Are you sure you want to delete '\(template.name)'? This action cannot be undone.")
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
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Foods Saved")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Create your first food template to quickly add common foods to your daily intake.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Add Food") {
                showingAddTemplate = true
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

struct CustomNutritionTemplateRow: View {
    let template: CustomNutritionTemplate
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onUse: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Template Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(categoryColor)
            }
            
            // Template Info
            VStack(alignment: .leading, spacing: 6) {
                Text(template.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(template.category)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(.systemGray6))
                    )
                
            }
            
            Spacer()
            
            // Action Buttons - Clean and Professional
            HStack(spacing: 8) {
                // Use Button
                Button(action: onUse) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Edit Button
                Button(action: onEdit) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Delete Button
                Button(action: onDelete) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 24))
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
    
    private var categoryIcon: String {
        if let category = NutritionTemplateCategory(rawValue: template.category) {
            return category.icon
        }
        return "star.fill"
    }
    
    private var categoryColor: Color {
        if let category = NutritionTemplateCategory(rawValue: template.category) {
            return category.color
        }
        return .gray
    }
}

struct NutritionStat: View {
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)
                .lineLimit(1)
            Text(unit)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(minWidth: 40)
    }
}

#Preview {
    CustomNutritionTemplatesView(dataManager: BPDataManager())
}
