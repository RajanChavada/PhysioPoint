import Foundation

// MARK: - Tracking Mode

/// Defines how the AR engine should interpret the angle measurement for a given exercise.
/// Labels are for educational demo only — not medical prescriptions.
public enum TrackingMode: String, Hashable, Codable {
    case angleBased          // Measure joint angle, count reps when held in zone
    case holdDuration        // Hold a position for N seconds (isometric)
    case rangeOfMotion       // Track range through a movement arc
    case repetitionCounting  // Count full bend/extend cycles
}

// MARK: - Camera Position

/// Recommended camera placement for best ARKit tracking accuracy.
public enum CameraPosition: String, Codable, Hashable {
    case side   // Side view — best for sagittal plane movements (knee, elbow, shoulder)
    case front  // Front view — best for frontal plane movements (balance)
}

// MARK: - Tracking Reliability

/// ARKit tracking reliability tier based on real-device testing.
public enum TrackingReliability: String, Hashable, Codable {
    case reliable   // Confirmed working on device (~3-8° error)
    case marginal   // Works with wider tolerances (~10-20° error)
}

// MARK: - Rep Direction

/// Which direction the angle moves during the "active" phase of the exercise.
/// Used by the phase-based rep counter to know when a rep is complete.
public enum RepDirection: String, Hashable, Codable {
    case increasing  // Angle goes UP during active phase (e.g. knee extension: 90° → 180°)
    case decreasing  // Angle goes DOWN during active phase (e.g. hip flexion: 170° → 100°)
}

// MARK: - Form Cue

/// An optional "good form" check shown to the user during the exercise.
public struct FormCue: Hashable {
    public let description: String
    public let jointToWatch: String?
    /// If non-nil, this cue fires when the secondary joint's deviation exceeds this value (degrees).
    public let maxAngleDeviation: Double?
    /// If non-nil, this cue only shows when the primary angle is in this zone.
    public let zone: AngleZone?

    public init(
        description: String,
        jointToWatch: String? = nil,
        maxAngleDeviation: Double? = nil,
        zone: AngleZone? = nil
    ) {
        self.description = description
        self.jointToWatch = jointToWatch
        self.maxAngleDeviation = maxAngleDeviation
        self.zone = zone
    }
}

// MARK: - Joint Tracking Config

/// Defines which 3 ARKit joints form the angle triple for a given exercise,
/// plus what "good form" means and the correct AR-measured target angle range.
///
/// ALL exercises in this file have been validated on a real device.
/// Timer-only and unreliable exercises have been removed entirely.
///
/// Joint names use `{side}_` prefix (e.g. "right_arm_joint") which gets resolved
/// at runtime based on which side the user is exercising.
public struct JointTrackingConfig: Hashable {
    public let proximalJoint: String
    public let middleJoint: String
    public let distalJoint: String
    public let mode: TrackingMode
    public let targetRange: ClosedRange<Double>
    public let formCues: [FormCue]
    public let cameraPosition: CameraPosition
    public let reliability: TrackingReliability
    public let repDirection: RepDirection
    public let restAngle: Double  // Approximate angle when at rest (used for phase detection)

    public init(
        proximalJoint: String,
        middleJoint: String,
        distalJoint: String,
        mode: TrackingMode,
        targetRange: ClosedRange<Double>,
        formCues: [FormCue],
        cameraPosition: CameraPosition,
        reliability: TrackingReliability,
        repDirection: RepDirection,
        restAngle: Double
    ) {
        self.proximalJoint = proximalJoint
        self.middleJoint = middleJoint
        self.distalJoint = distalJoint
        self.mode = mode
        self.targetRange = targetRange
        self.formCues = formCues
        self.cameraPosition = cameraPosition
        self.reliability = reliability
        self.repDirection = repDirection
        self.restAngle = restAngle
    }
}

// MARK: - Exercise → Tracking Config (Device-Validated Only)

extension Exercise {

    /// Returns the ARKit joint tracking configuration for this exercise.
    /// Returns `nil` ONLY for exercises not in the active library (should never happen
    /// since all condition presets now use only validated exercises).
    ///
    /// Every config below has been tested on a real device and confirmed to produce
    /// meaningful angle data with the specified joint triple.
    ///
    /// SHOULDER FIX: Changed proximal from spine_7 → hips_joint.
    ///   spine_7 → shoulder → arm only swings ~40° because spine_7 is close to shoulder.
    ///   hips_joint → shoulder → arm swings ~150° (rest ~20°, overhead ~160°+).
    ///
    /// HIP HINGE FIX: Changed from spine_7 → hips → upLeg (all move together)
    ///   to spine_7 → right_upLeg → right_leg (angle at top of femur, measures forward bend).
    var trackingConfig: JointTrackingConfig? {
        switch name {

        // ═══════════════════════════════════════════════════════════════
        // KNEE — right_upLeg_joint → right_leg_joint → right_foot_joint
        // Confirmed: large visible joint, side view, ~3-5° error
        // ═══════════════════════════════════════════════════════════════

        case "Seated Knee Extension":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint",
                middleJoint: "right_leg_joint",
                distalJoint: "right_foot_joint",
                mode: .angleBased,
                targetRange: 150...180,
                formCues: [
                    FormCue(description: "Sit tall — back against the chair, no leaning.", jointToWatch: "spine_4_joint", maxAngleDeviation: 15),
                    FormCue(description: "Toes point up, not out.", jointToWatch: "right_foot_joint", zone: .belowTarget),
                    FormCue(description: "Let the movement come from the knee, not the hip.", zone: .target)
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .increasing,
                restAngle: 90
            )

        case "Straight Leg Raises":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint",
                middleJoint: "right_leg_joint",
                distalJoint: "right_foot_joint",
                mode: .angleBased,
                targetRange: 160...180,
                formCues: [
                    FormCue(description: "Keep the knee fully locked straight as you lift.", jointToWatch: "right_leg_joint", maxAngleDeviation: 15),
                    FormCue(description: "Low back stays flat — don't arch.", jointToWatch: "spine_4_joint", maxAngleDeviation: 12),
                    FormCue(description: "Lift slowly, lower with control.")
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .increasing,
                restAngle: 170
            )

        case "Heel Slides":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint",
                middleJoint: "right_leg_joint",
                distalJoint: "right_foot_joint",
                mode: .rangeOfMotion,
                targetRange: 60...120,
                formCues: [
                    FormCue(description: "Back stays flat on the surface — no bridging.", jointToWatch: "hips_joint", maxAngleDeviation: 10),
                    FormCue(description: "Slide the heel in slowly — don't rush the bend.", zone: .belowTarget),
                    FormCue(description: "Good depth — now slide back out with the same control.", zone: .target)
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .decreasing,
                restAngle: 170
            )

        case "Terminal Knee Extension":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint",
                middleJoint: "right_leg_joint",
                distalJoint: "right_foot_joint",
                mode: .angleBased,
                targetRange: 155...180,
                formCues: [
                    FormCue(description: "Knee tracks straight — don't let it drift inward.", jointToWatch: "right_leg_joint", maxAngleDeviation: 12),
                    FormCue(description: "Push straight back — no hip rotation.", jointToWatch: "hips_joint"),
                    FormCue(description: "Hold 2 seconds at full extension.", zone: .target)
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .increasing,
                restAngle: 150
            )

        case "Seated Knee Flexion":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint",
                middleJoint: "right_leg_joint",
                distalJoint: "right_foot_joint",
                mode: .rangeOfMotion,
                targetRange: 70...120,
                formCues: [
                    FormCue(description: "Torso stays upright — don't lean forward.", jointToWatch: "spine_4_joint", maxAngleDeviation: 15),
                    FormCue(description: "Let gravity help — just let the leg drop slowly.", zone: .belowTarget),
                    FormCue(description: "Good range — hold briefly before returning.", zone: .target)
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .decreasing,
                restAngle: 170
            )

        case "Single Leg Balance":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint",
                middleJoint: "right_leg_joint",
                distalJoint: "right_foot_joint",
                mode: .holdDuration,
                targetRange: 155...180,
                formCues: [
                    FormCue(description: "Stand tall — eyes on a fixed point in front.", jointToWatch: "spine_7_joint", maxAngleDeviation: 10),
                    FormCue(description: "Opposite foot fully off the floor.", jointToWatch: "left_foot_joint"),
                    FormCue(description: "Breathe normally — tension makes balance harder.", zone: .target)
                ],
                cameraPosition: .front,
                reliability: .reliable,
                repDirection: .increasing,
                restAngle: 170
            )

        // ═══════════════════════════════════════════════════════════════
        // ELBOW — right_arm_joint → right_forearm_joint → right_hand_joint
        // Confirmed: clear flexion/extension arc, side view, ~5-8° error
        // ═══════════════════════════════════════════════════════════════

        case "Elbow Flexion & Extension":
            return JointTrackingConfig(
                proximalJoint: "right_arm_joint",
                middleJoint: "right_forearm_joint",
                distalJoint: "right_hand_joint",
                mode: .repetitionCounting,
                targetRange: 30...90,
                formCues: [
                    FormCue(description: "Upper arm stays pinned to your side — no swinging.", jointToWatch: "right_shoulder_1_joint", maxAngleDeviation: 15),
                    FormCue(description: "Full extension on the way down — straighten it all the way.", zone: .belowTarget), // using below target since it's inverted angle logic?
                    FormCue(description: "Squeeze at the top of the curl.", zone: .target)
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .decreasing,
                restAngle: 170
            )

        case "Active Elbow Flexion":
            return JointTrackingConfig(
                proximalJoint: "right_arm_joint",
                middleJoint: "right_forearm_joint",
                distalJoint: "right_hand_joint",
                mode: .repetitionCounting,
                targetRange: 30...90,
                formCues: [
                    FormCue(description: "Keep the upper arm completely still.", jointToWatch: "right_arm_joint", maxAngleDeviation: 12),
                    FormCue(description: "Wrist stays neutral — don't curl it.", jointToWatch: "right_hand_joint"),
                    FormCue(description: "Smooth arc — no jerky momentum.")
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .decreasing,
                restAngle: 170
            )

        case "Elbow Extension Stretch":
            return JointTrackingConfig(
                proximalJoint: "right_arm_joint",
                middleJoint: "right_forearm_joint",
                distalJoint: "right_hand_joint",
                mode: .holdDuration,
                targetRange: 150...180,
                formCues: [
                    FormCue(description: "Shoulder stays completely still — stretch is at the elbow only.", jointToWatch: "right_shoulder_1_joint", maxAngleDeviation: 10),
                    FormCue(description: "Gentle overpressure — no pain, just mild tension.", zone: .belowTarget),
                    FormCue(description: "Hold the stretch — don't bounce.", zone: .target)
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .increasing,
                restAngle: 90
            )

        // ═══════════════════════════════════════════════════════════════
        // SHOULDER — hips_joint → right_shoulder_1_joint → right_arm_joint
        // FIX: Changed proximal from spine_7 → hips_joint.
        //   spine_7 is too close to shoulder → only ~40° swing.
        //   hips_joint is the pelvis center → gives ~150° swing arc.
        //   Real device: rest ~20-30°, overhead ~160-170°.
        // ═══════════════════════════════════════════════════════════════

        case "Wall Slides":
            return JointTrackingConfig(
                proximalJoint: "hips_joint",
                middleJoint: "right_shoulder_1_joint",
                distalJoint: "right_arm_joint",
                mode: .rangeOfMotion,
                targetRange: 130...175,
                formCues: [
                    FormCue(description: "Back of hand AND elbow must stay touching the wall.", jointToWatch: "right_arm_joint", maxAngleDeviation: 10),
                    FormCue(description: "Ribs stay down — don't flare the chest to reach higher.", jointToWatch: "spine_4_joint", maxAngleDeviation: 12),
                    FormCue(description: "Slide smoothly — no shrugging the shoulder.")
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .increasing,
                restAngle: 25
            )

        case "Supine Shoulder Flexion":
            return JointTrackingConfig(
                proximalJoint: "hips_joint",
                middleJoint: "right_shoulder_1_joint",
                distalJoint: "right_arm_joint",
                mode: .rangeOfMotion,
                targetRange: 130...175,
                formCues: [
                    FormCue(description: "Back stays flat — no arching.", jointToWatch: "spine_4_joint", maxAngleDeviation: 10),
                    FormCue(description: "Arm leads the movement — don't use momentum.", zone: .belowTarget),
                    FormCue(description: "Hold at the top — breathe out.", zone: .target)
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .increasing,
                restAngle: 25
            )

        case "Standing Shoulder Flexion":
            return JointTrackingConfig(
                proximalJoint: "hips_joint",
                middleJoint: "right_shoulder_1_joint",
                distalJoint: "right_arm_joint",
                mode: .rangeOfMotion,
                targetRange: 130...175,
                formCues: [
                    FormCue(description: "Torso upright — no leaning back to cheat the range.", jointToWatch: "spine_4_joint", maxAngleDeviation: 15),
                    FormCue(description: "Elbow stays soft — not rigidly locked.", jointToWatch: "right_forearm_joint"),
                    FormCue(description: "Lower slowly — don't let gravity drop the arm.")
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .increasing,
                restAngle: 25
            )

        // ═══════════════════════════════════════════════════════════════
        // HIP
        // Standing Hip Flexion: spine_4 → hips → right_upLeg (confirmed)
        //   Angle DECREASES from ~170° to ~90-120° as leg lifts.
        //
        // Hip Hinge FIX: Changed from spine_7 → hips → upLeg (all move together)
        //   to spine_7 → right_upLeg → right_leg.
        //   This measures the angle at the top of the femur — when you bend forward,
        //   the thigh-to-shin angle changes meaningfully.
        // ═══════════════════════════════════════════════════════════════

        case "Standing Hip Flexion":
            return JointTrackingConfig(
                proximalJoint: "spine_4_joint",
                middleJoint: "hips_joint",
                distalJoint: "right_upLeg_joint",
                mode: .angleBased,
                targetRange: 80...140,
                formCues: [
                    FormCue(description: "Stand tall — no backward lean as the leg lifts.", jointToWatch: "spine_7_joint", maxAngleDeviation: 12),
                    FormCue(description: "Lift from the hip, not the knee.", jointToWatch: "hips_joint", zone: .belowTarget),
                    FormCue(description: "Hold 2 seconds at the top.", zone: .target)
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .decreasing,
                restAngle: 170
            )

        case "Hip Hinge":
            return JointTrackingConfig(
                proximalJoint: "spine_7_joint",
                middleJoint: "right_upLeg_joint",
                distalJoint: "right_leg_joint",
                mode: .angleBased,
                targetRange: 100...150,
                formCues: [
                    FormCue(description: "Push hips back like closing a car door with your hips.", jointToWatch: "hips_joint"),
                    FormCue(description: "Spine stays long and neutral — no rounding.", jointToWatch: "spine_4_joint", maxAngleDeviation: 15),
                    FormCue(description: "Weight in the heels — toes stay light.", jointToWatch: "right_foot_joint")
                ],
                cameraPosition: .side,
                reliability: .reliable,
                repDirection: .decreasing,
                restAngle: 175
            )

        default:
            return nil
        }
    }

    /// Whether this exercise has AR body tracking. All exercises in condition presets
    /// should return true. Returns false only for legacy/unused exercises.
    var isARTracked: Bool {
        trackingConfig != nil
    }

    /// The recommended camera position for this exercise.
    var recommendedCameraPosition: CameraPosition {
        trackingConfig?.cameraPosition ?? .side
    }

    /// The tracking reliability tier.
    var trackingReliability: TrackingReliability {
        trackingConfig?.reliability ?? .reliable
    }
}
