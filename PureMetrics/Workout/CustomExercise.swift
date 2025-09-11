import Foundation

struct CustomExercise: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: ExerciseCategory
    var dateCreated: Date
    var dateModified: Date
    
    init(name: String, category: ExerciseCategory) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.dateCreated = Date()
        self.dateModified = Date()
    }
    
    mutating func update(name: String, category: ExerciseCategory) {
        self.name = name
        self.category = category
        self.dateModified = Date()
    }
}

// Extension to make CustomExercise work with ExerciseType
extension CustomExercise {
    var exerciseType: ExerciseType? {
        // Try to find matching ExerciseType by name
        return ExerciseType.allCases.first { $0.rawValue.lowercased() == name.lowercased() }
    }
}
