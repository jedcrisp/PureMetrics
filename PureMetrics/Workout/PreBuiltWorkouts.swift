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
    var isFavorite: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, category, description, exercises, estimatedDuration, difficulty, isFavorite
    }
    
    init(name: String, category: WorkoutCategory, description: String, exercises: [WorkoutExercise], estimatedDuration: Int, difficulty: WorkoutDifficulty, isFavorite: Bool = false) {
        self.name = name
        self.category = category
        self.description = description
        self.exercises = exercises
        self.estimatedDuration = estimatedDuration
        self.difficulty = difficulty
        self.isFavorite = isFavorite
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
    let exerciseType: ExerciseType?
    let customExercise: CustomExercise?
    let exerciseName: String // Display name for the exercise
    let exerciseCategory: ExerciseCategory // Category for UI purposes
    let sets: Int
    let reps: Int?
    let weight: Double? // in lbs
    let time: TimeInterval? // in seconds
    let restTime: TimeInterval? // in seconds
    let notes: String?
    let plannedSets: [PlannedSet]? // Detailed set information
    
    enum CodingKeys: String, CodingKey {
        case exerciseType, customExercise, exerciseName, exerciseCategory, sets, reps, weight, time, restTime, notes, plannedSets
    }
    
    // Initialize with built-in exercise
    init(exerciseType: ExerciseType, sets: Int, reps: Int? = nil, weight: Double? = nil, time: TimeInterval? = nil, restTime: TimeInterval? = nil, notes: String? = nil, plannedSets: [PlannedSet]? = nil) {
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
    
    // Initialize with custom exercise
    init(customExercise: CustomExercise, sets: Int, reps: Int? = nil, weight: Double? = nil, time: TimeInterval? = nil, restTime: TimeInterval? = nil, notes: String? = nil, plannedSets: [PlannedSet]? = nil) {
        self.exerciseType = nil
        self.customExercise = customExercise
        self.exerciseName = customExercise.name
        self.exerciseCategory = customExercise.category
        self.sets = sets
        self.reps = reps
        self.weight = weight
        self.time = time
        self.restTime = restTime
        self.notes = notes
        self.plannedSets = plannedSets
    }
    
    // Computed property to check if this is a custom exercise
    var isCustomExercise: Bool {
        return customExercise != nil
    }
}

// MARK: - Planned Set Model

struct PlannedSet: Identifiable, Codable {
    let id = UUID()
    let setNumber: Int
    var reps: Int?
    var weight: Double? // in lbs
    var time: TimeInterval? // in seconds
    var distance: Double? // in miles
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case setNumber, reps, weight, time, distance, notes
    }
    
    init(setNumber: Int, reps: Int? = nil, weight: Double? = nil, time: TimeInterval? = nil, distance: Double? = nil, notes: String? = nil) {
        self.setNumber = setNumber
        self.reps = reps
        self.weight = weight
        self.time = time
        self.distance = distance
        self.notes = notes
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
            // Beginner Upper Body Workouts
            PreBuiltWorkout(
                name: "Beginner Chest Workout",
                category: .upperBody,
                description: "Perfect for building chest strength and muscle. Focus on proper form and controlled movements.",
                exercises: [
                    WorkoutExercise(exerciseType: .benchPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Start with lighter weight, focus on full range of motion"),
                    WorkoutExercise(exerciseType: .inclineBenchPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Targets upper chest, keep core tight"),
                    WorkoutExercise(exerciseType: .chestFly, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Control the weight, feel the stretch in your chest"),
                    WorkoutExercise(exerciseType: .weightedPushUps, sets: 3, reps: 10, weight: nil, time: nil, restTime: 60, notes: "Use bodyweight if no weight available, keep straight line"),
                    WorkoutExercise(exerciseType: .squeezePress, sets: 2, reps: 15, weight: nil, time: nil, restTime: 45, notes: "Light weight, focus on squeezing chest muscles")
                ],
                estimatedDuration: 40,
                difficulty: .beginner
            ),
            
            PreBuiltWorkout(
                name: "Beginner Back Workout",
                category: .upperBody,
                description: "Build a strong, defined back with these essential exercises. Focus on pulling movements.",
                exercises: [
                    WorkoutExercise(exerciseType: .latPulldown, sets: 3, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Pull to chest, squeeze shoulder blades together"),
                    WorkoutExercise(exerciseType: .bentOverRows, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Keep back straight, pull elbows back"),
                    WorkoutExercise(exerciseType: .deadlifts, sets: 3, reps: 6, weight: nil, time: nil, restTime: 120, notes: "Start light, focus on hip hinge movement"),
                    WorkoutExercise(exerciseType: .singleArmDumbbellRow, sets: 3, reps: 10, weight: nil, time: nil, restTime: 60, notes: "One arm at a time, support with other hand"),
                    WorkoutExercise(exerciseType: .invertedRow, sets: 2, reps: 8, weight: nil, time: nil, restTime: 60, notes: "Use bodyweight, adjust angle for difficulty")
                ],
                estimatedDuration: 45,
                difficulty: .beginner
            ),
            
            PreBuiltWorkout(
                name: "Beginner Shoulders Workout",
                category: .upperBody,
                description: "Develop strong, rounded shoulders with these targeted exercises. Perfect for shoulder stability.",
                exercises: [
                    WorkoutExercise(exerciseType: .overheadPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Press straight up, keep core tight"),
                    WorkoutExercise(exerciseType: .lateralRaise, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Light weight, raise to shoulder height"),
                    WorkoutExercise(exerciseType: .frontRaise, sets: 3, reps: 10, weight: nil, time: nil, restTime: 60, notes: "Alternate arms, control the movement"),
                    WorkoutExercise(exerciseType: .rearDeltFly, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Bent over position, squeeze shoulder blades"),
                    WorkoutExercise(exerciseType: .uprightRow, sets: 2, reps: 10, weight: nil, time: nil, restTime: 45, notes: "Keep elbows high, pull to chest level")
                ],
                estimatedDuration: 35,
                difficulty: .beginner
            ),
            
            PreBuiltWorkout(
                name: "Beginner Arms Workout",
                category: .upperBody,
                description: "Build strong biceps and triceps with these essential arm exercises. Focus on controlled movements.",
                exercises: [
                    WorkoutExercise(exerciseType: .barbellCurl, sets: 3, reps: 10, weight: nil, time: nil, restTime: 60, notes: "Keep elbows at sides, full range of motion"),
                    WorkoutExercise(exerciseType: .dumbbellCurl, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Alternate arms, squeeze at the top"),
                    WorkoutExercise(exerciseType: .closeGripBenchPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Narrow grip, focus on triceps"),
                    WorkoutExercise(exerciseType: .skullCrushers, sets: 3, reps: 10, weight: nil, time: nil, restTime: 60, notes: "Keep elbows stable, lower to forehead"),
                    WorkoutExercise(exerciseType: .tricepsKickback, sets: 2, reps: 12, weight: nil, time: nil, restTime: 45, notes: "Bent over position, extend arm back")
                ],
                estimatedDuration: 35,
                difficulty: .beginner
            ),
            
            PreBuiltWorkout(
                name: "Beginner Chest & Back Workout",
                category: .upperBody,
                description: "Complete upper body workout targeting both chest and back muscles. Great for balanced development.",
                exercises: [
                    WorkoutExercise(exerciseType: .benchPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Start with chest, focus on form"),
                    WorkoutExercise(exerciseType: .latPulldown, sets: 3, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Pull to chest, engage lats"),
                    WorkoutExercise(exerciseType: .inclineBenchPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Upper chest focus, controlled movement"),
                    WorkoutExercise(exerciseType: .bentOverRows, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Pull elbows back, squeeze shoulder blades"),
                    WorkoutExercise(exerciseType: .chestFly, sets: 2, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Stretch and squeeze, feel the burn")
                ],
                estimatedDuration: 50,
                difficulty: .beginner
            ),
            
            // Beginner Lower Body Workouts
            PreBuiltWorkout(
                name: "Beginner Legs Workout",
                category: .lowerBody,
                description: "Build strong legs and glutes with these fundamental lower body exercises. Perfect for beginners.",
                exercises: [
                    WorkoutExercise(exerciseType: .squat, sets: 3, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Keep your back straight, go as low as comfortable"),
                    WorkoutExercise(exerciseType: .lunges, sets: 3, reps: 8, weight: nil, time: nil, restTime: 60, notes: "Alternate legs, maintain balance"),
                    WorkoutExercise(exerciseType: .legPress, sets: 3, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Start with lighter weight, focus on form"),
                    WorkoutExercise(exerciseType: .standingCalfRaise, sets: 3, reps: 15, weight: nil, time: nil, restTime: 45, notes: "Slow and controlled movement"),
                    WorkoutExercise(exerciseType: .gluteBridge, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Squeeze glutes at the top")
                ],
                estimatedDuration: 35,
                difficulty: .beginner
            ),
            
            PreBuiltWorkout(
                name: "Beginner Glutes Workout",
                category: .lowerBody,
                description: "Target your glutes specifically with these beginner-friendly exercises for a stronger backside.",
                exercises: [
                    WorkoutExercise(exerciseType: .gluteBridge, sets: 3, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Hold at the top for 2 seconds"),
                    WorkoutExercise(exerciseType: .hipThrust, sets: 3, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Use a bench or elevated surface"),
                    WorkoutExercise(exerciseType: .donkeyCalfRaise, sets: 3, reps: 12, weight: nil, time: nil, restTime: 45, notes: "Keep core tight, slow movement"),
                    WorkoutExercise(exerciseType: .lateralRaise, sets: 3, reps: 10, weight: nil, time: nil, restTime: 45, notes: "Maintain balance, controlled motion"),
                    WorkoutExercise(exerciseType: .squat, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Wide stance, toes pointed out")
                ],
                estimatedDuration: 30,
                difficulty: .beginner
            ),
            
            // Beginner Full Body Workouts
            PreBuiltWorkout(
                name: "Beginner Full Body Workout",
                category: .fullBody,
                description: "A complete workout targeting all major muscle groups. Perfect for building overall strength.",
                exercises: [
                    WorkoutExercise(exerciseType: .squat, sets: 3, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Foundation movement for legs"),
                    WorkoutExercise(exerciseType: .weightedPushUps, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Modify on knees if needed"),
                    WorkoutExercise(exerciseType: .bentOverRows, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Keep back straight, pull to chest"),
                    WorkoutExercise(exerciseType: .overheadPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Start with lighter weights"),
                    WorkoutExercise(exerciseType: .weightedPlank, sets: 3, reps: nil, weight: nil, time: 30, restTime: 60, notes: "Hold for 30 seconds, keep core tight")
                ],
                estimatedDuration: 45,
                difficulty: .beginner
            ),
            
            PreBuiltWorkout(
                name: "Beginner HIIT Workout",
                category: .fullBody,
                description: "High-intensity interval training for beginners. Build endurance and burn calories.",
                exercises: [
                    WorkoutExercise(exerciseType: .jumpingJacks, sets: 4, reps: 20, weight: nil, time: nil, restTime: 30, notes: "Warm up movement"),
                    WorkoutExercise(exerciseType: .mountainClimbers, sets: 4, reps: 15, weight: nil, time: nil, restTime: 30, notes: "Keep core engaged"),
                    WorkoutExercise(exerciseType: .burpees, sets: 4, reps: 8, weight: nil, time: nil, restTime: 45, notes: "Modify as needed"),
                    WorkoutExercise(exerciseType: .highKnees, sets: 4, reps: 20, weight: nil, time: nil, restTime: 30, notes: "Run in place, lift knees high"),
                    WorkoutExercise(exerciseType: .weightedPlank, sets: 4, reps: nil, weight: nil, time: 20, restTime: 30, notes: "Hold for 20 seconds")
                ],
                estimatedDuration: 25,
                difficulty: .beginner
            ),
            
            // Beginner Core Workouts
            PreBuiltWorkout(
                name: "Beginner Core Workout",
                category: .core,
                description: "Build a strong core foundation with these beginner-friendly abdominal exercises.",
                exercises: [
                    WorkoutExercise(exerciseType: .weightedPlank, sets: 3, reps: nil, weight: nil, time: 30, restTime: 60, notes: "Hold for 30 seconds, keep straight line"),
                    WorkoutExercise(exerciseType: .weightedCrunch, sets: 3, reps: 15, weight: nil, time: nil, restTime: 45, notes: "Lift shoulders off ground"),
                    WorkoutExercise(exerciseType: .russianTwist, sets: 3, reps: 20, weight: nil, time: nil, restTime: 45, notes: "Rotate torso side to side"),
                    WorkoutExercise(exerciseType: .hangingLegRaise, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Keep legs straight, control movement"),
                    WorkoutExercise(exerciseType: .russianTwist, sets: 3, reps: 20, weight: nil, time: nil, restTime: 45, notes: "Alternate elbow to knee")
                ],
                estimatedDuration: 20,
                difficulty: .beginner
            ),
            
            PreBuiltWorkout(
                name: "Beginner Abs & Obliques",
                category: .core,
                description: "Target your abs and obliques with these beginner core exercises for a stronger midsection.",
                exercises: [
                    WorkoutExercise(exerciseType: .weightedCrunch, sets: 3, reps: 15, weight: nil, time: nil, restTime: 45, notes: "Focus on upper abs"),
                    WorkoutExercise(exerciseType: .sideBend, sets: 3, reps: nil, weight: nil, time: 20, restTime: 60, notes: "Hold for 20 seconds each side"),
                    WorkoutExercise(exerciseType: .russianTwist, sets: 3, reps: 20, weight: nil, time: nil, restTime: 45, notes: "Engage obliques"),
                    WorkoutExercise(exerciseType: .abRollout, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Keep lower back pressed to floor"),
                    WorkoutExercise(exerciseType: .turkishGetUp, sets: 3, reps: 10, weight: nil, time: nil, restTime: 60, notes: "Alternate arm and leg")
                ],
                estimatedDuration: 25,
                difficulty: .beginner
            ),
            
            // Intermediate Upper Body Workouts
            PreBuiltWorkout(
                name: "Intermediate Chest Workout",
                category: .upperBody,
                description: "Advanced chest training with heavier weights and more complex movements. Build serious chest strength and size.",
                exercises: [
                    WorkoutExercise(exerciseType: .benchPress, sets: 4, reps: 6, weight: nil, time: nil, restTime: 120, notes: "Heavy weight, focus on explosive power and full range of motion"),
                    WorkoutExercise(exerciseType: .inclineBenchPress, sets: 4, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Upper chest focus, control the negative portion"),
                    WorkoutExercise(exerciseType: .declineBenchPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Lower chest emphasis, maintain tight core"),
                    WorkoutExercise(exerciseType: .chestFly, sets: 3, reps: 12, weight: nil, time: nil, restTime: 75, notes: "Stretch and squeeze, perfect form over weight"),
                    WorkoutExercise(exerciseType: .weightedPushUps, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Add weight plate or resistance band for extra challenge")
                ],
                estimatedDuration: 55,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "Intermediate Back Workout",
                category: .upperBody,
                description: "Comprehensive back development with compound movements and isolation exercises. Build a powerful, defined back.",
                exercises: [
                    WorkoutExercise(exerciseType: .deadlifts, sets: 4, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Heavy compound movement, perfect your form before adding weight"),
                    WorkoutExercise(exerciseType: .bentOverRows, sets: 4, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Pull to lower chest, squeeze shoulder blades together"),
                    WorkoutExercise(exerciseType: .latPulldown, sets: 4, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Wide grip, pull to upper chest, control the negative"),
                    WorkoutExercise(exerciseType: .tBarRow, sets: 3, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Neutral grip, focus on lat activation"),
                    WorkoutExercise(exerciseType: .singleArmDumbbellRow, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "One arm at a time, focus on mind-muscle connection")
                ],
                estimatedDuration: 60,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "Intermediate Shoulders Workout",
                category: .upperBody,
                description: "Advanced shoulder training for strength, size, and stability. Develop powerful, rounded deltoids.",
                exercises: [
                    WorkoutExercise(exerciseType: .overheadPress, sets: 4, reps: 6, weight: nil, time: nil, restTime: 120, notes: "Heavy weight, press straight up, keep core tight"),
                    WorkoutExercise(exerciseType: .pushPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Use leg drive for heavier weight, explosive movement"),
                    WorkoutExercise(exerciseType: .lateralRaise, sets: 4, reps: 12, weight: nil, time: nil, restTime: 75, notes: "Control the weight, raise to shoulder height, slight forward angle"),
                    WorkoutExercise(exerciseType: .rearDeltFly, sets: 4, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Bent over position, squeeze rear delts, control the movement"),
                    WorkoutExercise(exerciseType: .uprightRow, sets: 3, reps: 10, weight: nil, time: nil, restTime: 75, notes: "Narrow grip, pull to chest level, avoid shoulder impingement")
                ],
                estimatedDuration: 50,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "Intermediate Arms Workout",
                category: .upperBody,
                description: "Advanced arm training with supersets and drop sets. Build massive, defined biceps and triceps.",
                exercises: [
                    WorkoutExercise(exerciseType: .barbellCurl, sets: 4, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Heavy weight, full range of motion, squeeze at the top"),
                    WorkoutExercise(exerciseType: .closeGripBenchPress, sets: 4, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Narrow grip, focus on triceps, control the negative"),
                    WorkoutExercise(exerciseType: .concentrationCurl, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "One arm at a time, perfect form, squeeze the bicep"),
                    WorkoutExercise(exerciseType: .skullCrushers, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Keep elbows stable, lower to forehead, extend fully"),
                    WorkoutExercise(exerciseType: .cableCurl, sets: 3, reps: 15, weight: nil, time: nil, restTime: 45, notes: "Constant tension, squeeze at the peak contraction")
                ],
                estimatedDuration: 45,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "Intermediate Chest & Back Workout",
                category: .upperBody,
                description: "High-intensity upper body training combining chest and back exercises. Build serious upper body strength.",
                exercises: [
                    WorkoutExercise(exerciseType: .benchPress, sets: 4, reps: 6, weight: nil, time: nil, restTime: 120, notes: "Heavy compound movement, explosive power"),
                    WorkoutExercise(exerciseType: .bentOverRows, sets: 4, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Pull to lower chest, squeeze shoulder blades"),
                    WorkoutExercise(exerciseType: .inclineBenchPress, sets: 3, reps: 8, weight: nil, time: nil, restTime: 90, notes: "Upper chest focus, control the movement"),
                    WorkoutExercise(exerciseType: .latPulldown, sets: 3, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Wide grip, pull to upper chest"),
                    WorkoutExercise(exerciseType: .chestFly, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Stretch and squeeze, perfect form")
                ],
                estimatedDuration: 65,
                difficulty: .intermediate
            ),
            
            // Intermediate Lower Body Workouts
            PreBuiltWorkout(
                name: "Intermediate Legs Workout",
                category: .lowerBody,
                description: "Advanced leg training with heavier weights and more challenging movements. Build serious leg strength.",
                exercises: [
                    WorkoutExercise(exerciseType: .squat, sets: 4, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Heavy weight, focus on depth and form"),
                    WorkoutExercise(exerciseType: .deadlifts, sets: 4, reps: 6, weight: nil, time: nil, restTime: 120, notes: "Keep back straight, drive through heels"),
                    WorkoutExercise(exerciseType: .splitSquats, sets: 3, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Elevated rear foot, focus on front leg"),
                    WorkoutExercise(exerciseType: .legPress, sets: 4, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Heavy weight, full range of motion"),
                    WorkoutExercise(exerciseType: .standingCalfRaise, sets: 4, reps: 20, weight: nil, time: nil, restTime: 60, notes: "Slow and controlled, hold at top")
                ],
                estimatedDuration: 50,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "Intermediate Glutes & Hamstrings",
                category: .lowerBody,
                description: "Target glutes and hamstrings with advanced exercises for a stronger posterior chain.",
                exercises: [
                    WorkoutExercise(exerciseType: .hipThrust, sets: 4, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Heavy weight, squeeze glutes at top"),
                    WorkoutExercise(exerciseType: .romanianDeadlift, sets: 4, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Focus on hamstring stretch"),
                    WorkoutExercise(exerciseType: .nordicCurl, sets: 3, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Use GHR machine or partner"),
                    WorkoutExercise(exerciseType: .lunges, sets: 3, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Hold weights, long strides"),
                    WorkoutExercise(exerciseType: .singleLegDeadlift, sets: 3, reps: 15, weight: nil, time: nil, restTime: 60, notes: "One leg at a time, hold at top")
                ],
                estimatedDuration: 45,
                difficulty: .intermediate
            ),
            
            // Intermediate Full Body Workouts
            PreBuiltWorkout(
                name: "Intermediate Full Body Workout",
                category: .fullBody,
                description: "Complete full body training with compound movements and higher intensity. Build overall strength and muscle.",
                exercises: [
                    WorkoutExercise(exerciseType: .squat, sets: 4, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Heavy compound movement"),
                    WorkoutExercise(exerciseType: .benchPress, sets: 4, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Upper body strength focus"),
                    WorkoutExercise(exerciseType: .bentOverRows, sets: 4, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Pull to chest, squeeze shoulder blades"),
                    WorkoutExercise(exerciseType: .overheadPress, sets: 3, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Shoulder strength and stability"),
                    WorkoutExercise(exerciseType: .weightedPlank, sets: 3, reps: nil, weight: nil, time: 45, restTime: 60, notes: "Hold for 45 seconds")
                ],
                estimatedDuration: 60,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "Intermediate HIIT Workout",
                category: .fullBody,
                description: "High-intensity interval training with more challenging exercises. Build endurance and burn fat.",
                exercises: [
                    WorkoutExercise(exerciseType: .burpees, sets: 5, reps: 10, weight: nil, time: nil, restTime: 30, notes: "Full burpee with push-up"),
                    WorkoutExercise(exerciseType: .mountainClimbers, sets: 5, reps: 20, weight: nil, time: nil, restTime: 30, notes: "Fast pace, keep core tight"),
                    WorkoutExercise(exerciseType: .lunges, sets: 5, reps: 15, weight: nil, time: nil, restTime: 30, notes: "Explosive movement, alternate legs"),
                    WorkoutExercise(exerciseType: .highKnees, sets: 5, reps: 25, weight: nil, time: nil, restTime: 30, notes: "Maximum effort, lift knees high"),
                    WorkoutExercise(exerciseType: .weightedPlank, sets: 5, reps: nil, weight: nil, time: 30, restTime: 30, notes: "Hold for 30 seconds")
                ],
                estimatedDuration: 30,
                difficulty: .intermediate
            ),
            
            // Intermediate Core Workouts
            PreBuiltWorkout(
                name: "Intermediate Core Workout",
                category: .core,
                description: "Advanced core training with more challenging exercises. Build serious abdominal strength.",
                exercises: [
                    WorkoutExercise(exerciseType: .weightedPlank, sets: 4, reps: nil, weight: nil, time: 45, restTime: 60, notes: "Hold for 45 seconds, keep straight line"),
                    WorkoutExercise(exerciseType: .hangingLegRaise, sets: 3, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Hang from bar, lift legs to 90 degrees"),
                    WorkoutExercise(exerciseType: .russianTwist, sets: 4, reps: 25, weight: nil, time: nil, restTime: 45, notes: "Hold weight, rotate side to side"),
                    WorkoutExercise(exerciseType: .russianTwist, sets: 4, reps: 30, weight: nil, time: nil, restTime: 45, notes: "Fast pace, alternate elbow to knee"),
                    WorkoutExercise(exerciseType: .sideBend, sets: 3, reps: nil, weight: nil, time: 30, restTime: 60, notes: "Hold for 30 seconds each side")
                ],
                estimatedDuration: 30,
                difficulty: .intermediate
            ),
            
            PreBuiltWorkout(
                name: "Intermediate Abs & Obliques",
                category: .core,
                description: "Target abs and obliques with advanced exercises for a stronger, more defined core.",
                exercises: [
                    WorkoutExercise(exerciseType: .weightedCrunch, sets: 4, reps: 20, weight: nil, time: nil, restTime: 45, notes: "Hold weight, focus on upper abs"),
                    WorkoutExercise(exerciseType: .sideBend, sets: 4, reps: nil, weight: nil, time: 30, restTime: 60, notes: "Hold for 30 seconds each side"),
                    WorkoutExercise(exerciseType: .russianTwist, sets: 4, reps: 25, weight: nil, time: nil, restTime: 45, notes: "Hold weight, engage obliques"),
                    WorkoutExercise(exerciseType: .abRollout, sets: 4, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Slow and controlled, keep back flat"),
                    WorkoutExercise(exerciseType: .turkishGetUp, sets: 4, reps: 12, weight: nil, time: nil, restTime: 60, notes: "Hold position for 2 seconds")
                ],
                estimatedDuration: 35,
                difficulty: .intermediate
            ),
            
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
                    WorkoutExercise(exerciseType: .turkishGetUp, sets: 4, reps: 5, weight: nil, time: nil, restTime: 20, notes: "Slow and controlled"),
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
            ),
            
            // Advanced Upper Body Workouts
            PreBuiltWorkout(
                name: "Advanced Chest Workout",
                category: .upperBody,
                description: "Elite chest training with maximum intensity and advanced techniques. For experienced lifters only.",
                exercises: [
                    WorkoutExercise(exerciseType: .benchPress, sets: 5, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Maximum weight, explosive power"),
                    WorkoutExercise(exerciseType: .inclineBenchPress, sets: 4, reps: 6, weight: nil, time: nil, restTime: 150, notes: "Heavy weight, control the negative"),
                    WorkoutExercise(exerciseType: .declineBenchPress, sets: 4, reps: 8, weight: nil, time: nil, restTime: 150, notes: "Lower chest focus, heavy weight"),
                    WorkoutExercise(exerciseType: .chestFly, sets: 4, reps: 12, weight: nil, time: nil, restTime: 120, notes: "Stretch and squeeze, perfect form"),
                    WorkoutExercise(exerciseType: .weightedDips, sets: 4, reps: 10, weight: nil, time: nil, restTime: 120, notes: "Add weight if possible, full range of motion")
                ],
                estimatedDuration: 75,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Advanced Back Workout",
                category: .upperBody,
                description: "Elite back training with maximum intensity and advanced techniques. Build a powerful, wide back.",
                exercises: [
                    WorkoutExercise(exerciseType: .deadlifts, sets: 5, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Maximum weight, perfect form"),
                    WorkoutExercise(exerciseType: .pullUps, sets: 4, reps: 8, weight: nil, time: nil, restTime: 150, notes: "Add weight if possible, wide grip"),
                    WorkoutExercise(exerciseType: .bentOverRows, sets: 4, reps: 8, weight: nil, time: nil, restTime: 150, notes: "Heavy weight, pull to chest"),
                    WorkoutExercise(exerciseType: .tBarRow, sets: 4, reps: 10, weight: nil, time: nil, restTime: 120, notes: "Squeeze shoulder blades together"),
                    WorkoutExercise(exerciseType: .rearDeltFly, sets: 4, reps: 15, weight: nil, time: nil, restTime: 90, notes: "External rotation, rear delt focus")
                ],
                estimatedDuration: 80,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Advanced Shoulders Workout",
                category: .upperBody,
                description: "Elite shoulder training with maximum intensity and advanced techniques. Build powerful, rounded shoulders.",
                exercises: [
                    WorkoutExercise(exerciseType: .overheadPress, sets: 5, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Maximum weight, explosive power"),
                    WorkoutExercise(exerciseType: .arnoldPress, sets: 4, reps: 8, weight: nil, time: nil, restTime: 150, notes: "Full rotation, control the movement"),
                    WorkoutExercise(exerciseType: .lateralRaise, sets: 4, reps: 12, weight: nil, time: nil, restTime: 120, notes: "Heavy weight, slow and controlled"),
                    WorkoutExercise(exerciseType: .rearDeltFly, sets: 4, reps: 15, weight: nil, time: nil, restTime: 90, notes: "Squeeze rear delts, perfect form"),
                    WorkoutExercise(exerciseType: .uprightRow, sets: 4, reps: 10, weight: nil, time: nil, restTime: 120, notes: "Wide grip, pull to chest level")
                ],
                estimatedDuration: 70,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Advanced Arms Workout",
                category: .upperBody,
                description: "Elite arm training with maximum intensity and advanced techniques. Build massive, strong arms.",
                exercises: [
                    WorkoutExercise(exerciseType: .barbellCurl, sets: 5, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Heavy weight, strict form"),
                    WorkoutExercise(exerciseType: .hammerCurl, sets: 4, reps: 10, weight: nil, time: nil, restTime: 90, notes: "Neutral grip, control the negative"),
                    WorkoutExercise(exerciseType: .closeGripBenchPress, sets: 4, reps: 8, weight: nil, time: nil, restTime: 120, notes: "Heavy weight, tricep focus"),
                    WorkoutExercise(exerciseType: .skullCrushers, sets: 4, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Slow and controlled, full extension"),
                    WorkoutExercise(exerciseType: .weightedDips, sets: 4, reps: 12, weight: nil, time: nil, restTime: 90, notes: "Add weight if possible, full range")
                ],
                estimatedDuration: 65,
                difficulty: .advanced
            ),
            
            // Advanced Lower Body Workouts
            PreBuiltWorkout(
                name: "Advanced Legs Workout",
                category: .lowerBody,
                description: "Elite leg training with maximum intensity and advanced techniques. Build powerful, strong legs.",
                exercises: [
                    WorkoutExercise(exerciseType: .squat, sets: 5, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Maximum weight, perfect depth"),
                    WorkoutExercise(exerciseType: .deadlifts, sets: 5, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Heavy weight, perfect form"),
                    WorkoutExercise(exerciseType: .frontSquat, sets: 4, reps: 8, weight: nil, time: nil, restTime: 150, notes: "Front rack position, core tight"),
                    WorkoutExercise(exerciseType: .splitSquats, sets: 4, reps: 12, weight: nil, time: nil, restTime: 120, notes: "Heavy weight, focus on front leg"),
                    WorkoutExercise(exerciseType: .standingCalfRaise, sets: 5, reps: 25, weight: nil, time: nil, restTime: 60, notes: "Heavy weight, hold at top")
                ],
                estimatedDuration: 90,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Advanced Glutes & Hamstrings",
                category: .lowerBody,
                description: "Elite posterior chain training with maximum intensity and advanced techniques. Build powerful glutes and hamstrings.",
                exercises: [
                    WorkoutExercise(exerciseType: .hipThrust, sets: 5, reps: 10, weight: nil, time: nil, restTime: 120, notes: "Maximum weight, squeeze glutes"),
                    WorkoutExercise(exerciseType: .romanianDeadlift, sets: 5, reps: 8, weight: nil, time: nil, restTime: 150, notes: "Heavy weight, focus on hamstring stretch"),
                    WorkoutExercise(exerciseType: .nordicCurl, sets: 4, reps: 15, weight: nil, time: nil, restTime: 120, notes: "Use GHR machine, full range"),
                    WorkoutExercise(exerciseType: .lunges, sets: 4, reps: 15, weight: nil, time: nil, restTime: 90, notes: "Heavy weight, long strides"),
                    WorkoutExercise(exerciseType: .singleLegDeadlift, sets: 4, reps: 20, weight: nil, time: nil, restTime: 90, notes: "One leg at a time, hold at top")
                ],
                estimatedDuration: 75,
                difficulty: .advanced
            ),
            
            // Advanced Full Body Workouts
            PreBuiltWorkout(
                name: "Advanced Full Body Workout",
                category: .fullBody,
                description: "Elite full body training with maximum intensity and advanced techniques. Build overall strength and power.",
                exercises: [
                    WorkoutExercise(exerciseType: .squat, sets: 5, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Maximum weight, perfect form"),
                    WorkoutExercise(exerciseType: .benchPress, sets: 5, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Heavy weight, explosive power"),
                    WorkoutExercise(exerciseType: .bentOverRows, sets: 5, reps: 5, weight: nil, time: nil, restTime: 180, notes: "Heavy weight, pull to chest"),
                    WorkoutExercise(exerciseType: .overheadPress, sets: 4, reps: 8, weight: nil, time: nil, restTime: 150, notes: "Shoulder strength and stability"),
                    WorkoutExercise(exerciseType: .weightedPlank, sets: 4, reps: nil, weight: nil, time: 60, restTime: 90, notes: "Hold for 60 seconds")
                ],
                estimatedDuration: 90,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Advanced HIIT Workout",
                category: .fullBody,
                description: "Elite high-intensity interval training with maximum intensity and advanced exercises. Build elite endurance.",
                exercises: [
                    WorkoutExercise(exerciseType: .burpees, sets: 6, reps: 15, weight: nil, time: nil, restTime: 20, notes: "Maximum effort, full burpee"),
                    WorkoutExercise(exerciseType: .mountainClimbers, sets: 6, reps: 30, weight: nil, time: nil, restTime: 20, notes: "Fast pace, keep core tight"),
                    WorkoutExercise(exerciseType: .lunges, sets: 6, reps: 20, weight: nil, time: nil, restTime: 20, notes: "Explosive movement, alternate legs"),
                    WorkoutExercise(exerciseType: .highKnees, sets: 6, reps: 35, weight: nil, time: nil, restTime: 20, notes: "Maximum effort, lift knees high"),
                    WorkoutExercise(exerciseType: .weightedPlank, sets: 6, reps: nil, weight: nil, time: 45, restTime: 20, notes: "Hold for 45 seconds")
                ],
                estimatedDuration: 35,
                difficulty: .advanced
            ),
            
            // Advanced Core Workouts
            PreBuiltWorkout(
                name: "Advanced Core Workout",
                category: .core,
                description: "Elite core training with maximum intensity and advanced techniques. Build elite abdominal strength.",
                exercises: [
                    WorkoutExercise(exerciseType: .weightedPlank, sets: 5, reps: nil, weight: nil, time: 60, restTime: 60, notes: "Hold for 60 seconds, keep straight line"),
                    WorkoutExercise(exerciseType: .hangingLegRaise, sets: 4, reps: 15, weight: nil, time: nil, restTime: 120, notes: "Hang from bar, lift legs to 90 degrees"),
                    WorkoutExercise(exerciseType: .russianTwist, sets: 5, reps: 30, weight: nil, time: nil, restTime: 45, notes: "Hold heavy weight, rotate side to side"),
                    WorkoutExercise(exerciseType: .russianTwist, sets: 5, reps: 40, weight: nil, time: nil, restTime: 45, notes: "Fast pace, alternate elbow to knee"),
                    WorkoutExercise(exerciseType: .sideBend, sets: 4, reps: nil, weight: nil, time: 45, restTime: 60, notes: "Hold for 45 seconds each side")
                ],
                estimatedDuration: 40,
                difficulty: .advanced
            ),
            
            PreBuiltWorkout(
                name: "Advanced Abs & Obliques",
                category: .core,
                description: "Elite abs and obliques training with maximum intensity and advanced techniques. Build elite core strength.",
                exercises: [
                    WorkoutExercise(exerciseType: .weightedCrunch, sets: 5, reps: 25, weight: nil, time: nil, restTime: 45, notes: "Hold heavy weight, focus on upper abs"),
                    WorkoutExercise(exerciseType: .sideBend, sets: 5, reps: nil, weight: nil, time: 45, restTime: 60, notes: "Hold for 45 seconds each side"),
                    WorkoutExercise(exerciseType: .russianTwist, sets: 5, reps: 30, weight: nil, time: nil, restTime: 45, notes: "Hold heavy weight, engage obliques"),
                    WorkoutExercise(exerciseType: .abRollout, sets: 5, reps: 20, weight: nil, time: nil, restTime: 60, notes: "Slow and controlled, keep back flat"),
                    WorkoutExercise(exerciseType: .turkishGetUp, sets: 5, reps: 15, weight: nil, time: nil, restTime: 60, notes: "Hold position for 3 seconds")
                ],
                estimatedDuration: 45,
                difficulty: .advanced
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
    static let bodyweightBurpees = ExerciseType.manMaker
    static let bodyweightMountainClimbers = ExerciseType.turkishGetUp
    static let bodyweightJumpingJacks = ExerciseType.kettlebellSwing
    static let bodyweightHighKnees = ExerciseType.kettlebellSwing
    static let sprint = ExerciseType.kettlebellSwing
    static let walk = ExerciseType.kettlebellSwing
    static let hammerCurl = ExerciseType.dumbbellCurl
    static let bodyweightBoxJumps = ExerciseType.stepUps
    static let handstandPushUps = ExerciseType.overheadPress
    static let muscleUps = ExerciseType.pullUps
    static let planche = ExerciseType.weightedPlank
    static let frontLever = ExerciseType.hangingLegRaise
    static let humanFlag = ExerciseType.sideBend
    static let wallBall = ExerciseType.kettlebellSwing
    static let kettlebellGobletSquat = ExerciseType.squat
    static let dips = ExerciseType.tricepsKickback
}
