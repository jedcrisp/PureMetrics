import Foundation

// MARK: - Exercise Categories

enum ExerciseCategory: String, CaseIterable, Codable {
    case upperBody = "Upper Body"
    case lowerBody = "Lower Body"
    case coreAbs = "Core / Abs"
    case fullBody = "Full Body & Power"
    case machineBased = "Machine-Based"
    
    var icon: String {
        switch self {
        case .upperBody: return "figure.arms.open"
        case .lowerBody: return "figure.strengthtraining.traditional"
        case .coreAbs: return "figure.core.training"
        case .fullBody: return "figure.strengthtraining.traditional"
        case .machineBased: return "dumbbell.fill"
        }
    }
    
    var color: String {
        switch self {
        case .upperBody: return "blue"
        case .lowerBody: return "green"
        case .coreAbs: return "orange"
        case .fullBody: return "purple"
        case .machineBased: return "red"
        }
    }
}

// MARK: - Exercise Types

enum ExerciseType: String, CaseIterable, Codable {
    // Upper Body - Chest
    case benchPress = "Bench Press"
    case inclineBenchPress = "Incline Bench Press"
    case declineBenchPress = "Decline Bench Press"
    case chestFly = "Chest Fly"
    case weightedPushUps = "Weighted Push-Ups"
    case squeezePress = "Squeeze Press"
    
    // Upper Body - Back
    case deadlifts = "Deadlifts"
    case bentOverRows = "Bent-Over Rows"
    case pendlayRow = "Pendlay Row"
    case sealRow = "Seal Row"
    case singleArmDumbbellRow = "Single-Arm Dumbbell Row"
    case invertedRow = "Inverted Row"
    case latPulldown = "Lat Pulldown"
    case pullUps = "Pull-ups / Chin-ups"
    case tBarRow = "T-Bar Row"
    case meadowsRow = "Meadows Row"
    
    // Upper Body - Shoulders
    case overheadPress = "Overhead Press"
    case pushPress = "Push Press"
    case arnoldPress = "Arnold Press"
    case lateralRaise = "Lateral Raise"
    case frontRaise = "Front Raise"
    case rearDeltFly = "Rear Delt Fly"
    case uprightRow = "Upright Row"
    case zPress = "Z-Press"
    
    // Upper Body - Biceps
    case barbellCurl = "Barbell Curl"
    case dumbbellCurl = "Dumbbell Curl"
    case concentrationCurl = "Concentration Curl"
    case preacherCurl = "Preacher Curl"
    case cableCurl = "Cable Curl"
    case spiderCurl = "Spider Curl"
    case zottmanCurl = "Zottman Curl"
    
    // Upper Body - Triceps
    case closeGripBenchPress = "Close-Grip Bench Press"
    case skullCrushers = "Skull Crushers"
    case overheadTricepsExtension = "Overhead Triceps Extension"
    case tricepsKickback = "Triceps Kickback"
    case cablePushdowns = "Cable Pushdowns"
    case tatePress = "Tate Press"
    case weightedDips = "Weighted Dips"
    
    // Lower Body - Quadriceps
    case squat = "Squat"
    case splitSquats = "Split Squats"
    case stepUps = "Step-Ups"
    case legPress = "Leg Press"
    case sissySquat = "Sissy Squat"
    case lunges = "Lunges"
    
    // Lower Body - Hamstrings & Glutes
    case romanianDeadlift = "Romanian Deadlift"
    case goodMorning = "Good Morning"
    case hipThrust = "Hip Thrust"
    case gluteBridge = "Glute Bridge"
    case nordicCurl = "Nordic Curl"
    case kettlebellSwing = "Kettlebell Swing"
    case cablePullThrough = "Cable Pull-Through"
    case singleLegDeadlift = "Single-Leg Deadlift"
    
    // Lower Body - Calves
    case standingCalfRaise = "Standing Calf Raise"
    case seatedCalfRaise = "Seated Calf Raise"
    case donkeyCalfRaise = "Donkey Calf Raise"
    
    // Core / Abs
    case weightedSitUps = "Weighted Sit-Ups"
    case weightedCrunch = "Weighted Crunch"
    case weightedPlank = "Weighted Plank"
    case abRollout = "Ab Rollout"
    case hangingLegRaise = "Hanging Leg Raise"
    case cableCrunch = "Cable Crunch"
    case russianTwist = "Russian Twist"
    case turkishGetUp = "Turkish Get-Up"
    case sideBend = "Side Bend"
    
    // Full Body & Power
    case cleanAndPress = "Clean & Press"
    case powerClean = "Power Clean"
    case snatch = "Snatch"
    case jerk = "Jerk"
    case thruster = "Thruster"
    case manMaker = "Man-Maker"
    case farmersCarry = "Farmer's Carry"
    case suitcaseCarry = "Suitcase Carry"
    case overheadCarry = "Overhead Carry"
    case zercherCarry = "Zercher Carry"
    case sandbagLifts = "Sandbag Lifts"
    
    // Machine-Based
    case chestPress = "Chest Press"
    case pecDeck = "Pec Deck"
    case latPulldownMachine = "Lat Pulldown Machine"
    case rowMachine = "Row Machine"
    case shoulderPressMachine = "Shoulder Press Machine"
    case bicepsCurlMachine = "Biceps Curl Machine"
    case tricepsExtensionMachine = "Triceps Extension Machine"
    case legExtension = "Leg Extension"
    case legCurl = "Leg Curl"
    case hackSquatMachine = "Hack Squat Machine"
    case smithMachine = "Smith Machine"
    case cableFunctionalTrainer = "Cable Functional Trainer"
    
    var category: ExerciseCategory {
        switch self {
        // Upper Body
        case .benchPress, .inclineBenchPress, .declineBenchPress, .chestFly, .weightedPushUps, .squeezePress,
             .deadlifts, .bentOverRows, .pendlayRow, .sealRow, .singleArmDumbbellRow, .invertedRow, .latPulldown, .pullUps, .tBarRow, .meadowsRow,
             .overheadPress, .pushPress, .arnoldPress, .lateralRaise, .frontRaise, .rearDeltFly, .uprightRow, .zPress,
             .barbellCurl, .dumbbellCurl, .concentrationCurl, .preacherCurl, .cableCurl, .spiderCurl, .zottmanCurl,
             .closeGripBenchPress, .skullCrushers, .overheadTricepsExtension, .tricepsKickback, .cablePushdowns, .tatePress, .weightedDips:
            return .upperBody
            
        // Lower Body
        case .squat, .splitSquats, .stepUps, .legPress, .sissySquat, .lunges,
             .romanianDeadlift, .goodMorning, .hipThrust, .gluteBridge, .nordicCurl, .kettlebellSwing, .cablePullThrough, .singleLegDeadlift,
             .standingCalfRaise, .seatedCalfRaise, .donkeyCalfRaise:
            return .lowerBody
            
        // Core / Abs
        case .weightedSitUps, .weightedCrunch, .weightedPlank, .abRollout, .hangingLegRaise, .cableCrunch, .russianTwist, .turkishGetUp, .sideBend:
            return .coreAbs
            
        // Full Body & Power
        case .cleanAndPress, .powerClean, .snatch, .jerk, .thruster, .manMaker, .farmersCarry, .suitcaseCarry, .overheadCarry, .zercherCarry, .sandbagLifts:
            return .fullBody
            
        // Machine-Based
        case .chestPress, .pecDeck, .latPulldownMachine, .rowMachine, .shoulderPressMachine, .bicepsCurlMachine, .tricepsExtensionMachine, .legExtension, .legCurl, .hackSquatMachine, .smithMachine, .cableFunctionalTrainer:
            return .machineBased
        }
    }
    
    var icon: String {
        switch self {
        // Upper Body - Chest
        case .benchPress, .inclineBenchPress, .declineBenchPress: return "dumbbell.fill"
        case .chestFly, .squeezePress: return "figure.arms.open"
        case .weightedPushUps: return "figure.push"
        
        // Upper Body - Back
        case .deadlifts, .bentOverRows, .pendlayRow, .sealRow, .singleArmDumbbellRow, .tBarRow, .meadowsRow: return "figure.strengthtraining.traditional"
        case .invertedRow, .latPulldown, .pullUps: return "figure.pullups"
        
        // Upper Body - Shoulders
        case .overheadPress, .pushPress, .arnoldPress, .zPress: return "figure.strengthtraining.traditional"
        case .lateralRaise, .frontRaise, .rearDeltFly, .uprightRow: return "figure.arms.open"
        
        // Upper Body - Biceps
        case .barbellCurl, .dumbbellCurl, .concentrationCurl, .preacherCurl, .cableCurl, .spiderCurl, .zottmanCurl: return "figure.arms.open"
        
        // Upper Body - Triceps
        case .closeGripBenchPress, .skullCrushers, .overheadTricepsExtension, .tricepsKickback, .cablePushdowns, .tatePress, .weightedDips: return "figure.arms.open"
        
        // Lower Body - Quadriceps
        case .squat, .splitSquats, .stepUps, .legPress, .sissySquat, .lunges: return "figure.strengthtraining.traditional"
        
        // Lower Body - Hamstrings & Glutes
        case .romanianDeadlift, .goodMorning, .hipThrust, .gluteBridge, .nordicCurl, .kettlebellSwing, .cablePullThrough, .singleLegDeadlift: return "figure.strengthtraining.traditional"
        
        // Lower Body - Calves
        case .standingCalfRaise, .seatedCalfRaise, .donkeyCalfRaise: return "figure.strengthtraining.traditional"
        
        // Core / Abs
        case .weightedSitUps, .weightedCrunch, .weightedPlank, .abRollout, .hangingLegRaise, .cableCrunch, .russianTwist, .turkishGetUp, .sideBend: return "figure.core.training"
        
        // Full Body & Power
        case .cleanAndPress, .powerClean, .snatch, .jerk, .thruster, .manMaker: return "figure.strengthtraining.traditional"
        case .farmersCarry, .suitcaseCarry, .overheadCarry, .zercherCarry, .sandbagLifts: return "figure.strengthtraining.traditional"
        
        // Machine-Based
        case .chestPress, .pecDeck, .latPulldownMachine, .rowMachine, .shoulderPressMachine, .bicepsCurlMachine, .tricepsExtensionMachine, .legExtension, .legCurl, .hackSquatMachine, .smithMachine, .cableFunctionalTrainer: return "dumbbell.fill"
        }
    }
    
    var color: String {
        return category.color
    }
    
    var unit: String {
        // All exercises support both reps and weight
        return "lbs"
    }
    
    var supportsWeight: Bool {
        return true // All exercises support weight
    }
    
    var supportsTime: Bool {
        // Most exercises can be timed (holds, isometric exercises, etc.)
        switch self {
        case .weightedPlank, .turkishGetUp, .farmersCarry, .suitcaseCarry, .overheadCarry, .zercherCarry:
            return true
        default:
            return false
        }
    }
    
    var supportsReps: Bool {
        return true // All exercises support reps
    }
}

// MARK: - Exercise Set Model

struct ExerciseSet: Codable, Identifiable {
    let id: UUID
    let reps: Int?
    let weight: Double?
    let time: TimeInterval? // in seconds
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id, reps, weight, time, timestamp
    }
    
    init(id: UUID = UUID(), reps: Int? = nil, weight: Double? = nil, time: TimeInterval? = nil, timestamp: Date? = nil) {
        self.id = id
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
    var id: UUID
    let exerciseType: ExerciseType
    var sets: [ExerciseSet]
    let startTime: Date
    var endTime: Date?
    var isCompleted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, exerciseType, sets, startTime, endTime, isCompleted
    }
    
    init(exerciseType: ExerciseType, startTime: Date? = nil) {
        self.id = UUID()
        self.exerciseType = exerciseType
        self.sets = []
        self.startTime = startTime ?? Date()
    }
    
    mutating func addSet(_ set: ExerciseSet) {
        print("=== ExerciseSession addSet ===")
        print("Adding set: \(set)")
        print("Sets before: \(sets.count)")
        sets.append(set)
        print("Sets after: \(sets.count)")
        print("=== End ExerciseSession addSet ===")
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
    var id: UUID
    var exerciseSessions: [ExerciseSession]
    let startTime: Date
    var endTime: Date?
    var isActive: Bool = true
    var isPaused: Bool = false
    var isCompleted: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, exerciseSessions, startTime, endTime, isActive, isPaused, isCompleted
    }
    
    init(startTime: Date? = nil) {
        self.id = UUID()
        self.exerciseSessions = []
        self.startTime = startTime ?? Date()
        self.isActive = false  // New sessions start as inactive
    }
    
    mutating func addExerciseSession(_ session: ExerciseSession) {
        exerciseSessions.append(session)
    }
    
    mutating func start() {
        isActive = true
        isPaused = false
    }
    
    mutating func removeExerciseSession(at index: Int) {
        guard index >= 0 && index < exerciseSessions.count else { return }
        exerciseSessions.remove(at: index)
    }
    
    mutating func pause() {
        isPaused = true
        isActive = false
    }
    
    mutating func resume() {
        isPaused = false
        isActive = true
    }
    
    mutating func complete() {
        endTime = Date()
        isActive = false
        isPaused = false
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