import Foundation

/// Which body area this exercise targets
enum BodyArea: String, CaseIterable, Identifiable {
    case knee = "Knee"
    case shoulder = "Shoulder"
    case elbow = "Elbow"
    case ankle = "Ankle"
    case hip = "Hip"
    var id: String { rawValue }
}

/// A single step in an exercise (shown as a card with image + instruction)
struct ExerciseStep: Identifiable, Hashable {
    let id: UUID
    let stepNumber: Int
    let title: String          // e.g. "Start", "Mid", "End"
    let instruction: String    // Short coaching cue
    let imageName: String?     // Asset name (nil = no image yet)
    
    init(id: UUID = UUID(), stepNumber: Int, title: String, instruction: String, imageName: String? = nil) {
        self.id = id
        self.stepNumber = stepNumber
        self.title = title
        self.instruction = instruction
        self.imageName = imageName
    }
}

struct Exercise: Identifiable, Hashable {
    let id: UUID
    let name: String
    let bodyArea: BodyArea
    let visualDescription: String
    let targetAngleRange: ClosedRange<Double>
    let holdSeconds: Int
    let reps: Int
    let steps: [ExerciseStep]         // Step-by-step guide with images
    let caregiverTip: String?         // Tip for the family member / helper
    let thumbnailName: String?        // Thumbnail image for exercise list
    
    init(
        id: UUID = UUID(),
        name: String,
        bodyArea: BodyArea = .knee,
        visualDescription: String,
        targetAngleRange: ClosedRange<Double>,
        holdSeconds: Int,
        reps: Int,
        steps: [ExerciseStep] = [],
        caregiverTip: String? = nil,
        thumbnailName: String? = nil
    ) {
        self.id = id
        self.name = name
        self.bodyArea = bodyArea
        self.visualDescription = visualDescription
        self.targetAngleRange = targetAngleRange
        self.holdSeconds = holdSeconds
        self.reps = reps
        self.steps = steps
        self.caregiverTip = caregiverTip
        self.thumbnailName = thumbnailName
    }
}

// MARK: - Knee Exercises

extension Exercise {
    static let kneeFlexionExercises: [Exercise] = [
        Exercise(
            name: "Heel Slides",
            bodyArea: .knee,
            visualDescription: "Lie on your back. Slowly slide your heel toward your glutes, bending the knee. Hold, then straighten.",
            targetAngleRange: 80...95,
            holdSeconds: 3,
            reps: 3,
            steps: [
                ExerciseStep(stepNumber: 1, title: "Start", instruction: "Lie flat on your back with legs straight.", imageName: "heel_slide_1"),
                ExerciseStep(stepNumber: 2, title: "Slide", instruction: "Slowly bend your knee, sliding your heel toward your glutes.", imageName: "heel_slide_2"),
                ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold the bent position for 3 seconds, then slowly return.", imageName: "heel_slide_3"),
            ],
            caregiverTip: "Stand beside the patient. Gently guide the heel if they struggle to initiate the slide. Do not force the knee past the pain point.",
            thumbnailName: "heel_slide_thumb"
        ),
        Exercise(
            name: "Seated Knee Flexion",
            bodyArea: .knee,
            visualDescription: "Sit on a chair. Slowly bend your knee under the seat as far as comfortable. Hold, then release.",
            targetAngleRange: 90...110,
            holdSeconds: 3,
            reps: 3,
            steps: [
                ExerciseStep(stepNumber: 1, title: "Start & Finish", instruction: "Sit upright, slide your foot back under the chair to bend the knee. Hold 3 seconds at max bend, then return to start.", imageName: "seated_flexion_1"),
            ],
            caregiverTip: "Sit facing the patient to encourage them. Place a towel under their foot to reduce friction if needed.",
            thumbnailName: "seated_flexion_1"
        ),
    ]
    
    static let kneeExtensionExercises: [Exercise] = [
        Exercise(
            name: "Straight Leg Raises",
            bodyArea: .knee,
            visualDescription: "Lie on your back. Keep the leg perfectly straight, tighten your thigh, and lift it about 30cm off the ground.",
            targetAngleRange: 0...5,
            holdSeconds: 3,
            reps: 3,
            steps: [
                ExerciseStep(stepNumber: 1, title: "Start", instruction: "Lie flat. Bend the uninvolved knee for support. Keep the exercising leg straight.", imageName: "slr_1"),
                ExerciseStep(stepNumber: 2, title: "Lift & Hold", instruction: "Tighten your thigh, lift the straight leg about 30 cm. Hold for 3 seconds, then slowly lower.", imageName: "slr_2"),
            ],
            caregiverTip: "Watch that the knee stays locked straight during the lift. If it bends, the thigh muscles aren't engaging enough — remind them to squeeze.",
            thumbnailName: "slr_1"
        ),
        Exercise(
            name: "Prone Knee Extension",
            bodyArea: .knee,
            visualDescription: "Lie face-down. Place a rolled towel under your ankle and let gravity straighten the knee.",
            targetAngleRange: 0...5,
            holdSeconds: 5,
            reps: 3,
            steps: [
                ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Lie face-down. Place a rolled towel under the ankle of the affected leg.", imageName: "prone_ext_1"),
                ExerciseStep(stepNumber: 2, title: "Relax", instruction: "Let the knee sag toward the surface — gravity does the work.", imageName: "prone_ext_2"),
                ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Stay relaxed for 5 seconds. Repeat.", imageName: "prone_ext_3"),
            ],
            caregiverTip: "Ensure the towel is under the ankle, not the knee. Gently press down on the back of the thigh if tolerated.",
            thumbnailName: "prone_ext_thumb"
        ),
    ]
}

// MARK: - Shoulder Exercises

extension Exercise {
    static let shoulderExercises: [Exercise] = [
        Exercise(
            name: "Pendulum Swings",
            bodyArea: .shoulder,
            visualDescription: "Lean forward with support. Let your affected arm hang and gently swing it in small circles.",
            targetAngleRange: 0...30,
            holdSeconds: 0,
            reps: 10,
            steps: [
                ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Lean forward, supporting yourself with your good arm on a table.", imageName: "pendulum_1"),
                ExerciseStep(stepNumber: 2, title: "Swing", instruction: "Let your affected arm hang loose. Swing it gently in small circles.", imageName: "pendulum_2"),
                ExerciseStep(stepNumber: 3, title: "Reverse", instruction: "Reverse the circle direction after 10 swings.", imageName: "pendulum_3"),
            ],
            caregiverTip: "Ensure the patient is stable and leaning on a sturdy surface. The arm should be completely relaxed — no muscle effort.",
            thumbnailName: "pendulum_thumb"
        ),
        Exercise(
            name: "Sleeper Stretch",
            bodyArea: .shoulder,
            visualDescription: "Lie on your affected side. Use your other hand to gently push the forearm toward the floor for internal rotation.",
            targetAngleRange: 30...60,
            holdSeconds: 5,
            reps: 3,
            steps: [
                ExerciseStep(stepNumber: 1, title: "Position", instruction: "Lie on your affected side, elbow bent 90°, forearm pointing up.", imageName: "sleeper_1"),
                ExerciseStep(stepNumber: 2, title: "Press", instruction: "Use your other hand to gently push the forearm toward the floor.", imageName: "sleeper_2"),
                ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold the stretch for 5 seconds. You should feel a gentle pull.", imageName: "sleeper_3"),
            ],
            caregiverTip: "Apply very gentle pressure. Stop immediately if the patient reports sharp pain. This should be a mild stretch only.",
            thumbnailName: "sleeper_thumb"
        ),
    ]
}

// MARK: - Ankle Exercises

extension Exercise {
    static let ankleExercises: [Exercise] = [
        Exercise(
            name: "Ankle Alphabet",
            bodyArea: .ankle,
            visualDescription: "Sit with your leg elevated. Use your foot to trace the letters of the alphabet in the air.",
            targetAngleRange: 0...45,
            holdSeconds: 0,
            reps: 1,
            steps: [
                ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Sit with your affected leg elevated on a pillow or stool.", imageName: "ankle_abc_1"),
                ExerciseStep(stepNumber: 2, title: "Trace", instruction: "Use your big toe to 'write' the letters A through Z in the air.", imageName: "ankle_abc_2"),
                ExerciseStep(stepNumber: 3, title: "Rest", instruction: "Rest for 30 seconds, then repeat if comfortable.", imageName: "ankle_abc_3"),
            ],
            caregiverTip: "This is a gentle range-of-motion exercise. Encourage full movement in all directions. Call out letters to make it fun.",
            thumbnailName: "ankle_abc_thumb"
        ),
    ]
}

// MARK: - Hip Exercises

extension Exercise {
    static let hipExercises: [Exercise] = [
        Exercise(
            name: "Clamshells",
            bodyArea: .hip,
            visualDescription: "Lie on your side with knees bent. Keep feet together and lift the top knee like a clamshell opening.",
            targetAngleRange: 30...50,
            holdSeconds: 3,
            reps: 5,
            steps: [
                ExerciseStep(stepNumber: 1, title: "Start", instruction: "Lie on your unaffected side, knees bent at 45°, feet together.", imageName: "clamshell_1"),
                ExerciseStep(stepNumber: 2, title: "Open", instruction: "Keeping feet together, lift your top knee as high as comfortable.", imageName: "clamshell_2"),
                ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold at the top for 3 seconds, then slowly lower.", imageName: "clamshell_3"),
            ],
            caregiverTip: "Place your hand on the patient's hip to ensure they don't roll backward. The pelvis should stay still — only the knee moves.",
            thumbnailName: "clamshell_thumb"
        ),
    ]
}

// MARK: - Elbow Exercises

extension Exercise {
    static let elbowExercises: [Exercise] = [
        Exercise(
            name: "Elbow Flexion & Extension",
            bodyArea: .elbow,
            visualDescription: "Sit or stand upright. Slowly bend and straighten your elbow through full range of motion.",
            targetAngleRange: 10...130,
            holdSeconds: 3,
            reps: 5,
            steps: [
                ExerciseStep(stepNumber: 1, title: "Start", instruction: "Stand or sit with your arm at your side, palm facing forward."),
                ExerciseStep(stepNumber: 2, title: "Bend", instruction: "Slowly bend your elbow, bringing your hand toward your shoulder."),
                ExerciseStep(stepNumber: 3, title: "Extend", instruction: "Slowly straighten the elbow back to the starting position. Repeat."),
            ],
            caregiverTip: "Support the upper arm if needed. Ensure the movement is smooth — no jerking. Stop if pain is sharp."
        ),
    ]
}
