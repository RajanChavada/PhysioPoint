import Foundation
import simd

public enum AngleMath {
    /// Computes the angle in degrees between three points (hip, knee, ankle).
    /// The angle is computed at the middle point (knee).
    /// Returns 180 when the leg is perfectly straight.
    public static func computeKneeFlexionAngle(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) -> Double {
        // Vector A = knee to hip
        let vectorA = hip - knee
        // Vector B = knee to ankle
        let vectorB = ankle - knee
        
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
}
