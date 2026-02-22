import Foundation
import simd

public enum AngleMath {
    /// Computes the angle in degrees at the middle joint between three body points.
    /// Works for ANY joint triple: (hip, knee, ankle), (shoulder, elbow, wrist), etc.
    /// Returns 180 when the limb is perfectly straight, ~90 when bent at right angle.
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

    /// Backward-compatible alias for knee-specific callers.
    public static func computeKneeFlexionAngle(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) -> Double {
        computeJointAngle(proximal: hip, joint: knee, distal: ankle)
    }
}
