import Foundation
import simd

public enum AngleZone {
    case belowTarget
    case target
    case aboveTarget
}

public struct AngleState {
    public let degrees: Double
    public let zone: AngleZone
}

public struct RepState {
    public let repsCompleted: Int
    public let isHolding: Bool
}

public protocol RehabEngine {
    func update(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) -> AngleState
    var currentRepState: RepState { get }
}

public class SimpleRehabEngine: RehabEngine {
    private let targetAngle: Double
    private let tolerance: Double
    
    // Rep counting state
    private var repsCompleted: Int = 0
    private var isCurrentlyInTargetZone: Bool = false
    private var holdStartTime: Date?
    private let requiredHoldTime: TimeInterval
    
    public init(targetAngle: Double = 90.0, tolerance: Double = 10.0, requiredHoldTime: TimeInterval = 2.0) {
        self.targetAngle = targetAngle
        self.tolerance = tolerance
        self.requiredHoldTime = requiredHoldTime
    }
    
    public var currentRepState: RepState {
        return RepState(repsCompleted: repsCompleted, isHolding: holdStartTime != nil && isCurrentlyInTargetZone)
    }
    
    public func update(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) -> AngleState {
        let degrees = AngleMath.computeKneeFlexionAngle(hip: hip, knee: knee, ankle: ankle)
        
        let zone: AngleZone
        if degrees < (targetAngle - tolerance) {
            zone = .belowTarget
        } else if degrees > (targetAngle + tolerance) {
            zone = .aboveTarget
        } else {
            zone = .target
        }
        
        // Simple rep state machine
        if zone == .target {
            if holdStartTime == nil {
                // Entered the zone
                holdStartTime = Date()
                isCurrentlyInTargetZone = true
            } else if let startTime = holdStartTime, Date().timeIntervalSince(startTime) >= requiredHoldTime {
                // Held for the required time
                if isCurrentlyInTargetZone {
                    repsCompleted += 1
                    isCurrentlyInTargetZone = false // prevent double counting until they leave the zone
                }
            }
        } else {
            // Left the zone, reset
            holdStartTime = nil
            isCurrentlyInTargetZone = false // They can now start a new hold when they re-enter
        }
        
        return AngleState(degrees: degrees, zone: zone)
    }
}
