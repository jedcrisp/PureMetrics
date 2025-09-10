import SwiftUI

struct OlympicExerciseSelector: View {
    @Binding var selectedExercise: ExerciseType?
    let onExerciseSelected: (ExerciseType) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    private var olympicExercises: [ExerciseType] {
        ExerciseType.allCases.filter { $0.category == .olympic }
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
                    
                    VStack(spacing: 4) {
                        Image(systemName: "trophy.fill")
                            .font(.title2)
                            .foregroundColor(.yellow)
                        Text("Olympic Movements")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
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
                    ForEach(olympicExercises, id: \.self) { exercise in
                        Button(action: {
                            selectedExercise = exercise
                            onExerciseSelected(exercise)
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack(spacing: 16) {
                                // Exercise Icon
                                ZStack {
                                    Circle()
                                        .fill(Color.yellow.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: exercise.icon)
                                        .font(.title3)
                                        .foregroundColor(.yellow)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.rawValue)
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text("Olympic weightlifting")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedExercise == exercise {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.yellow)
                                        .font(.title3)
                                }
                            }
                            .padding(.vertical, 8)
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
    OlympicExerciseSelector(
        selectedExercise: .constant(nil),
        onExerciseSelected: { _ in }
    )
}
