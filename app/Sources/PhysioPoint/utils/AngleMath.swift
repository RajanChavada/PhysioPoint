import Foundation
import simd

public enum AngleMath {
    /// Computes the angle at the middle joint formed by proximal-joint-distal
    /// using the dot product of vectors from the joint.
    /// Returns degrees in range [0, 180]. (180 when limb is perfectly straight).
    /// Labels are for educational demo only — not medical prescriptions.
    public static func computeJointAngle(proximal: SIMD3<Float>, joint: SIMD3<Float>, distal: SIMD3<Float>) -> Double {
        let vectorA = proximal - joint
        let vectorB = distal - joint
        
        let lengthA = length(vectorA)
        let lengthB = length(vectorB)
        
        guard lengthA > 0 && lengthB > 0 else {
            return 0
        }
        
        let dotProduct = dot(vectorA, vectorB)
        let cosTheta = dotProduct / (lengthA * lengthB)
        
        // Clamp to [-1, 1] to avoid NaN due to floating point inaccuracies
        let clampedCosTheta = max(-1.0, min(1.0, cosTheta))
        
        let radians = acos(clampedCosTheta)
        let degrees = Double(radians) * 180.0 / .pi
        
        return degrees
    }

    // MARK: - Named Convenience Wrappers
    
    /// Knee flexion angle (hip → knee → ankle)
    static func kneeFlexion(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) -> Double {
        computeJointAngle(proximal: hip, joint: knee, distal: ankle)
    }
    
    /// Elbow flexion angle (shoulder → elbow → wrist)
    static func elbowFlexion(shoulder: SIMD3<Float>, elbow: SIMD3<Float>, wrist: SIMD3<Float>) -> Double {
        computeJointAngle(proximal: shoulder, joint: elbow, distal: wrist)
    }
    
    /// Shoulder angle (torso → shoulder → elbow)
    static func shoulderAngle(torso: SIMD3<Float>, shoulder: SIMD3<Float>, elbow: SIMD3<Float>) -> Double {
        computeJointAngle(proximal: torso, joint: shoulder, distal: elbow)
    }
    
    /// Hip angle (spine → hip → thigh)
    static func hipAngle(spine: SIMD3<Float>, hip: SIMD3<Float>, thigh: SIMD3<Float>) -> Double {
        computeJointAngle(proximal: spine, joint: hip, distal: thigh)
    }
}

// MARK: - Angle Smoother (Temporal Moving Average)

/// Applies a simple moving average to raw ARKit angle data to reduce frame-to-frame jitter.
/// Raw ARKit data jitters ±5° per frame; smoothing reduces this to ±1–2°.
/// Window size of 5 provides good balance between responsiveness and stability.
public final class AngleSmoother {
    private var buffer: [Double] = []
    private let windowSize: Int

    public init(windowSize: Int = 5) {
        self.windowSize = windowSize
    }

    /// Feed a new raw angle value and get back the smoothed result.
    public func smooth(_ newValue: Double) -> Double {
        buffer.append(newValue)
        if buffer.count > windowSize {
            buffer.removeFirst()
        }
        return buffer.reduce(0, +) / Double(buffer.count)
    }

    /// Reset the buffer (e.g., when switching exercises or body lost).
    public func reset() {
        buffer.removeAll()
    }
}
