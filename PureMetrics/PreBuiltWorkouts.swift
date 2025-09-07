import Foundation

// MARK: - Pre-Built Workout Model

struct PreBuiltWorkout: Identifiable, Codable {
    let id = UUID()
    let name: String
    let category: WorkoutCategory
    let description: String
    let exercises: [WorkoutExercise]
    let estimatedDuration: Int // in minutes
    let difficulty: WorkoutDifficulty
    var isFavorite: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case name, category, description, exercises, estimatedDuration, difficulty, isFavorite
    }
    
    var displayName: String {
        if isFavorite {
            return "⭐ \(name)"
        }
        return name
    }
}

// MARK: - Workout Exercise Model

struct WorkoutExercise: Identifiable, Codable {
    let id = UUID()
    let exerciseType: ExerciseType
    let sets: Int
    let reps: Int?
    let weight: Double? // in lbs
    let time: TimeInterval? // in seconds
    let restTime: TimeInterval? // in seconds
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case exerciseType, sets, reps, weight, time, restTime, notes
    }
}

// MARK: - Workout Categories

enum WorkoutCategory: String, CaseIterable, Codable {
    case upperBody = "Upper Body"
    case lowerBody = "Lower Body"
    case fullBody = "Full Body"
    case cardio = "Cardio"
    case strength = "Strength"
    case hiit = "HIIT"
    case core = "Core"
    case flexibility = "Flexibility"
    
    var icon: String {
        switch self {
        case .upperBody: return "figure.arms.open"
        case .lowerBody: return "figure.strengthtraining.traditional"
        case .fullBody: return "figure.strengthtraining.traditional"
        case .cardio: return "heart.fill"
        case .strength: return "dumbbell.fill"
        case .hiit: return "bolt.fill"
        case .core: return "figure.core.training"
        case .flexibility: return "figure.flexibility"
        }
    }
    
    var color: String {
        switch self {
        case .upperBody: return "blue"
        case .lowerBody: return "green"
        case .fullBody: return "purple"
        case .cardio: return "red"
        case .strength: return "orange"
        case .hiit: return "yellow"
        case .core: return "pink"
        case .flexibility: return "teal"
        }
    }
}

// MARK: - Workout Difficulty

enum WorkoutDifficulty: String, CaseIterable, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "orange"
        case .advanced: return "red"
        }
    }
}

// MARK: - Pre-Built Workouts Data

class PreBuiltWorkoutManager: ObservableObject {
    @Published var workouts: [PreBuiltWorkout] = []
    
    init() {
        loadPreBuiltWorkouts()
        loadFavorites()
    }
    
    private func loadPreBuiltWorkouts() {
        workouts = [
            // Upper Body Workouts
            PreBuiltWorkout(
                name: "Push Day",
                category: .upperBody,
                description: "Focus on chest, shoulders, and triceps",
                exercises: [
                    WorkoutExercise(exerciseType: .benchPress, sets: 4, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Focus on controlled movement"),
                    WorkoutExercise(exerciseType: .inclineBenchPress, sets: 3, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Slight incline"),
                    WorkoutExercise(exerciseType: .overheadPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Core engaged"),
                    WorkoutExercise(exerciseType: .lateralRaise, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Light weight, high reps"),
                    WorkoutExercise(exerciseType: .tricepsKickback, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Squeeze at the top")
                ],
                estimatedDuration: 45,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "Pull Day",
                category: .upperBody,
                description: "Focus on back and biceps",
                exercises: [
                    WorkoutExercise(exerciseType: .deadlifts, sets: 4, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Heavy compound movement"),
                    WorkoutExercise(exerciseType: .bentOverRows, sets: 4, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Squeeze shoulder blades"),
                    WorkoutExercise(exerciseType: .pullUps, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Full range of motion"),
                    WorkoutExercise(exerciseType: .barbellCurl, sets: 3, reps: 10, weight: nil, time: nil, restTime: 60, notes: "Control the negative"),
                    WorkoutExercise(exerciseType: .hammerCurl, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Neutral grip")
                ],
                estimatedDuration: 50,
                difficulty: .intermediate
            ),
            
            // Lower Body Workouts
            PreBuiltWorkout(
                name: "Leg Day",
                category: .lowerBody,
                description: "Complete lower body workout",
                exercises: [
                    WorkoutExercise(exerciseType: .squat, sets: 4, reps: 8, weight: nil, time: nil, restTime: 180, notes: "Deep squats, full range"),
                    WorkoutExercise(exerciseType: .romanianDeadlift, sets: 4, reps: 10, weight: nil, time: nil, restTime: 120, notes: "Feel the stretch"),
                    WorkoutExercise(exerciseType: .lunges, sets: 3, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Alternating legs"),
                    WorkoutExercise(exerciseType: .standingCalfRaise, sets: 4, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Hold at the top"),
                    WorkoutExercise(exerciseType: .hipThrust, sets: 3, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Squeeze glutes")
                ],
                estimatedDuration: 55,
                difficulty: .intermediate
            ),
            
            // Full Body Workouts
            PreBuiltWorkout(
                name: "Full Body Strength",
                category: .fullBody,
                description: "Complete body workout in one session",
                exercises: [
                    WorkoutExercise(exerciseType: .squat, sets: 3, reps: 10, weight: nil, time: nil, restTime: 120, notes: "Start with legs"),
                    WorkoutExercise(exerciseType: .benchPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Upper body focus"),
                    WorkoutExercise(exerciseType: .bentOverRows, sets: 3, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Back strength"),
                    WorkoutExercise(exerciseType: .overheadPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Shoulder stability"),
                    WorkoutExercise(exerciseType: .deadlifts, sets: 2, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Heavy compound finish")
                ],
                estimatedDuration: 60,
                difficulty: .intermediate
            ),
            
            // Cardio Workouts
            PreBuiltWorkout(
                name: "HIIT Cardio",
                category: .cardio,
                description: "High intensity interval training",
                exercises: [
                    WorkoutExercise(exerciseType: .kettlebellSwing, sets: 4, reps: nil, weight: nil, time: 30, restTime: 30, notes: "High intensity"),
                    WorkoutExercise(exerciseType: .burpees, sets: 4, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Full body movement"),
                    WorkoutExercise(exerciseType: .mountainClimbers, sets: 4, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Core engaged"),
                    WorkoutExercise(exerciseType: .jumpingJacks, sets: 4, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Keep moving"),
                    WorkoutExercise(exerciseType: .highKnees, sets: 4, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Knees to chest")
                ],
                estimatedDuration: 25,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "Sprint Intervals",
                category: .cardio,
                description: "Running sprint intervals",
                exercises: [
                    WorkoutExercise(exerciseType: .sprint, sets: 6, reps: nil, weight: nil, time: 30, restTime: 60, notes: "All out effort"),
                    WorkoutExercise(exerciseType: .walk, sets: 6, reps: nil, weight: nil, time: 60, restTime: 0, notes: "Active recovery")
                ],
                estimatedDuration: 15,
                difficulty: .intermediate
            ),
            
            // Core Workouts
            PreBuiltWorkout(
                name: "Core Blast",
                category: .core,
                description: "Intensive core strengthening",
                exercises: [
                    WorkoutExercise(exerciseType: .weightedPlank, sets: 3, reps: nil, weight: nil, time: 60, restTime: 60, notes: "Hold steady"),
                    WorkoutExercise(exerciseType: .weightedCrunch, sets: 3, reps: 20, weight: nil, time: nil, restTime: 45, notes: "Slow and controlled"),
                    WorkoutExercise(exerciseType: .russianTwist, sets: 3, reps: 30, weight: nil, time: nil, restTime: 45, notes: "Rotate fully"),
                    WorkoutExercise(exerciseType: .hangingLegRaise, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Lift legs high"),
                    WorkoutExercise(exerciseType: .abRollout, sets: 3, reps: 10, weight: nil, time: nil, restTime: 60, notes: "Roll out slowly")
                ],
                estimatedDuration: 30,
                difficulty: .intermediate
            ),
            
            // Beginner Workouts
            PreBuiltWorkout(
                name: "Beginner Upper Body",
                category: .upperBody,
                description: "Perfect for beginners starting upper body training",
                exercises: [
                    WorkoutExercise(exerciseType: .pushUps, sets: 3, reps: 8, weight: nil, time: nil, restTime: 60, notes: "Knee push-ups if needed"),
                    WorkoutExercise(exerciseType: .dumbbellCurl, sets: 3, reps: 10, weight: nil, time: nil, restTime: 45, notes: "Light weight"),
                    WorkoutExercise(exerciseType: .lateralRaise, sets: 3, reps: 12, weight: nil, time: nil, restTime: 45, notes: "Very light weight"),
                    WorkoutExercise(exerciseType: .tricepsKickback, sets: 3, reps: 10, weight: nil, time: nil, restTime: 45, notes: "Focus on form")
                ],
                estimatedDuration: 25,
                difficulty: .beginner
            ),
            
            PreBuiltWorkout(
                name: "Beginner Lower Body",
                category: .lowerBody,
                description: "Perfect for beginners starting lower body training",
                exercises: [
                    WorkoutExercise(exerciseType: .bodyweightSquat, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Focus on form"),
                    WorkoutExercise(exerciseType: .lunges, sets: 3, reps: 10, weight: nil, time: nil, restTime: 60, notes: "Alternating legs"),
                    WorkoutExercise(exerciseType: .gluteBridge, sets: 3, reps: 15, weight: nil, time: nil, restTime: 45, notes: "Squeeze glutes"),
                    WorkoutExercise(exerciseType: .standingCalfRaise, sets: 3, reps: 15, weight: nil, time: nil, restTime: 30, notes: "Bodyweight only")
                ],
                estimatedDuration: 20,
                difficulty: .beginner
            ),
            
            // Advanced Workouts
            PreBuiltWorkout(
                name: "Powerlifting Max Out",
                category: .strength,
                description: "Heavy compound movements for maximum strength",
                exercises: [
                    WorkoutExercise(exerciseType: .squat, sets: 5, reps: 5, weight: nil, time: nil, restTime: 300, notes: "Heavy weight, focus on form"),
                    WorkoutExercise(exerciseType: .benchPress, sets: 5, reps: 5, weight: nil, time: nil, restTime: 300, notes: "Max effort sets"),
                    WorkoutExercise(exerciseType: .deadlifts, sets: 5, reps: 5, weight: nil, time: nil, restTime: 300, notes: "Heavy deadlifts"),
                    WorkoutExercise(exerciseType: .overheadPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 180, notes: "Accessory work"),
                    WorkoutExercise(exerciseType: .bentOverRows, sets: 3, reps: 8, weight: nil, time: nil, restTime: 180, notes: "Heavy rows")
                ],
                estimatedDuration: 90,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Olympic Lifting Complex",
                category: .strength,
                description: "Olympic lifting movements for explosive power",
                exercises: [
                    WorkoutExercise(exerciseType: .snatch, sets: 5, reps: 3, weight: nil, time: nil, restTime: 240, notes: "Focus on technique"),
                    WorkoutExercise(exerciseType: .cleanAndPress, sets: 5, reps: 3, weight: nil, time: nil, restTime: 240, notes: "Explosive movement"),
                    WorkoutExercise(exerciseType: .jerk, sets: 5, reps: 3, weight: nil, time: nil, restTime: 240, notes: "Overhead stability"),
                    WorkoutExercise(exerciseType: .powerClean, sets: 4, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Power development"),
                    WorkoutExercise(exerciseType: .thruster, sets: 3, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Conditioning finisher")
                ],
                estimatedDuration: 75,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Bodybuilding Volume",
                category: .strength,
                description: "High volume bodybuilding style workout",
                exercises: [
                    WorkoutExercise(exerciseType: .benchPress, sets: 4, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Moderate weight, high reps"),
                    WorkoutExercise(exerciseType: .inclineBenchPress, sets: 4, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Upper chest focus"),
                    WorkoutExercise(exerciseType: .chestFly, sets: 3, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Stretch and squeeze"),
                    WorkoutExercise(exerciseType: .barbellCurl, sets: 4, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Slow and controlled"),
                    WorkoutExercise(exerciseType: .dumbbellCurl, sets: 4, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Alternating arms"),
                    WorkoutExercise(exerciseType: .tricepsKickback, sets: 4, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Isolation work"),
                    WorkoutExercise(exerciseType: .lateralRaise, sets: 4, reps: 15, weight: nil, time: nil, restTime: 45, notes: "Light weight, high reps")
                ],
                estimatedDuration: 80,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "CrossFit WOD",
                category: .hiit,
                description: "High intensity CrossFit style workout",
                exercises: [
                    WorkoutExercise(exerciseType: .thruster, sets: 5, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Moderate weight"),
                    WorkoutExercise(exerciseType: .pullUps, sets: 5, reps: 10, weight: nil, time: nil, restTime: 60, notes: "Strict form"),
                    WorkoutExercise(exerciseType: .burpees, sets: 5, reps: 10, weight: nil, time: nil, restTime: 60, notes: "Full body movement"),
                    WorkoutExercise(exerciseType: .kettlebellSwing, sets: 5, reps: 20, weight: nil, time: nil, restTime: 60, notes: "Hip drive"),
                    WorkoutExercise(exerciseType: .boxJumps, sets: 5, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Explosive power")
                ],
                estimatedDuration: 30,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Spartan Race Prep",
                category: .fullBody,
                description: "Functional fitness for obstacle course racing",
                exercises: [
                    WorkoutExercise(exerciseType: .farmersCarry, sets: 4, reps: nil, weight: nil, time: 60, restTime: 90, notes: "Heavy carry"),
                    WorkoutExercise(exerciseType: .sandbagLifts, sets: 4, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Functional strength"),
                    WorkoutExercise(exerciseType: .overheadCarry, sets: 4, reps: nil, weight: nil, time: 30, restTime: 90, notes: "Overhead stability"),
                    WorkoutExercise(exerciseType: .pullUps, sets: 4, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Grip strength"),
                    WorkoutExercise(exerciseType: .burpees, sets: 4, reps: 20, weight: nil, time: nil, restTime: 60, notes: "Cardio endurance"),
                    WorkoutExercise(exerciseType: .turkishGetUp, sets: 3, reps: 5, weight: nil, time: nil, restTime: 120, notes: "Core stability")
                ],
                estimatedDuration: 70,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Strongman Training",
                category: .strength,
                description: "Heavy strongman movements and carries",
                exercises: [
                    WorkoutExercise(exerciseType: .deadlifts, sets: 5, reps: 3, weight: nil, time: nil, restTime: 300, notes: "Heavy deadlifts"),
                    WorkoutExercise(exerciseType: .farmersCarry, sets: 4, reps: nil, weight: nil, time: 60, restTime: 120, notes: "Heavy carry"),
                    WorkoutExercise(exerciseType: .overheadCarry, sets: 4, reps: nil, weight: nil, time: 30, restTime: 120, notes: "Overhead walk"),
                    WorkoutExercise(exerciseType: .zercherCarry, sets: 4, reps: nil, weight: nil, time: 45, restTime: 120, notes: "Zercher position"),
                    WorkoutExercise(exerciseType: .sandbagLifts, sets: 4, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Heavy sandbag"),
                    WorkoutExercise(exerciseType: .suitcaseCarry, sets: 3, reps: nil, weight: nil, time: 30, restTime: 90, notes: "Unilateral carry")
                ],
                estimatedDuration: 90,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Calisthenics Mastery",
                category: .fullBody,
                description: "Advanced bodyweight movements and skills",
                exercises: [
                    WorkoutExercise(exerciseType: .pullUps, sets: 5, reps: 15, weight: nil, time: nil, restTime: 90, notes: "Strict pull-ups"),
                    WorkoutExercise(exerciseType: .handstandPushUps, sets: 4, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Against wall"),
                    WorkoutExercise(exerciseType: .muscleUps, sets: 4, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Ring muscle-ups"),
                    WorkoutExercise(exerciseType: .planche, sets: 4, reps: nil, weight: nil, time: 15, restTime: 120, notes: "Hold position"),
                    WorkoutExercise(exerciseType: .frontLever, sets: 4, reps: nil, weight: nil, time: 10, restTime: 120, notes: "Horizontal hold"),
                    WorkoutExercise(exerciseType: .humanFlag, sets: 3, reps: nil, weight: nil, time: 8, restTime: 120, notes: "Side hold")
                ],
                estimatedDuration: 60,
                difficulty: .advanced
            ),
            
            // HIIT Workouts
            PreBuiltWorkout(
                name: "Tabata Blast",
                category: .hiit,
                description: "Classic Tabata protocol - 20 seconds work, 10 seconds rest",
                exercises: [
                    WorkoutExercise(exerciseType: .burpees, sets: 8, reps: nil, weight: nil, time: 20, restTime: 10, notes: "All out effort"),
                    WorkoutExercise(exerciseType: .mountainClimbers, sets: 8, reps: nil, weight: nil, time: 20, restTime: 10, notes: "Fast pace"),
                    WorkoutExercise(exerciseType: .jumpingJacks, sets: 8, reps: nil, weight: nil, time: 20, restTime: 10, notes: "Keep moving"),
                    WorkoutExercise(exerciseType: .highKnees, sets: 8, reps: nil, weight: nil, time: 20, restTime: 10, notes: "Knees to chest")
                ],
                estimatedDuration: 16,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "EMOM Hell",
                category: .hiit,
                description: "Every Minute On the Minute - complete reps within 60 seconds",
                exercises: [
                    WorkoutExercise(exerciseType: .thruster, sets: 10, reps: 10, weight: nil, time: nil, restTime: 0, notes: "Moderate weight"),
                    WorkoutExercise(exerciseType: .burpees, sets: 10, reps: 8, weight: nil, time: nil, restTime: 0, notes: "Full body"),
                    WorkoutExercise(exerciseType: .pullUps, sets: 10, reps: 6, weight: nil, time: nil, restTime: 0, notes: "Strict form"),
                    WorkoutExercise(exerciseType: .kettlebellSwing, sets: 10, reps: 15, weight: nil, time: nil, restTime: 0, notes: "Hip drive")
                ],
                estimatedDuration: 40,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "AMRAP Madness",
                category: .hiit,
                description: "As Many Rounds As Possible in 20 minutes",
                exercises: [
                    WorkoutExercise(exerciseType: .boxJumps, sets: 1, reps: 15, weight: nil, time: nil, restTime: 0, notes: "Explosive power"),
                    WorkoutExercise(exerciseType: .wallBall, sets: 1, reps: 20, weight: nil, time: nil, restTime: 0, notes: "Full squat"),
                    WorkoutExercise(exerciseType: .burpees, sets: 1, reps: 10, weight: nil, time: nil, restTime: 0, notes: "Chest to ground"),
                    WorkoutExercise(exerciseType: .kettlebellSwing, sets: 1, reps: 25, weight: nil, time: nil, restTime: 0, notes: "Hip snap")
                ],
                estimatedDuration: 20,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Death by Burpees",
                category: .hiit,
                description: "Progressive burpee challenge - add 1 burpee each minute",
                exercises: [
                    WorkoutExercise(exerciseType: .burpees, sets: 1, reps: 1, weight: nil, time: nil, restTime: 0, notes: "Minute 1: 1 burpee"),
                    WorkoutExercise(exerciseType: .burpees, sets: 1, reps: 2, weight: nil, time: nil, restTime: 0, notes: "Minute 2: 2 burpees"),
                    WorkoutExercise(exerciseType: .burpees, sets: 1, reps: 3, weight: nil, time: nil, restTime: 0, notes: "Minute 3: 3 burpees"),
                    WorkoutExercise(exerciseType: .burpees, sets: 1, reps: 4, weight: nil, time: nil, restTime: 0, notes: "Continue until failure")
                ],
                estimatedDuration: 15,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "HIIT Core Crusher",
                category: .hiit,
                description: "High intensity core-focused workout",
                exercises: [
                    WorkoutExercise(exerciseType: .mountainClimbers, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Fast pace"),
                    WorkoutExercise(exerciseType: .russianTwist, sets: 4, reps: 30, weight: nil, time: nil, restTime: 15, notes: "Full rotation"),
                    WorkoutExercise(exerciseType: .burpees, sets: 4, reps: nil, weight: nil, time: 30, restTime: 15, notes: "Core engaged"),
                    WorkoutExercise(exerciseType: .weightedPlank, sets: 4, reps: nil, weight: nil, time: 30, restTime: 15, notes: "Hold steady"),
                    WorkoutExercise(exerciseType: .hangingLegRaise, sets: 4, reps: 15, weight: nil, time: nil, restTime: 15, notes: "Controlled movement")
                ],
                estimatedDuration: 25,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "Sprint & Strength",
                category: .hiit,
                description: "Alternating sprint intervals with strength exercises",
                exercises: [
                    WorkoutExercise(exerciseType: .sprint, sets: 5, reps: nil, weight: nil, time: 30, restTime: 30, notes: "All out sprint"),
                    WorkoutExercise(exerciseType: .thruster, sets: 5, reps: 12, weight: nil, time: nil, restTime: 30, notes: "Moderate weight"),
                    WorkoutExercise(exerciseType: .sprint, sets: 5, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Recovery sprint"),
                    WorkoutExercise(exerciseType: .burpees, sets: 5, reps: 10, weight: nil, time: nil, restTime: 30, notes: "Full body")
                ],
                estimatedDuration: 20,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Kettlebell HIIT",
                category: .hiit,
                description: "High intensity kettlebell workout",
                exercises: [
                    WorkoutExercise(exerciseType: .kettlebellSwing, sets: 4, reps: nil, weight: nil, time: 40, restTime: 20, notes: "Hip drive"),
                    WorkoutExercise(exerciseType: .kettlebellGobletSquat, sets: 4, reps: 15, weight: nil, time: nil, restTime: 20, notes: "Deep squats"),
                    WorkoutExercise(exerciseType: .kettlebellTurkishGetUp, sets: 4, reps: 5, weight: nil, time: nil, restTime: 20, notes: "Slow and controlled"),
                    WorkoutExercise(exerciseType: .kettlebellSwing, sets: 4, reps: nil, weight: nil, time: 30, restTime: 20, notes: "Power swings")
                ],
                estimatedDuration: 30,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "Bodyweight Blitz",
                category: .hiit,
                description: "No equipment needed - pure bodyweight HIIT",
                exercises: [
                    WorkoutExercise(exerciseType: .burpees, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Full movement"),
                    WorkoutExercise(exerciseType: .mountainClimbers, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Fast pace"),
                    WorkoutExercise(exerciseType: .jumpingJacks, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Keep moving"),
                    WorkoutExercise(exerciseType: .highKnees, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Knees up"),
                    WorkoutExercise(exerciseType: .pushUps, sets: 4, reps: 15, weight: nil, time: nil, restTime: 15, notes: "Chest to ground")
                ],
                estimatedDuration: 25,
                difficulty: .beginner
            ),
            
            PreBuiltWorkout(
                name: "Metabolic Mayhem",
                category: .hiit,
                description: "High metabolic demand workout",
                exercises: [
                    WorkoutExercise(exerciseType: .thruster, sets: 5, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Moderate weight"),
                    WorkoutExercise(exerciseType: .burpees, sets: 5, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Full body"),
                    WorkoutExercise(exerciseType: .kettlebellSwing, sets: 5, reps: 20, weight: nil, time: nil, restTime: 60, notes: "Hip drive"),
                    WorkoutExercise(exerciseType: .boxJumps, sets: 5, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Explosive power")
                ],
                estimatedDuration: 35,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Quick HIIT",
                category: .hiit,
                description: "Fast 10-minute HIIT session",
                exercises: [
                    WorkoutExercise(exerciseType: .burpees, sets: 3, reps: nil, weight: nil, time: 30, restTime: 30, notes: "All out effort"),
                    WorkoutExercise(exerciseType: .mountainClimbers, sets: 3, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Fast pace"),
                    WorkoutExercise(exerciseType: .jumpingJacks, sets: 3, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Keep moving"),
                    WorkoutExercise(exerciseType: .highKnees, sets: 3, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Knees to chest")
                ],
                estimatedDuration: 10,
                difficulty: .beginner
            ),
            
            PreBuiltWorkout(
                name: "HIIT Upper Body",
                category: .hiit,
                description: "High intensity upper body focused workout",
                exercises: [
                    WorkoutExercise(exerciseType: .pushUps, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "As many as possible"),
                    WorkoutExercise(exerciseType: .pullUps, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Strict form"),
                    WorkoutExercise(exerciseType: .burpees, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Full movement"),
                    WorkoutExercise(exerciseType: .dips, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Controlled descent")
                ],
                estimatedDuration: 20,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "HIIT Lower Body",
                category: .hiit,
                description: "High intensity lower body focused workout",
                exercises: [
                    WorkoutExercise(exerciseType: .squat, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Bodyweight squats"),
                    WorkoutExercise(exerciseType: .lunges, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Alternating legs"),
                    WorkoutExercise(exerciseType: .jumpingJacks, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Keep moving"),
                    WorkoutExercise(exerciseType: .highKnees, sets: 4, reps: nil, weight: nil, time: 45, restTime: 15, notes: "Knees to chest"),
                    WorkoutExercise(exerciseType: .gluteBridge, sets: 4, reps: 20, weight: nil, time: nil, restTime: 15, notes: "Squeeze glutes")
                ],
                estimatedDuration: 25,
                difficulty: .beginner
            ),
            
            PreBuiltWorkout(
                name: "HIIT Cardio Blast",
                category: .hiit,
                description: "Pure cardio high intensity workout",
                exercises: [
                    WorkoutExercise(exerciseType: .burpees, sets: 5, reps: nil, weight: nil, time: 30, restTime: 30, notes: "All out effort"),
                    WorkoutExercise(exerciseType: .mountainClimbers, sets: 5, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Fast pace"),
                    WorkoutExercise(exerciseType: .jumpingJacks, sets: 5, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Keep moving"),
                    WorkoutExercise(exerciseType: .highKnees, sets: 5, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Knees to chest"),
                    WorkoutExercise(exerciseType: .sprint, sets: 5, reps: nil, weight: nil, time: 30, restTime: 30, notes: "All out sprint")
                ],
                estimatedDuration: 30,
                difficulty: .intermediate
            )
        ]
    }
    
    func getWorkouts(for category: WorkoutCategory) -> [PreBuiltWorkout] {
        return workouts.filter { $0.category == category }
    }
    
    func getWorkouts(for difficulty: WorkoutDifficulty) -> [PreBuiltWorkout] {
        return workouts.filter { $0.difficulty == difficulty }
    }
    
    func getFavoriteWorkouts() -> [PreBuiltWorkout] {
        return workouts.filter { $0.isFavorite }
    }
    
    func toggleFavorite(_ workout: PreBuiltWorkout) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index].isFavorite.toggle()
            saveFavorites()
        }
    }
    
    private func saveFavorites() {
        // Save favorite status to UserDefaults
        let favoriteIds = workouts.filter { $0.isFavorite }.map { $0.id.uuidString }
        UserDefaults.standard.set(favoriteIds, forKey: "PreBuiltWorkoutFavorites")
    }
    
    private func loadFavorites() {
        // Load favorite status from UserDefaults
        guard let favoriteIds = UserDefaults.standard.array(forKey: "PreBuiltWorkoutFavorites") as? [String] else { return }
        
        for (index, workout) in workouts.enumerated() {
            if favoriteIds.contains(workout.id.uuidString) {
                workouts[index].isFavorite = true
            }
        }
    }
}

// MARK: - Additional Exercise Types for Workouts

extension ExerciseType {
    static let bodyweightSquat = ExerciseType.squat
    static let pushUps = ExerciseType.weightedPushUps
    static let burpees = ExerciseType.manMaker
    static let mountainClimbers = ExerciseType.turkishGetUp
    static let jumpingJacks = ExerciseType.kettlebellSwing
    static let highKnees = ExerciseType.kettlebellSwing
    static let sprint = ExerciseType.kettlebellSwing
    static let walk = ExerciseType.kettlebellSwing
    static let hammerCurl = ExerciseType.dumbbellCurl
    static let boxJumps = ExerciseType.stepUps
    static let handstandPushUps = ExerciseType.overheadPress
    static let muscleUps = ExerciseType.pullUps
    static let planche = ExerciseType.weightedPlank
    static let frontLever = ExerciseType.hangingLegRaise
    static let humanFlag = ExerciseType.sideBend
    static let wallBall = ExerciseType.kettlebellSwing
    static let kettlebellGobletSquat = ExerciseType.squat
    static let dips = ExerciseType.tricepsKickback
    static let gluteBridge = ExerciseType.hipThrust
}
