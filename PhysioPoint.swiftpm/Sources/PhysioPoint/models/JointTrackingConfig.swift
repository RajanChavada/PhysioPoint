import Foundation

// MARK: - Tracking Mode

/// Defines how the AR engine should interpret the angle measurement for a given exercise.
/// Labels are for educational demo only — not medical prescriptions.
enum TrackingMode: String, Hashable, Codable {
    case angleBased          // Measure joint angle, count reps when held in zone
    case holdDuration        // Hold a position for N seconds (isometric)
    case rangeOfMotion       // Track range through a movement arc
    case repetitionCounting  // Count full bend/extend cycles
}

// MARK: - Camera Position

/// Recommended camera placement for best ARKit tracking accuracy.
enum CameraPosition: String, Codable, Hashable {
    case side   // Side view — best for sagittal plane movements (knee, elbow, shoulder)
    case front  // Front view — best for frontal plane movements (balance)
}

// MARK: - Tracking Reliability

/// ARKit tracking reliability tier based on real-device testing.
enum TrackingReliability: String, Hashable, Codable {
    case reliable   // Confirmed working on device (~3-8° error)
    case marginal   // Works with wider tolerances (~10-20° error)
}

// MARK: - Rep Direction

/// Which direction the angle moves during the "active" phase of the exercise.
/// Used by the phase-based rep counter to know when a rep is complete.
enum RepDirection: String, Hashable, Codable {
    case increasing  // Angle goes UP during active phase (e.g. knee extension: 90° → 180°)
    case decreasing  // Angle goes DOWN during active phase (e.g. hip flexion: 170° → 100°)
}

// MARK: - Form Cue

/// An optional "good form" check shown to the user during the exercise.
struct FormCue: Hashable {
    let description: String
    let jointToWatch: String?
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
struct JointTrackingConfig: Hashable {
    let proximalJoint: String
    let middleJoint: String
    let distalJoint: String
    let mode: TrackingMode
    let targetRange: ClosedRange<Double>
    let formCues: [FormCue]
    let cameraPosition: CameraPosition
    let reliability: TrackingReliability
    let repDirection: RepDirection
    let restAngle: Double  // Approximate angle when at rest (used for phase detection)
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
                formCues: [FormCue(description: "Torso stays upright — don't lean back", jointToWatch: "spine_4_joint")],
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
                formCues: [FormCue(description: "Keep knee locked straight during lift", jointToWatch: "right_leg_joint")],
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
                formCues: [FormCue(description: "Back stays flat on the surface", jointToWatch: "hips_joint")],
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
                formCues: [FormCue(description: "Knee tracks over second toe", jointToWatch: "right_leg_joint")],
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
                formCues: [FormCue(description: "Torso stays upright", jointToWatch: "spine_4_joint")],
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
                formCues: [FormCue(description: "Stand tall — opposite foot off ground", jointToWatch: "left_foot_joint")],
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
                targetRange: 30...170,
                formCues: [FormCue(description: "Shoulder stays still — only elbow moves", jointToWatch: "right_shoulder_1_joint")],
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
                targetRange: 30...160,
                formCues: [FormCue(description: "Upper arm stays at your side", jointToWatch: "right_arm_joint")],
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
                formCues: [FormCue(description: "Shoulder stays still — gentle pressure only", jointToWatch: "right_shoulder_1_joint")],
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
                formCues: [FormCue(description: "Back stays flat against wall", jointToWatch: "spine_4_joint")],
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
                formCues: [FormCue(description: "Back stays flat — no arching", jointToWatch: "spine_4_joint")],
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
                formCues: [FormCue(description: "Torso stays upright — no leaning back", jointToWatch: "spine_4_joint")],
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
                formCues: [FormCue(description: "Stand tall — no backward lean", jointToWatch: "spine_7_joint")],
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
                formCues: [FormCue(description: "Spine stays neutral — no rounding", jointToWatch: "spine_4_joint")],
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
