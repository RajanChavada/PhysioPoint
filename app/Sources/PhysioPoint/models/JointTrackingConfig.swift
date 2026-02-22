import Foundation

// MARK: - Tracking Mode

/// Defines how the AR engine should interpret the angle measurement for a given exercise.
/// Labels are for educational demo only — not medical prescriptions.
enum TrackingMode: String, Hashable, Codable {
    case angleBased          // Primary: measure joint angle, count reps on hold
    case holdDuration        // Primary: hold a position for N seconds (isometric)
    case rangeOfMotion       // Primary: track range through a movement arc
    case repetitionCounting  // Primary: count full bend/extend cycles
    case timerOnly           // Fallback: no skeleton tracking possible (grip, rotation)
}

// MARK: - Camera Position

/// Recommended camera placement for best ARKit tracking accuracy.
enum CameraPosition: String, Codable, Hashable {
    case side   // Side view — best for sagittal plane movements (knee, elbow)
    case front  // Front view — best for frontal plane movements (clamshells, balance)
}

// MARK: - Tracking Reliability

/// ARKit tracking reliability tier based on real-world accuracy research.
/// Average ARKit error is ~18.8° ± 12.1°. Side-view large joints: ~3.75° error.
/// Exercises classified by how reliably ARKit body skeleton can measure them.
enum TrackingReliability: String, Hashable, Codable {
    case reliable   // Large visible joint movements, side/front view (~3-8° error)
    case marginal   // May work with wider tolerances, some occlusion risk (~10-20° error)
    case unreliable // Small movements, occluded joints, or non-angle movements → timer only
}

// MARK: - Form Cue

/// An optional "good form" check shown to the user during the exercise.
struct FormCue: Hashable {
    let description: String
    let jointToWatch: String?   // ARKit joint name to monitor, nil for general cue
}

// MARK: - Joint Tracking Config

/// Defines which 3 ARKit joints form the angle triple for a given exercise,
/// plus what "good form" means and the correct AR-measured target angle range.
/// Widened tolerance zones account for ARKit's ~18° average error.
struct JointTrackingConfig: Hashable {
    let proximalJoint: String   // e.g. "right_upLeg_joint" (hip)
    let middleJoint: String     // e.g. "right_leg_joint"   (knee)
    let distalJoint: String     // e.g. "right_foot_joint"  (ankle)
    let mode: TrackingMode
    let targetRange: ClosedRange<Double>  // AR-measured angle range for "in zone" (widened for ARKit error)
    let formCues: [FormCue]
    let cameraPosition: CameraPosition
    let reliability: TrackingReliability
}

// MARK: - Exercise → Tracking Config Lookup (ARKit Accuracy Audited)

extension Exercise {

    /// Returns the ARKit joint tracking configuration for this exercise.
    /// Returns `nil` for exercises that can't be reliably tracked via body skeleton.
    ///
    /// Classification based on ARKit body tracking accuracy research:
    /// - Average error: ~18.8° ± 12.1° across all joints
    /// - Best case: ~3.75° (large joints, side view)
    /// - Worst case: ~47° (occluded joints, complex movements)
    /// - Wrist/foot/toe joints barely update → timer only
    /// - Side view performs significantly better than frontal
    /// - Tolerance zones widened to account for ARKit error margins
    var trackingConfig: JointTrackingConfig? {
        switch name {

        // ── KNEE (Reliable — large visible joint, side view) ──────────

        case "Quad Sets":
            // Marginal — subtle knee press is barely detectable, but measurable from side
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint", middleJoint: "right_leg_joint", distalJoint: "right_foot_joint",
                mode: .holdDuration, targetRange: 0...10,
                formCues: [FormCue(description: "Back of knee should press down", jointToWatch: "right_leg_joint")],
                cameraPosition: .side, reliability: .marginal
            )
        case "Short Arc Quads":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint", middleJoint: "right_leg_joint", distalJoint: "right_foot_joint",
                mode: .angleBased, targetRange: 0...10,
                formCues: [FormCue(description: "Thigh stays still", jointToWatch: "right_upLeg_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Seated Knee Extension":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint", middleJoint: "right_leg_joint", distalJoint: "right_foot_joint",
                mode: .angleBased, targetRange: 0...10,
                formCues: [FormCue(description: "Torso stays upright", jointToWatch: "spine_4_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Straight Leg Raises":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint", middleJoint: "right_leg_joint", distalJoint: "right_foot_joint",
                mode: .angleBased, targetRange: 0...10,
                formCues: [FormCue(description: "Knee must stay locked straight during lift", jointToWatch: "right_leg_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Heel Slides":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint", middleJoint: "right_leg_joint", distalJoint: "right_foot_joint",
                mode: .rangeOfMotion, targetRange: 70...105,
                formCues: [FormCue(description: "Back stays flat", jointToWatch: "hips_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Terminal Knee Extension":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint", middleJoint: "right_leg_joint", distalJoint: "right_foot_joint",
                mode: .angleBased, targetRange: 0...10,
                formCues: [FormCue(description: "Knee tracks over second toe", jointToWatch: "right_leg_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Seated Knee Flexion":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint", middleJoint: "right_leg_joint", distalJoint: "right_foot_joint",
                mode: .rangeOfMotion, targetRange: 80...120,
                formCues: [FormCue(description: "Torso upright", jointToWatch: "spine_4_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Prone Knee Flexion":
            // Marginal — face-down means back to camera, joints partially occluded
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint", middleJoint: "right_leg_joint", distalJoint: "right_foot_joint",
                mode: .rangeOfMotion, targetRange: 70...130,
                formCues: [FormCue(description: "Hip stays flat on surface — place camera at foot end", jointToWatch: "hips_joint")],
                cameraPosition: .side, reliability: .marginal
            )

        // ── ELBOW (Reliable for flexion/extension, side view) ─────────

        case "Elbow Flexion & Extension":
            return JointTrackingConfig(
                proximalJoint: "right_arm_joint", middleJoint: "right_forearm_joint", distalJoint: "right_hand_joint",
                mode: .repetitionCounting, targetRange: 5...140,
                formCues: [FormCue(description: "Shoulder stays still", jointToWatch: "right_shoulder_1_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Active Elbow Flexion":
            return JointTrackingConfig(
                proximalJoint: "right_arm_joint", middleJoint: "right_forearm_joint", distalJoint: "right_hand_joint",
                mode: .repetitionCounting, targetRange: 5...140,
                formCues: [FormCue(description: "Upper arm stays at side", jointToWatch: "right_arm_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Gravity-Assisted Extension":
            return JointTrackingConfig(
                proximalJoint: "right_arm_joint", middleJoint: "right_forearm_joint", distalJoint: "right_hand_joint",
                mode: .holdDuration, targetRange: 0...20,
                formCues: [FormCue(description: "Elbow stays relaxed", jointToWatch: "right_forearm_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Elbow Extension Stretch":
            return JointTrackingConfig(
                proximalJoint: "right_arm_joint", middleJoint: "right_forearm_joint", distalJoint: "right_hand_joint",
                mode: .holdDuration, targetRange: 0...15,
                formCues: [FormCue(description: "Shoulder stays still", jointToWatch: "right_shoulder_1_joint")],
                cameraPosition: .side, reliability: .reliable
            )

        // Timer-only elbow exercises (grip/rotation not trackable)
        case "Wrist Flexor Stretch":
            return nil  // Wrist joints barely update in ARKit — not reliable
        case "Towel Squeeze":
            return nil  // Grip force — not trackable via body skeleton
        case "Forearm Rotation":
            return nil  // Pronation/supination — axial rotation not captured by 3-joint angle

        // ── HIP / BACK ───────────────────────────────────────

        case "Clamshells":
            // Marginal — side-lying, knee opening detection depends on camera angle
            return JointTrackingConfig(
                proximalJoint: "hips_joint", middleJoint: "right_upLeg_joint", distalJoint: "right_leg_joint",
                mode: .angleBased, targetRange: 20...60,
                formCues: [FormCue(description: "Pelvis shouldn't roll backward", jointToWatch: "hips_joint")],
                cameraPosition: .front, reliability: .marginal
            )
        case "Glute Bridges":
            return JointTrackingConfig(
                proximalJoint: "right_leg_joint", middleJoint: "right_upLeg_joint", distalJoint: "hips_joint",
                mode: .angleBased, targetRange: 15...55,
                formCues: [FormCue(description: "Shoulders stay on floor", jointToWatch: "right_shoulder_1_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Standing Hip Flexion":
            return JointTrackingConfig(
                proximalJoint: "spine_4_joint", middleJoint: "hips_joint", distalJoint: "right_upLeg_joint",
                mode: .angleBased, targetRange: 20...70,
                formCues: [FormCue(description: "No backward lean", jointToWatch: "spine_7_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Hip Hinge":
            // Marginal — root joint drifts during forward bend; use relative angle only
            return JointTrackingConfig(
                proximalJoint: "spine_7_joint", middleJoint: "hips_joint", distalJoint: "right_upLeg_joint",
                mode: .angleBased, targetRange: 20...70,
                formCues: [FormCue(description: "Spine stays neutral — no rounding", jointToWatch: "spine_4_joint")],
                cameraPosition: .side, reliability: .marginal
            )
        case "Cat-Cow Stretch":
            // Marginal — spine joints are inferred, accept wide tolerance
            return JointTrackingConfig(
                proximalJoint: "hips_joint", middleJoint: "spine_4_joint", distalJoint: "spine_7_joint",
                mode: .repetitionCounting, targetRange: 5...40,
                formCues: [FormCue(description: "Wrists stay under shoulders", jointToWatch: "right_hand_joint")],
                cameraPosition: .side, reliability: .marginal
            )
        case "Single Leg Balance":
            // Detect if foot lifts — hold-based, front view
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint", middleJoint: "right_leg_joint", distalJoint: "right_foot_joint",
                mode: .holdDuration, targetRange: 0...15,
                formCues: [FormCue(description: "Opposite foot off ground", jointToWatch: "left_foot_joint")],
                cameraPosition: .front, reliability: .reliable
            )

        // Timer-only hip/back exercises (too subtle or occluded)
        case "Hip Flexor Stretch":
            return nil  // Kneeling stretch — heavy occlusion, subtle pelvic movement
        case "Seated Hip Rotation":
            return nil  // Crossed legs confuse skeleton badly
        case "Supine Hip Rotation":
            return nil  // Knees dropping to side — shoulders must stay flat, occlusion-prone
        case "Pelvic Tilt":
            return nil  // Movement is too subtle (~few degrees of spine tilt) for ARKit

        // ── ANKLE (Mostly timer-only — foot/toe joints too small for ARKit) ──

        // Timer-only: foot/toe movements are not reliably detected by ARKit body skeleton
        case "Ankle Alphabet":
            return nil  // Foot tracing movements too small for body skeleton
        case "Ankle Circles":
            return nil  // Same — ankle rotation too small
        case "Seated Calf Raises":
            return nil  // Marginal foot movement, not reliably measured
        case "Towel Scrunches":
            return nil  // Toe grip — not trackable
        case "Resistance Dorsiflexion":
            return nil  // Small ankle movement with band — not reliably detected
        case "Ankle Pumps":
            return nil  // Point/flex too small for body skeleton
        case "Seated Toe Raises":
            return nil  // Toe lift too small
        case "Seated Heel Raises":
            return nil  // Heel lift too small

        // ── SHOULDER ──────────────────────────────────────────

        case "Wall Slides":
            return JointTrackingConfig(
                proximalJoint: "spine_7_joint", middleJoint: "right_shoulder_1_joint", distalJoint: "right_arm_joint",
                mode: .rangeOfMotion, targetRange: 50...130,
                formCues: [FormCue(description: "Back stays against wall", jointToWatch: "spine_4_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "External Rotation":
            return JointTrackingConfig(
                proximalJoint: "right_shoulder_1_joint", middleJoint: "right_arm_joint", distalJoint: "right_forearm_joint",
                mode: .repetitionCounting, targetRange: 0...55,
                formCues: [FormCue(description: "Elbow stays tucked at side", jointToWatch: "right_arm_joint")],
                cameraPosition: .front, reliability: .reliable
            )
        case "Pendulum Swings":
            // Marginal — arm hanging + leaning causes occlusion, only track if arm is visible
            return JointTrackingConfig(
                proximalJoint: "right_shoulder_1_joint", middleJoint: "right_arm_joint", distalJoint: "right_forearm_joint",
                mode: .rangeOfMotion, targetRange: 0...40,
                formCues: [FormCue(description: "Arm fully relaxed — no muscle effort", jointToWatch: "right_arm_joint")],
                cameraPosition: .side, reliability: .marginal
            )
        case "Shoulder Rolls":
            return JointTrackingConfig(
                proximalJoint: "spine_7_joint", middleJoint: "right_shoulder_1_joint", distalJoint: "right_arm_joint",
                mode: .repetitionCounting, targetRange: 0...40,
                formCues: [FormCue(description: "Arms relaxed at sides", jointToWatch: "right_hand_joint")],
                cameraPosition: .front, reliability: .marginal
            )
        case "Supine Shoulder Flexion":
            return JointTrackingConfig(
                proximalJoint: "spine_7_joint", middleJoint: "right_shoulder_1_joint", distalJoint: "right_arm_joint",
                mode: .rangeOfMotion, targetRange: 50...160,
                formCues: [FormCue(description: "Back stays flat", jointToWatch: "spine_4_joint")],
                cameraPosition: .side, reliability: .reliable
            )
        case "Side-Lying External Rotation":
            return JointTrackingConfig(
                proximalJoint: "right_shoulder_1_joint", middleJoint: "right_arm_joint", distalJoint: "right_forearm_joint",
                mode: .repetitionCounting, targetRange: 0...55,
                formCues: [FormCue(description: "Elbow stays against body", jointToWatch: "right_arm_joint")],
                cameraPosition: .side, reliability: .marginal
            )

        // Timer-only shoulder exercises (occluded or not angle-based)
        case "Cross-Body Stretch":
            return nil  // Arm crosses torso = overlapping joints, heavy occlusion
        case "Sleeper Stretch":
            return nil  // Side-lying + arm across body = heavy occlusion
        case "Scapular Setting":
            return nil  // Shoulder blade squeeze = no visible joint angle change

        default:
            return nil  // Unknown exercise — timer-only fallback
        }
    }

    /// Whether this exercise uses AR body tracking or falls back to timer-only mode.
    var isTimerOnly: Bool {
        trackingConfig == nil
    }

    /// The recommended camera position for this exercise.
    /// Returns `.side` as default since side-view is generally more accurate.
    var recommendedCameraPosition: CameraPosition {
        trackingConfig?.cameraPosition ?? .side
    }

    /// The tracking reliability tier for this exercise.
    var trackingReliability: TrackingReliability {
        trackingConfig?.reliability ?? .unreliable
    }
}
