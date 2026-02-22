import Foundation

// MARK: - Body Area

enum BodyArea: String, CaseIterable, Identifiable, Codable, Hashable {
    case knee = "Knee"
    case shoulder = "Shoulder"
    case elbow = "Elbow"
    case ankle = "Ankle"
    case hip = "Hip"
    var id: String { rawValue }
    
    var displayName: String {
        rawValue
    }
    
    var systemImage: String {
        switch self {
        case .shoulder: return "figure.arms.open"
        case .elbow:    return "figure.strengthtraining.traditional"
        case .hip:      return "figure.walk"
        case .knee:     return "figure.run"
        case .ankle:    return "figure.step.training"
        }
    }
}

// MARK: - Exercise Step

/// A single step in an exercise's instruction sequence.
struct ExerciseStep: Identifiable, Hashable, Codable {
    var id: Int { stepNumber }
    let stepNumber: Int
    let title: String
    let description: String
    
    /// Alias so views can use `step.instruction`
    var instruction: String { description }
    
    /// Optional image name (not used in current library, but keeps UI code happy)
    var imageName: String? { nil }
}

// MARK: - Exercise

/// A physiotherapy exercise — all exercises in this file have been
/// validated on a real device with ARKit body tracking.
/// No timer-only exercises remain; every exercise produces meaningful angle data.
struct Exercise: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let bodyArea: BodyArea
    let description: String
    let targetAngleRange: ClosedRange<Double>
    let holdSeconds: Int
    let reps: Int
    let steps: [ExerciseStep]
    let caregiverTip: String?
    
    /// Alias for `description` — used by SessionIntroView
    var visualDescription: String { description }
    
    init(id: UUID = UUID(),
         name: String,
         bodyArea: BodyArea,
         description: String,
         targetAngleRange: ClosedRange<Double>,
         holdSeconds: Int,
         reps: Int,
         steps: [ExerciseStep],
         caregiverTip: String? = nil) {
        self.id = id
        self.name = name
        self.bodyArea = bodyArea
        self.description = description
        self.targetAngleRange = targetAngleRange
        self.holdSeconds = holdSeconds
        self.reps = reps
        self.steps = steps
        self.caregiverTip = caregiverTip
    }
    
    // ═══════════════════════════════════════════════════════════════
    // KNEE EXERCISES (6) — all use right_upLeg → right_leg → right_foot
    // ═══════════════════════════════════════════════════════════════
    
    static let seatedKneeExtension = Exercise(
        name: "Seated Knee Extension",
        bodyArea: .knee,
        description: "Straighten your knee fully while seated.",
        targetAngleRange: 150...180,
        holdSeconds: 3,
        reps: 12,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit", description: "Sit on a firm chair with feet flat on the floor."),
            ExerciseStep(stepNumber: 2, title: "Extend", description: "Slowly straighten your right leg until the knee is fully extended."),
            ExerciseStep(stepNumber: 3, title: "Hold & Lower", description: "Hold for 3 seconds, then slowly lower back down.")
        ],
        caregiverTip: "Support the heel if needed. Ensure the thigh stays on the seat."
    )
    
    static let straightLegRaises = Exercise(
        name: "Straight Leg Raises",
        bodyArea: .knee,
        description: "Lift your leg with knee locked straight.",
        targetAngleRange: 160...180,
        holdSeconds: 3,
        reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie Down", description: "Lie on your back with one knee bent and the other straight."),
            ExerciseStep(stepNumber: 2, title: "Tighten & Lift", description: "Tighten the thigh muscle and lift the straight leg about 30cm."),
            ExerciseStep(stepNumber: 3, title: "Hold & Lower", description: "Hold 3 seconds, then slowly lower.")
        ],
        caregiverTip: "Place a hand under the thigh to ensure the knee stays locked."
    )
    
    static let heelSlides = Exercise(
        name: "Heel Slides",
        bodyArea: .knee,
        description: "Slide your heel toward your buttock to bend the knee.",
        targetAngleRange: 60...120,
        holdSeconds: 2,
        reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie Down", description: "Lie on your back with both legs straight."),
            ExerciseStep(stepNumber: 2, title: "Slide", description: "Slowly slide your heel along the surface toward your buttock."),
            ExerciseStep(stepNumber: 3, title: "Return", description: "Hold briefly, then slide back to start.")
        ],
        caregiverTip: "Guide the heel with a towel under the foot if needed."
    )
    
    static let terminalKneeExtension = Exercise(
        name: "Terminal Knee Extension",
        bodyArea: .knee,
        description: "From a slight bend, push to full knee extension.",
        targetAngleRange: 155...180,
        holdSeconds: 3,
        reps: 12,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", description: "Stand with a slight bend in the knee (use a chair for support)."),
            ExerciseStep(stepNumber: 2, title: "Extend", description: "Push the knee back to fully straight."),
            ExerciseStep(stepNumber: 3, title: "Hold", description: "Hold for 3 seconds, then relax the slight bend.")
        ],
        caregiverTip: "Stand nearby for balance support."
    )
    
    static let seatedKneeFlexion = Exercise(
        name: "Seated Knee Flexion",
        bodyArea: .knee,
        description: "Bend the knee while seated by sliding the foot back.",
        targetAngleRange: 70...120,
        holdSeconds: 2,
        reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit", description: "Sit on a chair with feet flat."),
            ExerciseStep(stepNumber: 2, title: "Slide Back", description: "Slide the foot backward under the chair as far as comfortable."),
            ExerciseStep(stepNumber: 3, title: "Return", description: "Hold briefly, then slide forward to start.")
        ],
        caregiverTip: "Ensure smooth movement — no jerking."
    )
    
    static let singleLegBalance = Exercise(
        name: "Single Leg Balance",
        bodyArea: .knee,
        description: "Stand on one leg with the knee straight for balance.",
        targetAngleRange: 155...180,
        holdSeconds: 15,
        reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", description: "Stand near a wall or chair for safety."),
            ExerciseStep(stepNumber: 2, title: "Lift", description: "Lift one foot off the ground and balance on the standing leg."),
            ExerciseStep(stepNumber: 3, title: "Hold", description: "Hold for 15 seconds, then switch sides.")
        ],
        caregiverTip: "Stand close for safety. Touch the wall lightly if needed."
    )
    
    // ═══════════════════════════════════════════════════════════════
    // ELBOW EXERCISES (3) — all use right_arm → right_forearm → right_hand
    // ═══════════════════════════════════════════════════════════════
    
    static let elbowFlexionExtension = Exercise(
        name: "Elbow Flexion & Extension",
        bodyArea: .elbow,
        description: "Slowly bend and straighten your elbow through full range of motion.",
        targetAngleRange: 30...170,
        holdSeconds: 3,
        reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Start", description: "Stand with arm at your side, palm forward."),
            ExerciseStep(stepNumber: 2, title: "Bend", description: "Slowly bend elbow, bringing hand toward shoulder."),
            ExerciseStep(stepNumber: 3, title: "Extend", description: "Slowly straighten back to start.")
        ],
        caregiverTip: "Support the upper arm if needed. Ensure smooth movement."
    )
    
    static let activeElbowFlexion = Exercise(
        name: "Active Elbow Flexion",
        bodyArea: .elbow,
        description: "Actively curl the forearm upward against gravity.",
        targetAngleRange: 30...160,
        holdSeconds: 2,
        reps: 12,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", description: "Stand with arm at side, palm facing up."),
            ExerciseStep(stepNumber: 2, title: "Curl", description: "Bend the elbow to bring hand toward shoulder."),
            ExerciseStep(stepNumber: 3, title: "Lower", description: "Slowly lower back to the starting position.")
        ],
        caregiverTip: "Keep the upper arm still — only the forearm should move."
    )
    
    static let elbowExtensionStretch = Exercise(
        name: "Elbow Extension Stretch",
        bodyArea: .elbow,
        description: "Hold the arm straight to stretch into full extension.",
        targetAngleRange: 150...180,
        holdSeconds: 10,
        reps: 5,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit or Stand", description: "Place the back of your upper arm on a table edge."),
            ExerciseStep(stepNumber: 2, title: "Straighten", description: "Let gravity gently straighten the elbow."),
            ExerciseStep(stepNumber: 3, title: "Hold", description: "Hold the stretch for 10 seconds.")
        ],
        caregiverTip: "Apply gentle pressure above the elbow if tolerated."
    )
    
    // ═══════════════════════════════════════════════════════════════
    // SHOULDER EXERCISES (3) — all use spine_7 → right_shoulder_1 → right_arm
    // ═══════════════════════════════════════════════════════════════
    
    static let wallSlidesShoulder = Exercise(
        name: "Wall Slides",
        bodyArea: .shoulder,
        description: "Slide arms up a wall to improve overhead range of motion.",
        targetAngleRange: 140...185,
        holdSeconds: 3,
        reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand at Wall", description: "Stand facing a wall, forearms flat against it."),
            ExerciseStep(stepNumber: 2, title: "Slide Up", description: "Slowly slide hands upward as high as comfortable."),
            ExerciseStep(stepNumber: 3, title: "Slide Down", description: "Slowly lower back to start.")
        ],
        caregiverTip: "Ensure back stays flat against wall throughout."
    )
    
    static let supineShoulderFlexion = Exercise(
        name: "Supine Shoulder Flexion",
        bodyArea: .shoulder,
        description: "Lying on your back, raise the arm overhead.",
        targetAngleRange: 140...185,
        holdSeconds: 3,
        reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie Down", description: "Lie on your back, arm at your side."),
            ExerciseStep(stepNumber: 2, title: "Raise", description: "Slowly raise the arm overhead toward the ceiling then floor behind."),
            ExerciseStep(stepNumber: 3, title: "Lower", description: "Slowly return to your side.")
        ],
        caregiverTip: "Use the other hand to assist if strength is limited."
    )
    
    static let standingShoulderFlexion = Exercise(
        name: "Standing Shoulder Flexion",
        bodyArea: .shoulder,
        description: "Standing upright, raise the arm forward and overhead.",
        targetAngleRange: 140...185,
        holdSeconds: 3,
        reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", description: "Stand upright with arm at your side."),
            ExerciseStep(stepNumber: 2, title: "Raise", description: "Slowly raise arm forward and up overhead."),
            ExerciseStep(stepNumber: 3, title: "Lower", description: "Slowly lower back to your side.")
        ],
        caregiverTip: "Stand behind for support. Ensure torso stays upright."
    )
    
    // ═══════════════════════════════════════════════════════════════
    // HIP EXERCISES (2 + Single Leg Balance shared with knee)
    // spine → hips_joint → right_upLeg_joint
    // Angle ranges FIXED: standing upright = ~170-180°, flexed = ~80-130°
    // ═══════════════════════════════════════════════════════════════
    
    static let standingHipFlexion = Exercise(
        name: "Standing Hip Flexion",
        bodyArea: .hip,
        description: "Standing, lift the knee toward the chest.",
        targetAngleRange: 80...140,
        holdSeconds: 3,
        reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", description: "Stand holding a chair or wall for balance."),
            ExerciseStep(stepNumber: 2, title: "Lift", description: "Lift the knee toward your chest as far as comfortable."),
            ExerciseStep(stepNumber: 3, title: "Lower", description: "Slowly lower the leg back down.")
        ],
        caregiverTip: "Stand beside for balance. Ensure no backward lean."
    )
    
    static let hipHinge = Exercise(
        name: "Hip Hinge",
        bodyArea: .hip,
        description: "Bend forward at the hips keeping the spine neutral.",
        targetAngleRange: 80...130,
        holdSeconds: 3,
        reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", description: "Stand with feet hip-width apart, slight knee bend."),
            ExerciseStep(stepNumber: 2, title: "Hinge", description: "Push hips backward and lean torso forward — spine stays straight."),
            ExerciseStep(stepNumber: 3, title: "Return", description: "Squeeze glutes to return to standing.")
        ],
        caregiverTip: "Place a hand on their back to cue spine neutrality."
    )
    
    // ═══════════════════════════════════════════════════════════════
    // LEGACY ARRAY ACCESSORS (for backward compatibility)
    // ═══════════════════════════════════════════════════════════════
    
    static let kneeExercises: [Exercise] = [
        .seatedKneeExtension, .straightLegRaises, .heelSlides,
        .terminalKneeExtension, .seatedKneeFlexion, .singleLegBalance
    ]
    
    static let elbowExercises: [Exercise] = [
        .elbowFlexionExtension, .activeElbowFlexion, .elbowExtensionStretch
    ]
    
    static let shoulderExercises: [Exercise] = [
        .wallSlidesShoulder, .supineShoulderFlexion, .standingShoulderFlexion
    ]
    
    static let hipExercises: [Exercise] = [
        .standingHipFlexion, .hipHinge, .singleLegBalance
    ]
    
    static let ankleExercises: [Exercise] = [
        .singleLegBalance, .standingHipFlexion, .seatedKneeExtension
    ]
}
