import Foundation

// MARK: - Condition Category

enum ConditionCategory: String, Codable, CaseIterable, Identifiable {
    // Shared
    case generalPain        = "General Pain"
    // Knee + Elbow
    case dislocationTherapy = "Dislocation Therapy"
    case painBending        = "Pain Bending"
    // Hip / Back
    case troubleTwisting    = "Trouble Twisting"
    case painInBending      = "Pain in Bending"
    // Ankle
    case twistedRolled      = "Twisted / Rolled Ankle"
    case painRotating       = "Pain in Rotating"
    // Shoulder
    case dislocatedShoulder = "Dislocated Shoulder"
    case painLifting        = "Pain Lifting / Moving Arm"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .generalPain:        return "bandage"
        case .dislocationTherapy: return "bolt.heart"
        case .painBending:        return "arrow.up.and.down"
        case .troubleTwisting:    return "arrow.2.circlepath"
        case .painInBending:      return "arrow.down.forward"
        case .twistedRolled:      return "rotate.right"
        case .painRotating:       return "circle.dotted"
        case .dislocatedShoulder: return "figure.arms.open"
        case .painLifting:        return "arrow.up.circle"
        }
    }
}

// MARK: - Condition

struct Condition: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let bodyArea: BodyArea
    let category: ConditionCategory
    let recommendedExercises: [Exercise]

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        bodyArea: BodyArea,
        category: ConditionCategory = .generalPain,
        recommendedExercises: [Exercise] = []
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.bodyArea = bodyArea
        self.category = category
        self.recommendedExercises = recommendedExercises
    }

    /// Filter conditions for a specific body area.
    static func conditions(for area: BodyArea) -> [Condition] {
        library.filter { $0.bodyArea == area }
    }
}

// MARK: - Full Library: 5 body areas × 3 categories × 3 exercises = 15 conditions

extension Condition {
    static let library: [Condition] = kneeConditions + elbowConditions + hipConditions + ankleConditions + shoulderConditions

    // ── KNEE ─────────────────────────────────────────────

    static let kneeConditions: [Condition] = [
        Condition(
            name: "General Knee Pain",
            description: "Mild stiffness or aching around the knee. Exercises focus on gentle quad strengthening.",
            bodyArea: .knee,
            category: .generalPain,
            recommendedExercises: [.quadSets, .shortArcQuads, .seatedKneeExtension]
        ),
        Condition(
            name: "Knee Dislocation Therapy",
            description: "Recovery after a patellar dislocation. Rebuilds VMO strength and stability.",
            bodyArea: .knee,
            category: .dislocationTherapy,
            recommendedExercises: [.straightLegRaises, .heelSlides, .terminalKneeExtension]
        ),
        Condition(
            name: "Knee Pain Bending",
            description: "Difficulty bending the knee past 90°. Exercises gradually increase flexion range.",
            bodyArea: .knee,
            category: .painBending,
            recommendedExercises: [.heelSlides, .seatedKneeFlexion, .proneKneeFlexion]
        ),
    ]

    // ── ELBOW ────────────────────────────────────────────

    static let elbowConditions: [Condition] = [
        Condition(
            name: "General Elbow Pain",
            description: "Soreness or tightness in the elbow joint. Gentle stretches and grip work.",
            bodyArea: .elbow,
            category: .generalPain,
            recommendedExercises: [.elbowFlexionExtension, .wristFlexorStretch, .towelSqueeze]
        ),
        Condition(
            name: "Elbow Dislocation Therapy",
            description: "Post-dislocation rehab. Restores controlled flexion and rotation.",
            bodyArea: .elbow,
            category: .dislocationTherapy,
            recommendedExercises: [.activeElbowFlexion, .forearmRotation, .gravityElbowExtension]
        ),
        Condition(
            name: "Elbow Pain Bending",
            description: "Pain when bending or extending the elbow fully. Restores terminal range.",
            bodyArea: .elbow,
            category: .painBending,
            recommendedExercises: [.elbowFlexionExtension, .elbowExtensionStretch, .forearmRotation]
        ),
    ]

    // ── HIP / BACK ───────────────────────────────────────

    static let hipConditions: [Condition] = [
        Condition(
            name: "General Hip Pain",
            description: "Aching or stiffness in the hip area. Focuses on glute activation and flexibility.",
            bodyArea: .hip,
            category: .generalPain,
            recommendedExercises: [.clamshells, .gluteBridges, .hipFlexorStretch]
        ),
        Condition(
            name: "Trouble Twisting",
            description: "Difficulty rotating the trunk or hip. Restores rotational mobility.",
            bodyArea: .hip,
            category: .troubleTwisting,
            recommendedExercises: [.seatedHipRotation, .supineHipRotation, .catCow]
        ),
        Condition(
            name: "Hip Pain in Bending",
            description: "Pain when bending forward at the hip. Teaches safe hinge patterns.",
            bodyArea: .hip,
            category: .painInBending,
            recommendedExercises: [.hipHinge, .standingHipFlexion, .pelvicTilt]
        ),
    ]

    // ── ANKLE ────────────────────────────────────────────

    static let ankleConditions: [Condition] = [
        Condition(
            name: "General Ankle Pain",
            description: "Mild ankle discomfort or stiffness. Gentle mobility and calf work.",
            bodyArea: .ankle,
            category: .generalPain,
            recommendedExercises: [.ankleAlphabet, .ankleCircles, .seatedCalfRaises]
        ),
        Condition(
            name: "Twisted / Rolled Ankle",
            description: "Sprain recovery. Rebuilds stability, balance, and dorsiflexion.",
            bodyArea: .ankle,
            category: .twistedRolled,
            recommendedExercises: [.towelScrunches, .singleLegBalance, .resistanceDorsiflexion]
        ),
        Condition(
            name: "Broken Ankle / Pain Rotating",
            description: "Post-fracture recovery. Restores basic ankle pumping and weight tolerance.",
            bodyArea: .ankle,
            category: .painRotating,
            recommendedExercises: [.anklePumps, .seatedToeRaises, .seatedHeelRaises]
        ),
    ]

    // ── SHOULDER ─────────────────────────────────────────

    static let shoulderConditions: [Condition] = [
        Condition(
            name: "General Shoulder Pain",
            description: "Stiffness, aching, or limited mobility. Gentle warm-up and stretching.",
            bodyArea: .shoulder,
            category: .generalPain,
            recommendedExercises: [.pendulumSwings, .shoulderRolls, .crossBodyStretch]
        ),
        Condition(
            name: "Dislocated Shoulder",
            description: "Post-dislocation recovery. Restores rotator cuff strength and stability.",
            bodyArea: .shoulder,
            category: .dislocatedShoulder,
            recommendedExercises: [.sleeperStretch, .wallSlidesShoulder, .externalRotation]
        ),
        Condition(
            name: "Pain Lifting / Moving Arm",
            description: "Difficulty raising the arm overhead. Rebuilds scapular control and flexion.",
            bodyArea: .shoulder,
            category: .painLifting,
            recommendedExercises: [.scapularSetting, .supineShoulderFlexion, .sideLyingExternalRotation]
        ),
    ]
}
