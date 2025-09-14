import Foundation

// MARK: - Custom Workout Model

struct CustomWorkout: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String?
    let exercises: [WorkoutExercise]
    let createdDate: Date
    var isFavorite: Bool
    var lastUsed: Date?
    var useCount: Int = 0
    
    enum CodingKeys: String, CodingKey {
        case name, description, exercises, createdDate, isFavorite, lastUsed, useCount
    }
    
    init(name: String, description: String? = nil, exercises: [WorkoutExercise], createdDate: Date, isFavorite: Bool = false) {
        self.name = name
        self.description = description
        self.exercises = exercises
        self.createdDate = createdDate
        self.isFavorite = isFavorite
        self.useCount = 0
    }
    
    var displayName: String {
        if isFavorite {
            return "⭐ \(name)"
        }
        return name
    }
    
    var estimatedDuration: Int {
        // Estimate 2 minutes per set + rest time
        let totalSets = exercises.reduce(0) { $0 + $1.sets }
        let totalRestTime = exercises.reduce(0) { $0 + (($1.restTime ?? 0) * Double($1.sets)) }
        let exerciseTime = totalSets * 120 // 2 minutes per set
        return Int((Double(exerciseTime) + totalRestTime) / 60) // Convert to minutes
    }
    
    var totalExercises: Int {
        exercises.count
    }
    
    var totalSets: Int {
        exercises.reduce(0) { $0 + $1.sets }
    }
    
    var totalReps: Int {
        exercises.reduce(0) { $0 + (($1.reps ?? 0) * $1.sets) }
    }
}

// MARK: - Workout Exercise Extension

extension WorkoutExercise {
    init(exerciseType: ExerciseType, sets: Int, reps: Int, weight: Double? = nil, time: TimeInterval? = nil, restTime: TimeInterval = 60, notes: String = "", plannedSets: [PlannedSet]? = nil) {
        self.exerciseType = exerciseType
        self.customExercise = nil
        self.exerciseName = exerciseType.rawValue
        self.exerciseCategory = exerciseType.category
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.time = time
        self.restTime = restTime
        self.notes = notes
        self.plannedSets = plannedSets
    }
    
    var displayString: String {
        var components: [String] = []
        
        components.append("\(sets) sets")
        if let reps = reps {
            components.append("\(reps) reps")
        }
        
        if let weight = weight {
            components.append("\(Int(weight)) lbs")
        }
        
        if let time = time {
            components.append(formatTime(time))
        }
        
        if let restTime = restTime {
            components.append("\(formatTime(restTime)) rest")
        }
        
        return components.joined(separator: " • ")
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
