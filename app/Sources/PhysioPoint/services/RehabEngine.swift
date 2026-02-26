import Foundation
import simd

// MARK: - Angle Zone

public enum AngleZone {
    case belowTarget
    case target
    case aboveTarget
}

// MARK: - Angle State

public struct AngleState {
    public let degrees: Double
    public let zone: AngleZone
}

// MARK: - Rep State

public struct RepState {
    public let repsCompleted: Int
    public let isHolding: Bool
    public let phase: RepPhase
}

// MARK: - Rep Phase (directional state machine)

/// Tracks where the user is in the rep cycle.
///   .atRest     → waiting for user to begin moving
///   .moving     → user has left the rest zone and is heading toward target
///   .inTarget   → user is inside the target angle range
///   .returning  → user left the target zone and is heading back toward rest
public enum RepPhase: String {
    case atRest
    case moving
    case inTarget
    case returning
}

// MARK: - Protocol

public protocol RehabEngine {
    /// Generic 3-joint update: proximal→joint→distal (works for any body area).
    func update(proximal: SIMD3<Float>, joint: SIMD3<Float>, distal: SIMD3<Float>) -> AngleState
    var currentRepState: RepState { get }

    /// Backward-compatible alias for knee-specific callers.
    func update(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) -> AngleState
}

extension RehabEngine {
    public func update(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) -> AngleState {
        update(proximal: hip, joint: knee, distal: ankle)
    }
}

// MARK: - Directional Phase-Based Rep Counter

/// A phase-based rep counter that understands the direction of movement.
///
/// **Problem solved:** The old enter-leave counter didn't know which direction
/// the angle should move. For shoulder flexion (increasing), the angle goes from
/// ~25° at rest up to ~160°+ in the target zone. For hip flexion (decreasing),
/// the angle drops from ~170° at rest down to ~100° in the target zone.
/// Without direction awareness, the counter couldn't reliably detect full rep cycles.
///
/// **How it works:**
///   1. Start in `.atRest` — angle is near `restAngle`
///   2. Detect `.moving` — angle leaves the rest threshold toward target
///   3. Detect `.inTarget` — angle enters the targetRange
///   4. Detect `.returning` — angle leaves targetRange heading back toward rest
///   5. When angle returns near rest → count 1 rep, go back to `.atRest`
///
/// For hold-based exercises (isometric), a rep is counted after holding in
/// the target zone for `requiredHoldTime` seconds.
public class SimpleRehabEngine: RehabEngine {
    private let targetAngle: Double     // Midpoint of target range
    private let tolerance: Double       // Half-width of target range
    private let requiredHoldTime: TimeInterval
    
    // Direction & rest
    private let repDirection: RepDirection
    private let restAngle: Double
    private let restThreshold: Double = 15.0  // Degrees from rest to count as "back at rest"
    
    // Phase state machine
    private var phase: RepPhase = .atRest
    private var repsCompleted: Int = 0
    
    // Hold timing (for isometric exercises)
    private var holdStartTime: Date?
    private var holdRepCounted: Bool = false
    
    /// Full initializer with direction and rest angle.
    public init(
        targetAngle: Double = 90.0,
        tolerance: Double = 10.0,
        requiredHoldTime: TimeInterval = 2.0,
        repDirection: RepDirection = .increasing,
        restAngle: Double = 90.0
    ) {
        self.targetAngle = targetAngle
        self.tolerance = tolerance
        self.requiredHoldTime = requiredHoldTime
        self.repDirection = repDirection
        self.restAngle = restAngle
    }
    
    public var currentRepState: RepState {
        let isHolding = phase == .inTarget && holdStartTime != nil
        return RepState(repsCompleted: repsCompleted, isHolding: isHolding, phase: phase)
    }
    
    public func update(proximal: SIMD3<Float>, joint: SIMD3<Float>, distal: SIMD3<Float>) -> AngleState {
        let degrees = AngleMath.computeJointAngle(proximal: proximal, joint: joint, distal: distal)
        
        // ── Compute zone ──
        let lowerBound = targetAngle - tolerance
        let upperBound = targetAngle + tolerance
        
        let zone: AngleZone
        if degrees < lowerBound {
            zone = .belowTarget
        } else if degrees > upperBound {
            zone = .aboveTarget
        } else {
            zone = .target
        }
        
        let inTarget = (zone == .target)
        let nearRest = abs(degrees - restAngle) < restThreshold
        
        // ── Direction-aware helper ──
        // For .increasing exercises: "toward target" means angle > restAngle
        // For .decreasing exercises: "toward target" means angle < restAngle
        let isMovingTowardTarget: Bool
        switch repDirection {
        case .increasing:
            isMovingTowardTarget = degrees > (restAngle + restThreshold)
        case .decreasing:
            isMovingTowardTarget = degrees < (restAngle - restThreshold)
        }
        
        // ── Phase state machine ──
        switch phase {
            
        case .atRest:
            // Waiting for user to start moving toward target
            if inTarget {
                // Jumped straight into target (can happen with wide zones)
                phase = .inTarget
                holdStartTime = Date()
                holdRepCounted = false
            } else if isMovingTowardTarget {
                phase = .moving
            }
            
        case .moving:
            // User has left rest and is heading toward target
            if inTarget {
                phase = .inTarget
                holdStartTime = Date()
                holdRepCounted = false
            } else if nearRest {
                // Went back to rest without reaching target — reset
                phase = .atRest
            }
            
        case .inTarget:
            if inTarget {
                // Still in target zone — check hold time for isometric exercises
                if !holdRepCounted, let startTime = holdStartTime,
                   Date().timeIntervalSince(startTime) >= requiredHoldTime {
                    repsCompleted += 1
                    holdRepCounted = true
                }
            } else {
                // Left the target zone
                holdStartTime = nil
                
                if !holdRepCounted {
                    // For non-hold exercises: count the rep when leaving target
                    // (the user reached target and is now returning)
                    repsCompleted += 1
                }
                
                if nearRest {
                    phase = .atRest
                } else {
                    phase = .returning
                }
                holdRepCounted = false
            }
            
        case .returning:
            // Heading back toward rest after hitting target
            if inTarget {
                // Went back into target — re-enter target phase
                phase = .inTarget
                holdStartTime = Date()
                holdRepCounted = false
            } else if nearRest {
                phase = .atRest
            }
        }
        
        return AngleState(degrees: degrees, zone: zone)
    }
}
