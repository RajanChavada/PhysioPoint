# Agent: Architecture & Models (PhysioPoint)

## Purpose

You own the **data structures and high-level app state** for PhysioPoint.  
Your job is to define clean, simple models and state containers that all other agents depend on.

You DO NOT implement UI layout, AR logic, or platform-specific storage here.

## Files You May Edit

- `app/Sources/PhysioPoint/models/ConditionModel.swift`
- `app/Sources/PhysioPoint/models/ExerciseModel.swift`
- `app/Sources/PhysioPoint/models/SessionMetrics.swift`
- `app/Sources/PhysioPoint/AppState.swift` (or similar global state)
- Type definitions in `ContentView.swift` **only** when strictly necessary to wire state.

## Responsibilities

1. **Condition model**

Represents high-level issues the user picks (for demo, focus on knee):

```swift
struct Condition: Identifiable, Codable {
    let id: String
    let name: String            // "Knee – Hard to bend"
    let bodyArea: BodyArea      // .knee, .elbow, etc.
    let description: String
    let recommendedExercises: [ExerciseID]
}
```
## Exercise model

Represents one rehab exercise (e.g., Heel Slide):

```swift
struct Exercise: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let holdSeconds: Int
    let targetAngleRange: ClosedRange<Double>? // e.g. 80...95
    let reps: Int
    let phase: RehabPhase  // .early, .loading, .functional
}
```
## Session metrics

Represents the result of a single practice session:

```swift
struct SessionMetrics: Identifiable, Codable {
    let id: UUID
    let exerciseID: Exercise.ID
    let timestamp: Date
    let repsCompleted: Int
    let bestAngle: Double?
}
App state container
```
## Single source of truth for current flow:

```swift
final class PhysioPointState: ObservableObject {
    @Published var selectedCondition: Condition?
    @Published var selectedExercise: Exercise?
    @Published var currentMetrics: SessionMetrics?
    // Add fields as needed, but keep this class small and focused.
}
```
## Constraints
All data must be local and lightweight to keep the ZIP under 25 MB.[CHALLENGE_REQUIREMENTS.md]

No networking, no external databases.[CHALLENGE_REQUIREMENTS.md]

Models must be simple enough to serialize via Codable if storage is added later.

Numeric thresholds (angles, reps, times) are educational examples, not medical prescriptions.

Style
4-space indentation.

One type per file where reasonable.

UpperCamelCase for types, lowerCamelCase for properties and functions.