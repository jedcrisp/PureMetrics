import SwiftUI

struct ExerciseCategorySelector: View {
    @Binding var selectedCategory: ExerciseCategory?
    let onCategorySelected: (ExerciseCategory) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Select Exercise Category")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 8)
            
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
                            onCategorySelected(category)
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct CategoryCard: View {
    let category: ExerciseCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(colorForCategory(category).opacity(isSelected ? 0.2 : 0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(colorForCategory(category))
                }
                
                VStack(spacing: 4) {
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? colorForCategory(category).opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? colorForCategory(category) : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .shadow(
                color: isSelected ? colorForCategory(category).opacity(0.3) : .black.opacity(0.1),
                radius: isSelected ? 8 : 4,
                x: 0,
                y: isSelected ? 4 : 2
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    private func colorForCategory(_ category: ExerciseCategory) -> Color {
        switch category.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        default: return .blue
        }
    }
}

#Preview {
    ExerciseCategorySelector(
        selectedCategory: .constant(nil),
        onCategorySelected: { _ in }
    )
}
