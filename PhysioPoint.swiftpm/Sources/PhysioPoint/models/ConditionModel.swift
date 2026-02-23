import Foundation

// BodyArea is defined in ExerciseModel.swift — do NOT re-declare here.

// MARK: - Condition Category

/// Categories of conditions per body area.
enum ConditionCategory: String, CaseIterable, Codable, Hashable {
    // Knee
    case generalPain
    case dislocationTherapy
    case painBending
    // Elbow
    case elbowGeneralPain
    case elbowDislocation
    case elbowPainBending
    // Hip
    case hipGeneralPain
    case troubleTwisting
    case painInBending
    // Ankle
    case ankleGeneralPain
    case twistedRolled
    case painRotating
    // Shoulder
    case shoulderGeneralPain
    case dislocatedShoulder
    case painLifting
    
    var displayName: String {
        switch self {
        case .generalPain:          return "General Pain"
        case .dislocationTherapy:   return "Post-Dislocation"
        case .painBending:          return "Pain When Bending"
        case .elbowGeneralPain:     return "General Pain"
        case .elbowDislocation:     return "Post-Dislocation"
        case .elbowPainBending:     return "Pain When Bending"
        case .hipGeneralPain:       return "General Pain"
        case .troubleTwisting:      return "Trouble Twisting"
        case .painInBending:        return "Pain in Bending"
        case .ankleGeneralPain:     return "General Pain"
        case .twistedRolled:        return "Twisted/Rolled"
        case .painRotating:         return "Pain Rotating"
        case .shoulderGeneralPain:  return "General Pain"
        case .dislocatedShoulder:   return "Post-Dislocation"
        case .painLifting:          return "Pain Lifting Arm"
        }
    }
    
    var systemImage: String {
        switch self {
        case .generalPain, .elbowGeneralPain, .hipGeneralPain,
             .ankleGeneralPain, .shoulderGeneralPain:
            return "bandage"
        case .dislocationTherapy, .elbowDislocation, .dislocatedShoulder:
            return "arrow.triangle.2.circlepath"
        case .painBending, .elbowPainBending, .painInBending:
            return "angle"
        case .troubleTwisting:
            return "arrow.trianglehead.2.clockwise.rotate.90"
        case .twistedRolled:
            return "arrow.uturn.backward"
        case .painRotating:
            return "arrow.clockwise"
        case .painLifting:
            return "arrow.up.circle"
        }
    }
}

// MARK: - Condition

/// A rehab condition with 3 AR-validated exercises.
/// Every exercise in every condition has been tested on a real device
/// and confirmed to produce meaningful angle tracking data.
struct Condition: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let description: String
    let bodyArea: BodyArea
    let category: ConditionCategory
    let recommendedExercises: [Exercise]
    
    init(id: UUID = UUID(),
         name: String,
         description: String,
         bodyArea: BodyArea,
         category: ConditionCategory,
         recommendedExercises: [Exercise]) {
        self.id = id
        self.name = name
        self.description = description
        self.bodyArea = bodyArea
        self.category = category
        self.recommendedExercises = recommendedExercises
    }
    
    // MARK: - Full Library (12 exercises × 15 conditions, all AR-tracked)
    
    static let library: [Condition] = kneeConditions + elbowConditions
        + hipConditions + ankleConditions + shoulderConditions
    
    /// Filter conditions for a specific body area.
    static func conditions(for area: BodyArea) -> [Condition] {
        library.filter { $0.bodyArea == area }
    }
    
    // ── KNEE ─────────────────────────────────────────────────
    // Joint triple: right_upLeg → right_leg → right_foot
    // All confirmed reliable on device from side view.
    
    private static let kneeConditions: [Condition] = [
        Condition(
            name: "General Knee Pain",
            description: "Knee feels stiff or sore — gentle exercises to ease the pain.",
            bodyArea: .knee,
            category: .generalPain,
            recommendedExercises: [.seatedKneeExtension,
                                   .straightLegRaises,
                                   .heelSlides]
        ),
        Condition(
            name: "Knee Dislocation Therapy",
            description: "Gentle exercises after a kneecap slip or dislocation.",
            bodyArea: .knee,
            category: .dislocationTherapy,
            recommendedExercises: [.heelSlides,
                                   .terminalKneeExtension,
                                   .seatedKneeFlexion]
        ),
        Condition(
            name: "Knee Pain When Bending",
            description: "Hurts when you bend or climb stairs — we'll start slow.",
            bodyArea: .knee,
            category: .painBending,
            recommendedExercises: [.seatedKneeFlexion,
                                   .heelSlides,
                                   .terminalKneeExtension]
        )
    ]
    
    // ── ELBOW ────────────────────────────────────────────────
    // Joint triple: right_arm → right_forearm → right_hand
    // All confirmed reliable on device from side view.
    
    private static let elbowConditions: [Condition] = [
        Condition(
            name: "General Elbow Pain",
            description: "Elbow feels stiff or tender — gentle bending exercises.",
            bodyArea: .elbow,
            category: .elbowGeneralPain,
            recommendedExercises: [.elbowFlexionExtension,
                                   .activeElbowFlexion,
                                   .elbowExtensionStretch]
        ),
        Condition(
            name: "Elbow Dislocation Therapy",
            description: "Gentle exercises after an elbow dislocation.",
            bodyArea: .elbow,
            category: .elbowDislocation,
            recommendedExercises: [.elbowExtensionStretch,
                                   .elbowFlexionExtension,
                                   .activeElbowFlexion]
        ),
        Condition(
            name: "Elbow Pain When Bending",
            description: "Hurts when you bend or straighten your elbow.",
            bodyArea: .elbow,
            category: .elbowPainBending,
            recommendedExercises: [.activeElbowFlexion,
                                   .elbowFlexionExtension,
                                   .elbowExtensionStretch]
        )
    ]
    
    // ── HIP ──────────────────────────────────────────────────
    // Joint triple: spine → hips_joint → right_upLeg_joint
    // Standing Hip Flexion & Hip Hinge confirmed. Angle ranges FIXED
    // to match real ARKit readings (~80-140° when in correct position).
    // Single Leg Balance uses knee triple (also confirmed).
    
    private static let hipConditions: [Condition] = [
        Condition(
            name: "General Hip Pain",
            description: "Hip feels stiff or weak — gentle movements to loosen up.",
            bodyArea: .hip,
            category: .hipGeneralPain,
            recommendedExercises: [.standingHipFlexion,
                                   .hipHinge,
                                   .singleLegBalance]
        ),
        Condition(
            name: "Trouble Twisting",
            description: "Hard to twist or turn your body at the hips.",
            bodyArea: .hip,
            category: .troubleTwisting,
            recommendedExercises: [.standingHipFlexion,
                                   .singleLegBalance,
                                   .hipHinge]
        ),
        Condition(
            name: "Pain in Bending",
            description: "Hurts when you bend forward — we'll work on that.",
            bodyArea: .hip,
            category: .painInBending,
            recommendedExercises: [.hipHinge,
                                   .standingHipFlexion,
                                   .singleLegBalance]
        )
    ]
    
    // ── ANKLE ────────────────────────────────────────────────
    // ARKit cannot track foot/toe joints reliably.
    // Ankle conditions use leg-level proxy exercises that are all
    // AR-tracked and help ankle recovery through balance + stability.
    
    private static let ankleConditions: [Condition] = [
        Condition(
            name: "General Ankle Pain",
            description: "Ankle feels stiff — balance and stability exercises.",
            bodyArea: .ankle,
            category: .ankleGeneralPain,
            recommendedExercises: [.singleLegBalance,
                                   .standingHipFlexion,
                                   .seatedKneeExtension]
        ),
        Condition(
            name: "Twisted/Rolled Ankle",
            description: "Sprained ankle — start putting weight on it slowly.",
            bodyArea: .ankle,
            category: .twistedRolled,
            recommendedExercises: [.singleLegBalance,
                                   .hipHinge,
                                   .straightLegRaises]
        ),
        Condition(
            name: "Broken Ankle / Pain Rotating",
            description: "Recovering from a break — gentle strength and balance.",
            bodyArea: .ankle,
            category: .painRotating,
            recommendedExercises: [.singleLegBalance,
                                   .seatedKneeExtension,
                                   .standingHipFlexion]
        )
    ]
    
    // ── SHOULDER ─────────────────────────────────────────────
    // Joint triple: spine_7 → right_shoulder_1 → right_arm
    // Wall Slides, Supine Shoulder Flexion, Standing Shoulder Flexion
    // all confirmed working on device from side view.
    
    private static let shoulderConditions: [Condition] = [
        Condition(
            name: "General Shoulder Pain",
            description: "Shoulder feels stiff or has a pinching pain.",
            bodyArea: .shoulder,
            category: .shoulderGeneralPain,
            recommendedExercises: [.wallSlidesShoulder,
                                   .standingShoulderFlexion,
                                   .supineShoulderFlexion]
        ),
        Condition(
            name: "Dislocated Shoulder",
            description: "Gentle exercises after a shoulder dislocation.",
            bodyArea: .shoulder,
            category: .dislocatedShoulder,
            recommendedExercises: [.supineShoulderFlexion,
                                   .wallSlidesShoulder,
                                   .standingShoulderFlexion]
        ),
        Condition(
            name: "Pain Lifting Arm",
            description: "Hard to raise your arm up — we'll help you get there.",
            bodyArea: .shoulder,
            category: .painLifting,
            recommendedExercises: [.standingShoulderFlexion,
                                   .wallSlidesShoulder,
                                   .supineShoulderFlexion]
        )
    ]
}
