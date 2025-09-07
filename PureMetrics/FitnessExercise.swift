import Foundation

// MARK: - Exercise Types

enum ExerciseType: String, CaseIterable, Codable {
    case benchPress = "Bench Press"
    case squat = "Squat"
    case deadlift = "Deadlift"
    case powerClean = "Power Clean"
    case jumpRope = "Jump Rope"
    case pullUps = "Pull-ups"
    case pushUps = "Push-ups"
    case overheadPress = "Overhead Press"
    case barbellRow = "Barbell Row"
    case lunges = "Lunges"
    case planks = "Planks"
    case burpees = "Burpees"
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    
    var icon: String {
        switch self {
        case .benchPress: return "dumbbell.fill"
        case .squat: return "figure.strengthtraining.traditional"
        case .deadlift: return "figure.strengthtraining.traditional"
        case .powerClean: return "figure.strengthtraining.traditional"
        case .jumpRope: return "figure.jumprope"
        case .pullUps: return "figure.pullups"
        case .pushUps: return "figure.push"
        case .overheadPress: return "figure.strengthtraining.traditional"
        case .barbellRow: return "figure.strengthtraining.traditional"
        case .lunges: return "figure.strengthtraining.traditional"
        case .planks: return "figure.core.training"
        case .burpees: return "figure.strengthtraining.traditional"
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        }
    }
    
    var color: String {
        switch self {
        case .benchPress, .squat, .deadlift, .powerClean, .overheadPress, .barbellRow:
            return "blue"
        case .jumpRope, .pullUps, .pushUps, .lunges, .planks, .burpees:
            return "green"
        case .running, .cycling, .swimming:
            return "orange"
        }
    }
    
    var unit: String {
        switch self {
        case .benchPress, .squat, .deadlift, .powerClean, .overheadPress, .barbellRow:
            return "lbs"
        case .jumpRope, .pullUps, .pushUps, .lunges, .planks, .burpees:
            return "reps"
        case .running, .cycling, .swimming:
            return "min"
        }
    }
    
    var supportsWeight: Bool {
        switch self {
        case .benchPress, .squat, .deadlift, .powerClean, .overheadPress, .barbellRow:
            return true
        default:
            return false
        }
    }
    
    var supportsTime: Bool {
        switch self {
        case .running, .cycling, .swimming, .planks, .jumpRope:
            return true
        default:
            return false
        }
    }
    
    var supportsReps: Bool {
        switch self {
        case .jumpRope, .pullUps, .pushUps, .lunges, .burpees:
            return true
        default:
            return false
        }
    }
}

// MARK: - Exercise Set Model

struct ExerciseSet: Codable, Identifiable {
    let id = UUID()
    let reps: Int?
    let weight: Double?
    let time: TimeInterval? // in seconds
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case reps, weight, time, timestamp
    }
    
    init(reps: Int? = nil, weight: Double? = nil, time: TimeInterval? = nil, timestamp: Date? = nil) {
        self.reps = reps
        self.weight = weight
        self.time = time
        self.timestamp = timestamp ?? Date()
    }
    
    var isValid: Bool {
        return (reps != nil && reps! > 0) || (weight != nil && weight! > 0) || (time != nil && time! > 0)
    }
    
    var displayString: String {
        var components: [String] = []
        
        if let reps = reps {
            components.append("\(reps) reps")
        }
        
        if let weight = weight {
            components.append("\(Int(weight)) lbs")
        }
        
        if let time = time {
            let minutes = Int(time) / 60
            let seconds = Int(time) % 60
            if minutes > 0 {
                components.append("\(minutes):\(String(format: "%02d", seconds))")
            } else {
                components.append("\(seconds)s")
            }
        }
        
        return components.joined(separator: " • ")
    }
}

// MARK: - Exercise Session Model

struct ExerciseSession: Codable, Identifiable {
    let id = UUID()
    let exerciseType: ExerciseType
    var sets: [ExerciseSet]
    let startTime: Date
    var endTime: Date?
    var isCompleted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case exerciseType, sets, startTime, endTime, isCompleted
    }
    
    init(exerciseType: ExerciseType, startTime: Date? = nil) {
        self.exerciseType = exerciseType
        self.sets = []
        self.startTime = startTime ?? Date()
    }
    
    mutating func addSet(_ set: ExerciseSet) {
        sets.append(set)
    }
    
    mutating func removeSet(at index: Int) {
        guard index >= 0 && index < sets.count else { return }
        sets.remove(at: index)
    }
    
    mutating func complete() {
        endTime = Date()
        isCompleted = true
    }
    
    var totalReps: Int {
        sets.compactMap { $0.reps }.reduce(0, +)
    }
    
    var totalWeight: Double {
        sets.compactMap { $0.weight }.reduce(0, +)
    }
    
    var totalTime: TimeInterval {
        sets.compactMap { $0.time }.reduce(0, +)
    }
    
    var averageWeight: Double? {
        let weights = sets.compactMap { $0.weight }
        guard !weights.isEmpty else { return nil }
        return weights.reduce(0, +) / Double(weights.count)
    }
    
    var maxWeight: Double? {
        sets.compactMap { $0.weight }.max()
    }
    
    var displayString: String {
        var components: [String] = []
        
        if !sets.isEmpty {
            components.append("\(sets.count) sets")
        }
        
        if totalReps > 0 {
            components.append("\(totalReps) reps")
        }
        
        if let avgWeight = averageWeight {
            components.append("\(Int(avgWeight)) lbs avg")
        }
        
        if totalTime > 0 {
            let minutes = Int(totalTime) / 60
            let seconds = Int(totalTime) % 60
            if minutes > 0 {
                components.append("\(minutes):\(String(format: "%02d", seconds))")
            } else {
                components.append("\(seconds)s")
            }
        }
        
        return components.isEmpty ? "No sets" : components.joined(separator: " • ")
    }
}

// MARK: - Fitness Session Model (Collection of Exercise Sessions)

struct FitnessSession: Codable, Identifiable {
    let id = UUID()
    var exerciseSessions: [ExerciseSession]
    let startTime: Date
    var endTime: Date?
    var isActive: Bool = true
    var isCompleted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case exerciseSessions, startTime, endTime, isActive, isCompleted
    }
    
    init(startTime: Date? = nil) {
        self.exerciseSessions = []
        self.startTime = startTime ?? Date()
    }
    
    mutating func addExerciseSession(_ session: ExerciseSession) {
        exerciseSessions.append(session)
    }
    
    mutating func removeExerciseSession(at index: Int) {
        guard index >= 0 && index < exerciseSessions.count else { return }
        exerciseSessions.remove(at: index)
    }
    
    mutating func complete() {
        endTime = Date()
        isActive = false
        isCompleted = true
    }
    
    var totalExercises: Int {
        exerciseSessions.count
    }
    
    var totalSets: Int {
        exerciseSessions.reduce(0) { $0 + $1.sets.count }
    }
    
    var totalReps: Int {
        exerciseSessions.reduce(0) { $0 + $1.totalReps }
    }
    
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }
    
    var displayString: String {
        var components: [String] = []
        
        if totalExercises > 0 {
            components.append("\(totalExercises) exercises")
        }
        
        if totalSets > 0 {
            components.append("\(totalSets) sets")
        }
        
        if totalReps > 0 {
            components.append("\(totalReps) reps")
        }
        
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            components.append("\(minutes):\(String(format: "%02d", seconds))")
        } else if seconds > 0 {
            components.append("\(seconds)s")
        }
        
        return components.isEmpty ? "No exercises" : components.joined(separator: " • ")
    }
}