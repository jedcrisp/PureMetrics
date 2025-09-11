import SwiftUI

struct UnifiedExerciseSelector: View {
    @Binding var selectedExercise: ExerciseType?
    let onExerciseSelected: (ExerciseType) -> Void
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var dataManager: BPDataManager
    
    @State private var selectedCategory: ExerciseCategory?
    @State private var searchText = ""
    @State private var showingCategorySelector = true
    @State private var showingCustomExerciseView = false
    @State private var editingCustomExercise: CustomExercise?
    
    private var filteredExercises: [ExerciseType] {
        if let category = selectedCategory {
            let exercises = ExerciseType.allCases.filter { $0.category == category }
            if searchText.isEmpty {
                return exercises
            } else {
                return exercises.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
            }
        }
        return []
    }
    
    private var allExercises: [ExerciseType] {
        if searchText.isEmpty {
            return ExerciseType.allCases
        } else {
            return ExerciseType.allCases.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    private var allCustomExercises: [CustomExercise] {
        if searchText.isEmpty {
            return dataManager.customExercises
        } else {
            return dataManager.customExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if showingCategorySelector {
                    // Category Selection View
                    VStack(spacing: 16) {
                        // Header
                        HStack {
                            Spacer()
                            
                            Text("Select Exercise Category")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        
                        // Search Bar for All Exercises
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            
                            TextField("Search all exercises...", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                            
                            if !searchText.isEmpty {
                                Button("Clear") {
                                    searchText = ""
                                }
                                .foregroundColor(.blue)
                                .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                        .padding(.horizontal, 20)
                        
                        if searchText.isEmpty {
                            // Show Categories when not searching
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                    CategoryCard(
                                        category: category,
                                        isSelected: selectedCategory == category,
                                        onTap: {
                                            selectedCategory = category
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                showingCategorySelector = false
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Show All Exercises when searching
                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    // Custom Exercises Section
                                    if !allCustomExercises.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack {
                                                Text("Custom Exercises")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                
                                                Spacer()
                                                
                                                Button("Add Custom") {
                                                    editingCustomExercise = nil
                                                    showingCustomExerciseView = true
                                                }
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                            }
                                            .padding(.horizontal, 16)
                                            
                                            ForEach(allCustomExercises, id: \.id) { customExercise in
                                                Button(action: {
                                                    // Convert custom exercise to ExerciseType if possible
                                                    if let exerciseType = customExercise.exerciseType {
                                                        onExerciseSelected(exerciseType)
                                                    } else {
                                                        // For now, we'll need to handle custom exercises differently
                                                        // This is a placeholder - we might need to modify the onExerciseSelected callback
                                                        print("Selected custom exercise: \(customExercise.name)")
                                                    }
                                                    presentationMode.wrappedValue.dismiss()
                                                }) {
                                                    HStack {
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(customExercise.name)
                                                                .font(.headline)
                                                                .foregroundColor(.primary)
                                                            
                                                            Text(customExercise.category.rawValue)
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        HStack(spacing: 8) {
                                                            Button(action: {
                                                                editingCustomExercise = customExercise
                                                                showingCustomExerciseView = true
                                                            }) {
                                                                Image(systemName: "pencil")
                                                                    .font(.caption)
                                                                    .foregroundColor(.blue)
                                                            }
                                                            
                                                            Image(systemName: "chevron.right")
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(Color(.systemGray6))
                                                    )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                    
                                    // Regular Exercises Section
                                    if !allExercises.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            if !allCustomExercises.isEmpty {
                                                Text("Built-in Exercises")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                    .padding(.horizontal, 16)
                                            }
                                            
                                            ForEach(allExercises, id: \.self) { exercise in
                                                Button(action: {
                                                    onExerciseSelected(exercise)
                                                    presentationMode.wrappedValue.dismiss()
                                                }) {
                                                    HStack {
                                                        VStack(alignment: .leading, spacing: 4) {
                                                            Text(exercise.rawValue)
                                                                .font(.headline)
                                                                .foregroundColor(.primary)
                                                            
                                                            Text(exercise.category.rawValue)
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                        
                                                        Spacer()
                                                        
                                                        Image(systemName: "chevron.right")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 12)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(Color(.systemGray6))
                                                    )
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Show message if no exercises match search
                            if allExercises.isEmpty && allCustomExercises.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    
                                    Text("No exercises found")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Text("Try a different search term or add a custom exercise")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Button("Add Custom Exercise") {
                                        editingCustomExercise = nil
                                        showingCustomExerciseView = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }
                    }
                } else {
                    // Exercise Selection View
                    VStack(spacing: 0) {
                        // Header with back button and search
                        VStack(spacing: 12) {
                            HStack {
                                Button("Back") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingCategorySelector = true
                                        searchText = ""
                                    }
                                }
                                .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Text(selectedCategory?.rawValue ?? "Exercises")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Invisible button for balance
                                Button("Back") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showingCategorySelector = true
                                        searchText = ""
                                    }
                                }
                                .opacity(0)
                            }
                            .padding(.horizontal, 20)
                            
                            // Search Bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                
                                TextField("Search exercises...", text: $searchText)
                                    .textFieldStyle(PlainTextFieldStyle())
                                
                                if !searchText.isEmpty {
                                    Button("Clear") {
                                        searchText = ""
                                    }
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))
                        
                        Divider()
                        
                        // Exercise List
                        if filteredExercises.isEmpty && !searchText.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                
                                Text("No exercises found")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text("Try a different search term")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            List {
                                ForEach(filteredExercises, id: \.self) { exercise in
                                    Button(action: {
                                        selectedExercise = exercise
                                        onExerciseSelected(exercise)
                                        presentationMode.wrappedValue.dismiss()
                                    }) {
                                        HStack {
                                            Text(exercise.rawValue)
                                                .font(.body)
                                                .foregroundColor(.primary)
                                            
                                            Spacer()
                                            
                                            if selectedExercise == exercise {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.blue)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCustomExerciseView) {
            CustomExerciseView(
                exercise: editingCustomExercise,
                dataManager: dataManager
            ) { customExercise in
                // Custom exercise was saved/updated
                // The dataManager already handles the saving
            }
        }
    }
}


#Preview {
    UnifiedExerciseSelector(
        selectedExercise: .constant(nil),
        onExerciseSelected: { _ in },
        dataManager: BPDataManager()
    )
}
