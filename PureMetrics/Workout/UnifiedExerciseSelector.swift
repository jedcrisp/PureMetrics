import SwiftUI

struct UnifiedExerciseSelector: View {
    @Binding var selectedExercise: ExerciseType?
    let onExerciseSelected: (ExerciseType) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedCategory: ExerciseCategory?
    @State private var searchText = ""
    @State private var showingCategorySelector = true
    
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
                                .padding(.horizontal, 20)
                            }
                            
                            // Show message if no exercises match search
                            if allExercises.isEmpty {
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
    }
}


#Preview {
    UnifiedExerciseSelector(
        selectedExercise: .constant(nil),
        onExerciseSelected: { _ in }
    )
}
