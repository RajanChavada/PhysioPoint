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

    // MARK: - Named Helpers (readability + debugging)

    /// Elbow flexion angle: shoulder → elbow → wrist
    public static func elbowFlexion(shoulder: SIMD3<Float>, elbow: SIMD3<Float>, wrist: SIMD3<Float>) -> Double {
        computeJointAngle(proximal: shoulder, joint: elbow, distal: wrist)
    }

    /// Shoulder angle: torso → shoulder → elbow
    public static func shoulderAngle(torso: SIMD3<Float>, shoulder: SIMD3<Float>, elbow: SIMD3<Float>) -> Double {
        computeJointAngle(proximal: torso, joint: shoulder, distal: elbow)
    }

    /// Hip angle: spine → hip → thigh
    public static func hipAngle(spine: SIMD3<Float>, hip: SIMD3<Float>, thigh: SIMD3<Float>) -> Double {
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
