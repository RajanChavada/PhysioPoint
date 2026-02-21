
# Agent: Frontend UI & Navigation (PhysioPoint)

## Purpose

You own the **SwiftUI screens and navigation flow** that produce a clear 3-minute demo for judges.  
You do **not** implement AR math, storage internals, or business logic beyond simple wiring.

## Files You May Edit

- `app/Sources/PhysioPoint/ContentView.swift`
- `app/Sources/PhysioPoint/TriageView.swift`
- `app/Sources/PhysioPoint/ScheduleView.swift`
- `app/Sources/PhysioPoint/SessionIntroView.swift`
- `app/Sources/PhysioPoint/ExerciseARView.swift` (UI layer only; AR logic is in backend agent)
- `app/Sources/PhysioPoint/SummaryView.swift`
- Any additional `Views/` files dedicated to UI only.

You MAY read from:

- `models/*`
- `services/*`

But you MUST NOT put complex math, ARKit session management, or persistence logic inside views.

## Target 3-Minute Flow

Design and maintain a single "happy path" that a judge can complete in ≤ 3 minutes:

1. **ContentView**
   - Welcome screen.
   - Short 1–2 line explanation of PhysioPoint.
   - Button: “Start” → goes to TriageView.

2. **TriageView**
   - Ask: “Where is your main issue today?”
   - For demo: highlight **Knee** and one issue, e.g., “Hard to bend past 90°.”
   - Once selected, set `PhysioPointState.selectedCondition` and go to ScheduleView or SessionIntroView.

3. **ScheduleView** (optional but nice)
   - Show "Today's Plan": e.g., 3 × Heel Slides.
   - Provide a “Start Now” button that jumps straight to SessionIntroView for the chosen exercise.

4. **SessionIntroView**
   - Show the selected exercise name + a short description.
   - Simple diagram or text instructions.
   - Button: “Begin practice” → navigates to ExerciseARView.

5. **ExerciseARView**
   - Host the live session view:
     - Area showing camera/AR overlay.
     - Simple HUD: current angle, rep count, color zone indicator.
   - When reps are complete, present a button to finish and go to SummaryView.

6. **SummaryView**
   - Show metrics from `SessionMetrics`:
     - Reps completed.
     - Best angle achieved.
   - Include clear medical disclaimer text.

## Constraints

- All views must be **SwiftUI** and run in Swift Playgrounds on Mac.[CHALLENGE_REQUIREMENTS.md]
- No networking, no sign-in flows, no analytics.
- Copy must be in English only.
- UI should be understandable without reading long blocks of text — judges have ~3 minutes total.

## Style

- Use `PhysioPointState` (ObservableObject) as the app-wide state, injected via `.environmentObject` in `ContentView`.
- Keep views relatively small:
  - Avoid functions longer than ~100 lines.
  - Extract subviews for repeated UI components (e.g., cards, HUDs).
- Favor `NavigationStack` or simple view switching logic for navigation.

## Hand-offs

For AR angle/rep info, assume a backend interface like:

```swift
@ObservedObject var rehabSession: RehabSessionViewModel
// Provides: currentAngle, angleZone, repsCompleted, isGoalReached
```

```swift
@ObservedObject var rehabSession: RehabSessionViewModel
// Provides: currentAngle, angleZone, repsCompleted, isGoalReached
You display these values; you do not compute them.
```

***
