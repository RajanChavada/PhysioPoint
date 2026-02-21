

# Agent: Backend – Rehab Engine & AR Logic (PhysioPoint)

## Purpose

You implement the **movement analysis** core of PhysioPoint: angle math, simple rep detection, and optional AR body tracking.

You do NOT design UI layout or navigation.

## Files You May Edit

- `app/Sources/PhysioPoint/services/RehabEngine.swift`
- `app/Sources/PhysioPoint/utils/AngleMath.swift`
- AR-related parts of `ExerciseARView.swift` **only** (e.g., ARViewRepresentable + Coordinator).

## Responsibilities

1. **Angle math**

Implement pure Swift helpers to compute knee flexion angle from three joint positions:

```swift
struct AngleState {
    let degrees: Double
    let zone: AngleZone
}

enum AngleZone {
    case belowTarget
    case target
    case aboveTarget
}
Compute:

Vectors:

A = hip → knee

B = knee → ankle

Angle:

theta = arccos((A • B) / (|A||B|)) in degrees.

RehabEngine protocol

Define a simple engine interface:

swift
protocol RehabEngine {
    func update(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) -> AngleState
}
Add optional methods for rep detection:

swift
struct RepState {
    let repsCompleted: Int
    let isHolding: Bool
}
AR integration (optional but desired)

If the device supports ARBodyTrackingConfiguration, use ARBodyAnchor to fetch joint transforms.

Extract hip, knee, ankle positions and feed into RehabEngine.

If AR body tracking is not available, provide a fallback:

E.g., simulated joint positions driven by a slider for demo purposes.

Constraints
100% offline; no external ML models downloaded at runtime.

Use only ARKit/RealityKit frameworks available in Swift Playgrounds on Mac.

Keep logic lightweight to avoid bloating the project size.

All thresholds and angles must be clearly labeled “for educational demo only,” not medical prescriptions.

Style
Put pure math into utils/AngleMath.swift as static functions.

Keep AR session delegate code contained in a Coordinator class inside ExerciseARView.

Minimize state duplication; expose a single ObservableObject (e.g., RehabSessionViewModel) for the UI to observe.