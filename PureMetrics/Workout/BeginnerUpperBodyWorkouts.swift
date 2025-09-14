import Foundation

// MARK: - Beginner Upper Body Workout Templates

struct BeginnerUpperBodyWorkouts {
    
    // MARK: - Chest Focused Workout
    static let chestWorkout = CustomWorkout(
        name: "Beginner Chest Workout",
        description: "Perfect for building chest strength and muscle. Focus on proper form and controlled movements.",
        exercises: [
            WorkoutExercise(
                exerciseType: .benchPress,
                sets: 3,
                reps: 8,
                restTime: 90,
                notes: "Start with lighter weight, focus on full range of motion"
            ),
            WorkoutExercise(
                exerciseType: .inclineBenchPress,
                sets: 3,
                reps: 8,
                restTime: 90,
                notes: "Targets upper chest, keep core tight"
            ),
            WorkoutExercise(
                exerciseType: .chestFly,
                sets: 3,
                reps: 12,
                restTime: 60,
                notes: "Control the weight, feel the stretch in your chest"
            ),
            WorkoutExercise(
                exerciseType: .weightedPushUps,
                sets: 3,
                reps: 10,
                restTime: 60,
                notes: "Use bodyweight if no weight available, keep straight line"
            ),
            WorkoutExercise(
                exerciseType: .squeezePress,
                sets: 2,
                reps: 15,
                restTime: 45,
                notes: "Light weight, focus on squeezing chest muscles"
            )
        ],
        createdDate: Date(),
        isFavorite: false
    )
    
    // MARK: - Back Focused Workout
    static let backWorkout = CustomWorkout(
        name: "Beginner Back Workout",
        description: "Build a strong, defined back with these essential exercises. Focus on pulling movements.",
        exercises: [
            WorkoutExercise(
                exerciseType: .latPulldown,
                sets: 3,
                reps: 10,
                restTime: 90,
                notes: "Pull to chest, squeeze shoulder blades together"
            ),
            WorkoutExercise(
                exerciseType: .bentOverRows,
                sets: 3,
                reps: 8,
                restTime: 90,
                notes: "Keep back straight, pull elbows back"
            ),
            WorkoutExercise(
                exerciseType: .deadlifts,
                sets: 3,
                reps: 6,
                restTime: 120,
                notes: "Start light, focus on hip hinge movement"
            ),
            WorkoutExercise(
                exerciseType: .singleArmDumbbellRow,
                sets: 3,
                reps: 10,
                restTime: 60,
                notes: "One arm at a time, support with other hand"
            ),
            WorkoutExercise(
                exerciseType: .invertedRow,
                sets: 2,
                reps: 8,
                restTime: 60,
                notes: "Use bodyweight, adjust angle for difficulty"
            )
        ],
        createdDate: Date(),
        isFavorite: false
    )
    
    // MARK: - Shoulders Focused Workout
    static let shouldersWorkout = CustomWorkout(
        name: "Beginner Shoulders Workout",
        description: "Develop strong, rounded shoulders with these targeted exercises. Perfect for shoulder stability.",
        exercises: [
            WorkoutExercise(
                exerciseType: .overheadPress,
                sets: 3,
                reps: 8,
                restTime: 90,
                notes: "Press straight up, keep core tight"
            ),
            WorkoutExercise(
                exerciseType: .lateralRaise,
                sets: 3,
                reps: 12,
                restTime: 60,
                notes: "Light weight, raise to shoulder height"
            ),
            WorkoutExercise(
                exerciseType: .frontRaise,
                sets: 3,
                reps: 10,
                restTime: 60,
                notes: "Alternate arms, control the movement"
            ),
            WorkoutExercise(
                exerciseType: .rearDeltFly,
                sets: 3,
                reps: 12,
                restTime: 60,
                notes: "Bent over position, squeeze shoulder blades"
            ),
            WorkoutExercise(
                exerciseType: .uprightRow,
                sets: 2,
                reps: 10,
                restTime: 45,
                notes: "Keep elbows high, pull to chest level"
            )
        ],
        createdDate: Date(),
        isFavorite: false
    )
    
    // MARK: - Arms Focused Workout
    static let armsWorkout = CustomWorkout(
        name: "Beginner Arms Workout",
        description: "Build strong biceps and triceps with these essential arm exercises. Focus on controlled movements.",
        exercises: [
            WorkoutExercise(
                exerciseType: .barbellCurl,
                sets: 3,
                reps: 10,
                restTime: 60,
                notes: "Keep elbows at sides, full range of motion"
            ),
            WorkoutExercise(
                exerciseType: .dumbbellCurl,
                sets: 3,
                reps: 12,
                restTime: 60,
                notes: "Alternate arms, squeeze at the top"
            ),
            WorkoutExercise(
                exerciseType: .closeGripBenchPress,
                sets: 3,
                reps: 8,
                restTime: 90,
                notes: "Narrow grip, focus on triceps"
            ),
            WorkoutExercise(
                exerciseType: .skullCrushers,
                sets: 3,
                reps: 10,
                restTime: 60,
                notes: "Keep elbows stable, lower to forehead"
            ),
            WorkoutExercise(
                exerciseType: .tricepsKickback,
                sets: 2,
                reps: 12,
                restTime: 45,
                notes: "Bent over position, extend arm back"
            )
        ],
        createdDate: Date(),
        isFavorite: false
    )
    
    // MARK: - Chest & Back Combined Workout
    static let chestBackWorkout = CustomWorkout(
        name: "Beginner Chest & Back Workout",
        description: "Complete upper body workout targeting both chest and back muscles. Great for balanced development.",
        exercises: [
            WorkoutExercise(
                exerciseType: .benchPress,
                sets: 3,
                reps: 8,
                restTime: 90,
                notes: "Start with chest, focus on form"
            ),
            WorkoutExercise(
                exerciseType: .latPulldown,
                sets: 3,
                reps: 10,
                restTime: 90,
                notes: "Pull to chest, engage lats"
            ),
            WorkoutExercise(
                exerciseType: .inclineBenchPress,
                sets: 3,
                reps: 8,
                restTime: 90,
                notes: "Upper chest focus, controlled movement"
            ),
            WorkoutExercise(
                exerciseType: .bentOverRows,
                sets: 3,
                reps: 8,
                restTime: 90,
                notes: "Pull elbows back, squeeze shoulder blades"
            ),
            WorkoutExercise(
                exerciseType: .chestFly,
                sets: 2,
                reps: 12,
                restTime: 60,
                notes: "Stretch and squeeze, feel the burn"
            )
        ],
        createdDate: Date(),
        isFavorite: false
    )
    
    // MARK: - Intermediate Chest Focused Workout
    static let intermediateChestWorkout = CustomWorkout(
        name: "Intermediate Chest Workout",
        description: "Advanced chest training with heavier weights and more complex movements. Build serious chest strength and size.",
        exercises: [
            WorkoutExercise(
                exerciseType: .benchPress,
                sets: 4,
                reps: 6,
                restTime: 120,
                notes: "Heavy weight, focus on explosive power and full range of motion"
            ),
            WorkoutExercise(
                exerciseType: .inclineBenchPress,
                sets: 4,
                reps: 8,
                restTime: 120,
                notes: "Upper chest focus, control the negative portion"
            ),
            WorkoutExercise(
                exerciseType: .declineBenchPress,
                sets: 3,
                reps: 8,
                restTime: 90,
                notes: "Lower chest emphasis, maintain tight core"
            ),
            WorkoutExercise(
                exerciseType: .chestFly,
                sets: 3,
                reps: 12,
                restTime: 75,
                notes: "Stretch and squeeze, perfect form over weight"
            ),
            WorkoutExercise(
                exerciseType: .weightedPushUps,
                sets: 3,
                reps: 12,
                restTime: 60,
                notes: "Add weight plate or resistance band for extra challenge"
            )
        ],
        createdDate: Date(),
        isFavorite: false
    )
    
    // MARK: - Intermediate Back Focused Workout
    static let intermediateBackWorkout = CustomWorkout(
        name: "Intermediate Back Workout",
        description: "Comprehensive back development with compound movements and isolation exercises. Build a powerful, defined back.",
        exercises: [
            WorkoutExercise(
                exerciseType: .deadlifts,
                sets: 4,
                reps: 5,
                restTime: 180,
                notes: "Heavy compound movement, perfect your form before adding weight"
            ),
            WorkoutExercise(
                exerciseType: .bentOverRows,
                sets: 4,
                reps: 8,
                restTime: 120,
                notes: "Pull to lower chest, squeeze shoulder blades together"
            ),
            WorkoutExercise(
                exerciseType: .latPulldown,
                sets: 4,
                reps: 10,
                restTime: 90,
                notes: "Wide grip, pull to upper chest, control the negative"
            ),
            WorkoutExercise(
                exerciseType: .tBarRow,
                sets: 3,
                reps: 10,
                restTime: 90,
                notes: "Neutral grip, focus on lat activation"
            ),
            WorkoutExercise(
                exerciseType: .singleArmDumbbellRow,
                sets: 3,
                reps: 12,
                restTime: 60,
                notes: "One arm at a time, focus on mind-muscle connection"
            )
        ],
        createdDate: Date(),
        isFavorite: false
    )
    
    // MARK: - Intermediate Shoulders Focused Workout
    static let intermediateShouldersWorkout = CustomWorkout(
        name: "Intermediate Shoulders Workout",
        description: "Advanced shoulder training for strength, size, and stability. Develop powerful, rounded deltoids.",
        exercises: [
            WorkoutExercise(
                exerciseType: .overheadPress,
                sets: 4,
                reps: 6,
                restTime: 120,
                notes: "Heavy weight, press straight up, keep core tight"
            ),
            WorkoutExercise(
                exerciseType: .pushPress,
                sets: 3,
                reps: 8,
                restTime: 120,
                notes: "Use leg drive for heavier weight, explosive movement"
            ),
            WorkoutExercise(
                exerciseType: .lateralRaise,
                sets: 4,
                reps: 12,
                restTime: 75,
                notes: "Control the weight, raise to shoulder height, slight forward angle"
            ),
            WorkoutExercise(
                exerciseType: .rearDeltFly,
                sets: 4,
                reps: 15,
                restTime: 60,
                notes: "Bent over position, squeeze rear delts, control the movement"
            ),
            WorkoutExercise(
                exerciseType: .uprightRow,
                sets: 3,
                reps: 10,
                restTime: 75,
                notes: "Narrow grip, pull to chest level, avoid shoulder impingement"
            )
        ],
        createdDate: Date(),
        isFavorite: false
    )
    
    // MARK: - Intermediate Arms Focused Workout
    static let intermediateArmsWorkout = CustomWorkout(
        name: "Intermediate Arms Workout",
        description: "Advanced arm training with supersets and drop sets. Build massive, defined biceps and triceps.",
        exercises: [
            WorkoutExercise(
                exerciseType: .barbellCurl,
                sets: 4,
                reps: 8,
                restTime: 90,
                notes: "Heavy weight, full range of motion, squeeze at the top"
            ),
            WorkoutExercise(
                exerciseType: .closeGripBenchPress,
                sets: 4,
                reps: 8,
                restTime: 90,
                notes: "Narrow grip, focus on triceps, control the negative"
            ),
            WorkoutExercise(
                exerciseType: .concentrationCurl,
                sets: 3,
                reps: 12,
                restTime: 60,
                notes: "One arm at a time, perfect form, squeeze the bicep"
            ),
            WorkoutExercise(
                exerciseType: .skullCrushers,
                sets: 3,
                reps: 12,
                restTime: 60,
                notes: "Keep elbows stable, lower to forehead, extend fully"
            ),
            WorkoutExercise(
                exerciseType: .cableCurl,
                sets: 3,
                reps: 15,
                restTime: 45,
                notes: "Constant tension, squeeze at the peak contraction"
            )
        ],
        createdDate: Date(),
        isFavorite: false
    )
    
    // MARK: - Intermediate Chest & Back Combined Workout
    static let intermediateChestBackWorkout = CustomWorkout(
        name: "Intermediate Chest & Back Workout",
        description: "High-intensity upper body training combining chest and back exercises. Build serious upper body strength.",
        exercises: [
            WorkoutExercise(
                exerciseType: .benchPress,
                sets: 4,
                reps: 6,
                restTime: 120,
                notes: "Heavy compound movement, explosive power"
            ),
            WorkoutExercise(
                exerciseType: .bentOverRows,
                sets: 4,
                reps: 8,
                restTime: 120,
                notes: "Pull to lower chest, squeeze shoulder blades"
            ),
            WorkoutExercise(
                exerciseType: .inclineBenchPress,
                sets: 3,
                reps: 8,
                restTime: 90,
                notes: "Upper chest focus, control the movement"
            ),
            WorkoutExercise(
                exerciseType: .latPulldown,
                sets: 3,
                reps: 10,
                restTime: 90,
                notes: "Wide grip, pull to upper chest"
            ),
            WorkoutExercise(
                exerciseType: .chestFly,
                sets: 3,
                reps: 12,
                restTime: 60,
                notes: "Stretch and squeeze, perfect form"
            )
        ],
        createdDate: Date(),
        isFavorite: false
    )
    
    // MARK: - All Beginner Workouts
    static let allBeginnerWorkouts: [CustomWorkout] = [
        chestWorkout,
        backWorkout,
        shouldersWorkout,
        armsWorkout,
        chestBackWorkout
    ]
    
    // MARK: - All Intermediate Workouts
    static let allIntermediateWorkouts: [CustomWorkout] = [
        intermediateChestWorkout,
        intermediateBackWorkout,
        intermediateShouldersWorkout,
        intermediateArmsWorkout,
        intermediateChestBackWorkout
    ]
    
    // MARK: - All Workouts Combined
    static let allWorkouts: [CustomWorkout] = allBeginnerWorkouts + allIntermediateWorkouts
    
    // MARK: - Workout Categories
    static let workoutCategories: [String: [CustomWorkout]] = [
        "Chest": [chestWorkout, intermediateChestWorkout],
        "Back": [backWorkout, intermediateBackWorkout],
        "Shoulders": [shouldersWorkout, intermediateShouldersWorkout],
        "Arms": [armsWorkout, intermediateArmsWorkout],
        "Combined": [chestBackWorkout, intermediateChestBackWorkout]
    ]
}

// MARK: - Workout Tips and Guidelines

extension BeginnerUpperBodyWorkouts {
    
    static let workoutTips = [
        "💡 Start with lighter weights to focus on proper form",
        "🔥 Aim for 2-3 workouts per week with rest days between",
        "⏱️ Rest 60-90 seconds between sets for muscle recovery",
        "📈 Gradually increase weight as you get stronger",
        "🔄 Warm up with 5-10 minutes of light cardio before starting",
        "💧 Stay hydrated throughout your workout",
        "🎯 Focus on controlled movements rather than heavy weights",
        "📝 Track your progress to see improvements over time"
    ]
    
    static let beginnerGuidelines = [
        "Start with 1-2 sets if you're completely new to lifting",
        "Use a weight where you can complete all reps with good form",
        "If you can't complete all reps, reduce the weight",
        "If the last few reps are too easy, increase the weight",
        "Always warm up before starting your workout",
        "Cool down with light stretching after your workout",
        "Listen to your body and rest when needed",
        "Consider working with a trainer for proper form guidance"
    ]
    
    static let intermediateGuidelines = [
        "Focus on progressive overload - gradually increase weight or reps",
        "Use proper form with heavier weights - technique is crucial",
        "Implement periodization - vary intensity and volume weekly",
        "Track your workouts to monitor progress and plateaus",
        "Include deload weeks every 4-6 weeks to prevent overtraining",
        "Warm up thoroughly with lighter sets before heavy work",
        "Consider supersets and drop sets for added intensity",
        "Listen to your body - intermediate training requires more recovery"
    ]
}
