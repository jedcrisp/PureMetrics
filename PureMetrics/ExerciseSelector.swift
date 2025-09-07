import SwiftUI

struct ExerciseSelector: View {
    let category: ExerciseCategory
    @Binding var selectedExercise: ExerciseType?
    let onExerciseSelected: (ExerciseType) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    private var exercisesInCategory: [ExerciseType] {
        ExerciseType.allCases.filter { $0.category == category }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text(category.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .opacity(0)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemBackground))
                
                Divider()
                
                // Exercise List
                List {
                    ForEach(exercisesInCategory, id: \.self) { exercise in
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
            .navigationBarHidden(true)
        }
    }
}


#Preview {
    ExerciseSelector(
        category: .upperBody,
        selectedExercise: .constant(nil),
        onExerciseSelected: { _ in }
    )
}
