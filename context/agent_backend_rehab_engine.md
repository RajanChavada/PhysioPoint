

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

```swift
protocol RehabEngine {
    func update(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) -> AngleState
}
```
Add optional methods for rep detection:

```swift
struct RepState {
    let repsCompleted: Int
    let isHolding: Bool
}
```
## AR integration 

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


-- 

## Feature roadmap -> Scheudling the users sessions 

- We want to basically allow the user to select their body area then select the number of times per a day they want to do the exercises, then after they do this we reccomend various ones for different times of the day, where the user can adjust these 


Here are some one shot examples of some implementaions to help you get started on the scheduling feature.

- ensure that the schedule is saved for the day and then the user can mark each session as complete once they do it, we can also track the time they completed it to show trends over time in the summary page.

- note the constraint that we must not go over 25mb in total for the project, so we should keep the data models and storage lightweight (e.g. using UserDefaults with Codable structs, no heavy databases).

### models/DailySchedule.swift:

```swift
import Foundation

struct ScheduledSession: Identifiable, Codable {
    let id: UUID
    let exerciseID: String
    let label: String          // "Morning", "Afternoon", "Evening"
    let scheduledHour: Int     // 24hr, e.g. 8, 13, 18
    var isCompleted: Bool
    var completedAt: Date?
}

struct DailySchedule: Codable {
    let conditionID: String
    var sessions: [ScheduledSession]
    let createdDate: Date

    static func defaultSchedule(for condition: Condition) -> DailySchedule {
        let firstExerciseID = condition.recommendedExerciseIDs.first ?? ""
        return DailySchedule(
            conditionID: condition.id,
            sessions: [
                ScheduledSession(id: UUID(), exerciseID: firstExerciseID,
                                 label: "Morning",   scheduledHour: 8,
                                 isCompleted: false, completedAt: nil),
                ScheduledSession(id: UUID(), exerciseID: firstExerciseID,
                                 label: "Afternoon", scheduledHour: 13,
                                 isCompleted: false, completedAt: nil),
                ScheduledSession(id: UUID(), exerciseID: firstExerciseID,
                                 label: "Evening",   scheduledHour: 18,
                                 isCompleted: false, completedAt: nil)
            ],
            createdDate: Date()
        )
    }
}
```
## Storage service
### services/StorageService.swift:

```swift
import Foundation

final class StorageService: ObservableObject {
    private let scheduleKey = "pp_daily_schedule"
    private let metricsKey  = "pp_session_metrics"

    @Published var schedule: DailySchedule?

    // MARK: Schedule
    func saveSchedule(_ schedule: DailySchedule) {
        self.schedule = schedule
        if let data = try? JSONEncoder().encode(schedule) {
            UserDefaults.standard.set(data, forKey: scheduleKey)
        }
    }

    func loadSchedule() -> DailySchedule? {
        guard let data = UserDefaults.standard.data(forKey: scheduleKey),
              let decoded = try? JSONDecoder().decode(DailySchedule.self, from: data)
        else { return nil }
        return decoded
    }

    func markSessionComplete(_ sessionID: UUID) {
        guard var current = loadSchedule() else { return }
        if let idx = current.sessions.firstIndex(where: { $0.id == sessionID }) {
            current.sessions[idx].isCompleted = true
            current.sessions[idx].completedAt = Date()
        }
        saveSchedule(current)
    }

    // MARK: Metrics history (last 7 sessions)
    func saveMetrics(_ metrics: SessionMetrics) {
        var history = loadMetricsHistory()
        history.insert(metrics, at: 0)
        history = Array(history.prefix(7))  // keep last 7 only
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: metricsKey)
        }
    }

    func loadMetricsHistory() -> [SessionMetrics] {
        guard let data = UserDefaults.standard.data(forKey: metricsKey),
              let decoded = try? JSONDecoder().decode([SessionMetrics].self, from: data)
        else { return [] }
        return decoded
    }
}
```
## Schedule setup UI (after triage)
### ScheduleView.swift:

```swift
import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService
    @State private var sessions: [ScheduledSession] = []
    @State private var hours: [Int] = [8, 13, 18]

    var body: some View {
        VStack(spacing: 24) {
            Text("Set Your Daily Schedule")
                .font(.title2).bold()
            Text("Choose when you'll do each session today.")
                .font(.subheadline).foregroundColor(.secondary)

            ForEach(sessions.indices, id: \.self) { i in
                HStack {
                    Label(sessions[i].label, systemImage: labelIcon(for: i))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Picker("", selection: $hours[i]) {
                        ForEach(Array(stride(from: 6, through: 22, by: 1)), id: \.self) { h in
                            Text(formattedHour(h)).tag(h)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
            }
            .padding(.horizontal)

            Spacer()

            Button("Save Schedule") {
                guard let condition = appState.selectedCondition else { return }
                var schedule = DailySchedule.defaultSchedule(for: condition)
                for i in schedule.sessions.indices {
                    schedule.sessions[i].scheduledHour = hours[i]
                }
                storage.saveSchedule(schedule)
                appState.navigationPath.append("Home")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
        .onAppear {
            if let condition = appState.selectedCondition {
                sessions = DailySchedule.defaultSchedule(for: condition).sessions
            }
        }
    }

    private func labelIcon(for index: Int) -> String {
        ["sunrise", "sun.max", "sunset"][index]
    }

    private func formattedHour(_ h: Int) -> String {
        let suffix = h < 12 ? "AM" : "PM"
        let display = h > 12 ? h - 12 : h
        return "\(display):00 \(suffix)"
    }
}
```

- Notes on this feature implementation:
- The `ScheduleView` allows users to set their preferred times for each session (morning, afternoon, evening) using a simple `Picker`.
- The schedule is saved to `UserDefaults` via the `StorageService`, and the app
state is updated to navigate back to the Home screen after saving.
- The `DailySchedule` model includes a static method to generate a default schedule based on the
selected condition, which can be customized by the user before saving.


-- 

## Feature roadmap -> Session finish storage 
- After the user finishes a session we want to store the fact they completed 1/3 of their workouts today 
- update the scheudle screen allow them to revisit an exercise even if they completed it 
- AFter the user enters the summary page we need to update the scheudle for the day to mark that session as complete, we also want to store this 

Here are some examples and guidelines for you to help implement the feature: 

## 1. Track which slot is currently being exercised
AppState needs to know which slot ID is active so SummaryView can mark it complete:

```swift
// AppState.swift — add these two properties
@Published var activeSlotID: UUID?       // set when user taps "Start" on a slot
@Published var latestMetrics: SessionMetrics?
```
In ScheduleView / HomeView, when user taps Start Now on a slot:

```swift
Button("Start Now") {
    appState.activeSlotID = slot.id          // ← record which slot
    appState.selectedExercise = exercise
    appState.navigationPath.append("Session")
}
```
## 2. Mark slot complete in SummaryView
SummaryView is where the session ends — this is the correct place to call markSlotComplete. Call it once on appear (not on a button tap, so it always fires regardless of outcome):

```swift
// SummaryView.swift
struct SummaryView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // ... your existing metrics UI ...

                // Redo button
                if let slotID = appState.activeSlotID {
                    Button {
                        storage.unmarkSlotComplete(slotID)   // ← allow redo
                        appState.navigationPath.removeLast() // go back to session
                    } label: {
                        Label("Redo this session", systemImage: "arrow.counterclockwise")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            // Always mark complete when summary appears
            if let slotID = appState.activeSlotID {
                storage.markSlotComplete(slotID)
            }
        }
    }
}
```
## 3. Add unmarkSlotComplete to StorageService
So the "Redo" button can reset a slot:

```swift
// StorageService.swift — add this method
func markSlotComplete(_ id: UUID) {
    guard var plan = dailyPlan else { return }
    if let idx = plan.slots.firstIndex(where: { $0.id == id }) {
        plan.slots[idx].isCompleted = true
        plan.slots[idx].completedAt = Date()
    }
    saveDailyPlan(plan)
}

func unmarkSlotComplete(_ id: UUID) {
    guard var plan = dailyPlan else { return }
    if let idx = plan.slots.firstIndex(where: { $0.id == id }) {
        plan.slots[idx].isCompleted = false
        plan.slots[idx].completedAt = nil
    }
    saveDailyPlan(plan)
}

private func saveDailyPlan(_ plan: DailyPlan) {
    self.dailyPlan = plan    // triggers @Published → all views update
    if let data = try? JSONEncoder().encode(plan) {
        UserDefaults.standard.set(data, forKey: dailyPlanKey)
    }
}
```
Make sure dailyPlan is @Published:

```swift
final class StorageService: ObservableObject {
    @Published var dailyPlan: DailyPlan?
    private let dailyPlanKey = "pp_daily_plan"

    init() {
        self.dailyPlan = loadDailyPlan()
    }
}
```
## 4. Fix SummaryView ring to read from storage
Replace any appState-based ring logic with:

```swift
// Inside SummaryView body
private var completedCount: Int {
    storage.dailyPlan?.slots.filter(\.isCompleted).count ?? 0
}

private var totalCount: Int {
    storage.dailyPlan?.slots.count ?? 3
}

// Then in your VStack:
DailyProgressRing(completed: completedCount, total: totalCount)

// Completion banner when all done
if completedCount == totalCount {
    Label("All sessions done today! 🎉", systemImage: "star.fill")
        .font(.headline)
        .foregroundColor(.teal)
        .transition(.scale.combined(with: .opacity))
}
```
## 5. HomeView: show today's slots
This is your dashboard. It should load from storage.dailyPlan and reflect live state:

```swift
struct HomeView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Plan")
                        .font(.title2.bold())
                    Text(Date(), style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Progress ring
                if let plan = storage.dailyPlan {
                    let done = plan.slots.filter(\.isCompleted).count
                    DailyProgressRing(completed: done, total: plan.slots.count)
                }

                // Slot cards
                if let plan = storage.dailyPlan {
                    ForEach(plan.slots) { slot in
                        SlotCard(slot: slot) {
                            // Start this slot
                            appState.activeSlotID = slot.id
                            if let ex = ExerciseLibrary.exercise(withID: slot.exerciseID) {
                                appState.selectedExercise = ex
                                appState.navigationPath.append("Session")
                            }
                        }
                    }
                    .padding(.horizontal)
                } else {
                    // No schedule set yet
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No schedule set yet.")
                            .foregroundColor(.secondary)
                        Button("Set Up Schedule") {
                            appState.navigationPath.append("Triage")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.top, 40)
                }
            }
            .padding(.vertical)
        }
    }
}
```
## 6. SlotCard component
Reusable card per slot, with visual state for completed vs upcoming:

```swift
struct SlotCard: View {
    let slot: ScheduledSlot
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 16) {

            // Time + label
            VStack(alignment: .leading, spacing: 4) {
                Text(slot.label)
                    .font(.headline)
                Text(formattedHour(slot.scheduledHour))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 90, alignment: .leading)

            // Exercise name
            VStack(alignment: .leading, spacing: 4) {
                Text(ExerciseLibrary.exercise(withID: slot.exerciseID)?.name ?? "Exercise")
                    .font(.subheadline)
                if slot.isCompleted, let completedAt = slot.completedAt {
                    Text("Done at \(completedAt, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.teal)
                }
            }

            Spacer()

            // Status / action
            if slot.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.teal)
                    .font(.title2)
            } else {
                Button("Start", action: onStart)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(16)
        .background(slot.isCompleted
                    ? Color.teal.opacity(0.07)
                    : Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(slot.isCompleted
                        ? Color.teal.opacity(0.3)
                        : Color.gray.opacity(0.1),
                        lineWidth: 1)
        )
        .animation(.spring(response: 0.3), value: slot.isCompleted)
    }

    private func formattedHour(_ h: Int) -> String {
        let suffix = h < 12 ? "AM" : "PM"
        let display = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return "\(display):00 \(suffix)"
    }
}
```
Full wired flow summary
```text
HomeView (shows today's slots from storage.dailyPlan)
  ↓ user taps "Start" on a slot
  → sets appState.activeSlotID + selectedExercise
  → navigates to SessionIntroView → ExerciseARView
  → navigates to SummaryView
  → .onAppear: storage.markSlotComplete(appState.activeSlotID)
  → storage.dailyPlan @Published fires → HomeView ring + cards update live
  → user can tap "Redo" → storage.unmarkSlotComplete() → slot resets
  → 3/3 done → banner appears in SummaryView
  ```


  -- 

## Feature roadmap -> 5 body parts x 3 categories x 3 exercises 
- We want to expand the number of conditions and exercises in the app to cover 5 body areas (knee, elbow, hip/back, ankle, shoulder) with 3 categories each (general pain, dislocation therapy, pain bending/twisting). Each category will have 3 recommended exercises.
- This will allow us to provide more personalized and relevant exercise recommendations based on the user's specific condition and body area.
- We will need to update our data models to accommodate the new categories and exercises, and ensure that the UI can display this expanded information effectively.
- We should also consider how to keep the app lightweight and ensure that we do not exceed our 25mb size constraint while adding this new content.
- Here are some examples and guidelines for you to help implement this feature:


## 1. Update Condition model first
Add a category layer between BodyArea and Exercise:

```swift
// models/ConditionModel.swift

struct Condition: Identifiable, Hashable, Codable {
    let id: String
    let name: String                        // "Dislocation Therapy"
    let bodyArea: BodyArea
    let category: ConditionCategory
    let description: String
    let recommendedExerciseIDs: [String]    // maps to Exercise.name slugs

    static func conditions(for area: BodyArea) -> [Condition] {
        ConditionLibrary.all.filter { $0.bodyArea == area }
    }
}

enum ConditionCategory: String, Codable, CaseIterable {
    case generalPain        = "General Pain"
    case dislocationTherapy = "Dislocation Therapy"
    case painBending        = "Pain Bending"
    case troubleTwisting    = "Trouble Twisting"
    case twistedRolled      = "Twisted / Rolled"
    case painRotating       = "Pain in Rotating"
    case painLifting        = "Pain Lifting Arm"
    case dislocatedShoulder = "Dislocated Shoulder"

    var systemImage: String {
        switch self {
        case .generalPain:        return "bandage"
        case .dislocationTherapy: return "bolt.heart"
        case .painBending:        return "arrow.up.and.down"
        case .troubleTwisting:    return "arrow.2.circlepath"
        case .twistedRolled:      return "rotate.right"
        case .painRotating:       return "circle.dotted"
        case .painLifting:        return "arrow.up.circle"
        case .dislocatedShoulder: return "figure.arms.open"
        }
    }
}
```
## 2. Full Condition Library
services/ConditionLibrary.swift:

```swift
enum ConditionLibrary {
    static let all: [Condition] = knee + elbow + hip + ankle + shoulder

    // MARK: Knee
    static let knee: [Condition] = [
        Condition(
            id: "knee_general_pain",
            name: "General Pain",
            bodyArea: .knee,
            category: .generalPain,
            description: "General knee discomfort, stiffness, or aching without a specific injury.",
            recommendedExerciseIDs: ["quad_sets", "short_arc_quads", "seated_knee_extension"]
        ),
        Condition(
            id: "knee_dislocation",
            name: "Dislocation Therapy",
            bodyArea: .knee,
            category: .dislocationTherapy,
            description: "Recovery after a kneecap dislocation — rebuilding strength and stability.",
            recommendedExerciseIDs: ["straight_leg_raises", "heel_slides", "terminal_knee_extension"]
        ),
        Condition(
            id: "knee_pain_bending",
            name: "Pain Bending",
            bodyArea: .knee,
            category: .painBending,
            description: "Difficulty or pain when bending the knee past 90°.",
            recommendedExerciseIDs: ["heel_slides", "seated_knee_flexion", "prone_knee_flexion"]
        ),
    ]

    // MARK: Elbow
    static let elbow: [Condition] = [
        Condition(
            id: "elbow_general_pain",
            name: "General Pain",
            bodyArea: .elbow,
            category: .generalPain,
            description: "General elbow aching or stiffness from overuse or minor strain.",
            recommendedExerciseIDs: ["elbow_flexion_extension", "wrist_flexor_stretch", "towel_squeeze"]
        ),
        Condition(
            id: "elbow_dislocation",
            name: "Dislocation Therapy",
            bodyArea: .elbow,
            category: .dislocationTherapy,
            description: "Gentle recovery after an elbow dislocation — restore motion and stability.",
            recommendedExerciseIDs: ["active_elbow_flexion", "forearm_rotation", "gravity_elbow_extension"]
        ),
        Condition(
            id: "elbow_pain_bending",
            name: "Pain Bending",
            bodyArea: .elbow,
            category: .painBending,
            description: "Pain or resistance when bending or straightening the elbow.",
            recommendedExerciseIDs: ["elbow_flexion_extension", "elbow_extension_stretch", "forearm_rotation"]
        ),
    ]

    // MARK: Hip / Back
    static let hip: [Condition] = [
        Condition(
            id: "hip_general_pain",
            name: "General Pain",
            bodyArea: .hip,
            category: .generalPain,
            description: "General hip or lower back aching, stiffness, or weakness.",
            recommendedExerciseIDs: ["clamshells", "glute_bridges", "hip_flexor_stretch"]
        ),
        Condition(
            id: "hip_trouble_twisting",
            name: "Trouble Twisting",
            bodyArea: .hip,
            category: .troubleTwisting,
            description: "Pain or restriction when rotating or twisting through the hips or lower back.",
            recommendedExerciseIDs: ["seated_hip_rotation", "supine_hip_rotation", "cat_cow"]
        ),
        Condition(
            id: "hip_pain_bending",
            name: "Pain in Bending",
            bodyArea: .hip,
            category: .painBending,
            description: "Difficulty bending at the hip — common in older adults and post-surgery recovery.",
            recommendedExerciseIDs: ["hip_hinge", "standing_hip_flexion", "pelvic_tilt"]
        ),
    ]

    // MARK: Ankle
    static let ankle: [Condition] = [
        Condition(
            id: "ankle_general_pain",
            name: "General Pain",
            bodyArea: .ankle,
            category: .generalPain,
            description: "General ankle stiffness, aching, or reduced mobility.",
            recommendedExerciseIDs: ["ankle_alphabet", "ankle_circles", "seated_calf_raises"]
        ),
        Condition(
            id: "ankle_twisted",
            name: "Twisted / Rolled Ankle",
            bodyArea: .ankle,
            category: .twistedRolled,
            description: "Recovery after a lateral ankle sprain — restore mobility and balance.",
            recommendedExerciseIDs: ["towel_scrunches", "single_leg_balance", "resistance_dorsiflexion"]
        ),
        Condition(
            id: "ankle_pain_rotating",
            name: "Pain in Rotating",
            bodyArea: .ankle,
            category: .painRotating,
            description: "Pain when rotating the ankle — common after fracture or severe sprain.",
            recommendedExerciseIDs: ["ankle_pumps", "seated_toe_raises", "seated_heel_raises"]
        ),
    ]

    // MARK: Shoulder
    static let shoulder: [Condition] = [
        Condition(
            id: "shoulder_general_pain",
            name: "General Pain",
            bodyArea: .shoulder,
            category: .generalPain,
            description: "General shoulder aching, stiffness, or reduced range of motion.",
            recommendedExerciseIDs: ["pendulum_swings", "shoulder_rolls", "cross_body_stretch"]
        ),
        Condition(
            id: "shoulder_dislocation",
            name: "Dislocated Shoulder",
            bodyArea: .shoulder,
            category: .dislocatedShoulder,
            description: "Rebuilding stability and strength after a shoulder dislocation.",
            recommendedExerciseIDs: ["sleeper_stretch", "wall_slides_shoulder", "external_rotation"]
        ),
        Condition(
            id: "shoulder_pain_lifting",
            name: "Pain Lifting Arm",
            bodyArea: .shoulder,
            category: .painLifting,
            description: "Pain or weakness when raising the arm — common in rotator cuff issues.",
            recommendedExerciseIDs: ["scapular_setting", "supine_shoulder_flexion", "side_lying_external_rotation"]
        ),
    ]
}
```
## 3. Full Exercise Library
services/ExerciseLibrary.swift:

```swift
extension Exercise {

    // MARK: ── KNEE ──────────────────────────────────────────

    // General pain
    static let quad_sets = Exercise(
        name: "Quad Sets", bodyArea: .knee,
        visualDescription: "Tighten the thigh muscle of the straight leg, pressing the back of the knee toward the floor.",
        targetAngleRange: 0...5, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie flat", instruction: "Lie on your back with the affected leg straight."),
            ExerciseStep(stepNumber: 2, title: "Squeeze", instruction: "Tighten your thigh, pressing the back of the knee gently into the floor."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 5 seconds, then relax. Repeat 10 times."),
        ],
        caregiverTip: "Place your hand under the knee — you should feel it press down when the quads engage."
    )

    static let short_arc_quads = Exercise(
        name: "Short Arc Quads", bodyArea: .knee,
        visualDescription: "Lie flat with a rolled towel under the knee. Straighten the leg fully, hold, then lower.",
        targetAngleRange: 0...5, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Lie flat. Place a rolled towel (15 cm) under the knee."),
            ExerciseStep(stepNumber: 2, title: "Lift", instruction: "Tighten the thigh and raise the heel until the leg is fully straight."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 5 seconds, then slowly lower. Repeat 10 times."),
        ],
        caregiverTip: "Ensure the towel stays still. The thigh should not lift — only the lower leg moves."
    )

    static let seated_knee_extension = Exercise(
        name: "Seated Knee Extension", bodyArea: .knee,
        visualDescription: "Sit upright in a chair. Slowly kick the leg out straight, hold, then lower.",
        targetAngleRange: 0...5, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit upright", instruction: "Sit in a sturdy chair, feet flat on the floor."),
            ExerciseStep(stepNumber: 2, title: "Extend", instruction: "Slowly raise the affected leg until it's as straight as possible."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 3 seconds, then lower slowly. Repeat 10 times."),
        ],
        caregiverTip: "Watch for knee locking. A straight but not hyper-extended position is ideal."
    )

    // Dislocation therapy
    static let terminal_knee_extension = Exercise(
        name: "Terminal Knee Extension", bodyArea: .knee,
        visualDescription: "Stand with a resistance band behind the knee. Push the knee straight against the band's resistance.",
        targetAngleRange: 0...5, holdSeconds: 3, reps: 12,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Loop a band around a fixed object at knee height and step into it."),
            ExerciseStep(stepNumber: 2, title: "Bend slightly", instruction: "Stand with a slight knee bend, band pulling from behind."),
            ExerciseStep(stepNumber: 3, title: "Straighten", instruction: "Push the knee straight against the band. Hold 3 s, then release. Repeat 12 times."),
        ],
        caregiverTip: "This rebuilds the VMO (inner quad) — critical after dislocation. Ensure the knee tracks over the second toe."
    )

    // Pain bending
    static let prone_knee_flexion = Exercise(
        name: "Prone Knee Flexion", bodyArea: .knee,
        visualDescription: "Lie face-down. Slowly bend the knee, bringing the heel toward your glutes.",
        targetAngleRange: 80...120, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Lie face-down on a flat surface with legs straight."),
            ExerciseStep(stepNumber: 2, title: "Bend", instruction: "Slowly bend the affected knee, raising the heel toward your glutes."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold at your comfortable limit for 3 seconds, then lower slowly."),
        ],
        caregiverTip: "You can gently assist the heel upward — never force past pain."
    )

    // MARK: ── ELBOW ──────────────────────────────────────────

    static let wrist_flexor_stretch = Exercise(
        name: "Wrist Flexor Stretch", bodyArea: .elbow,
        visualDescription: "Extend your arm palm-up. Use the other hand to gently press the fingers down.",
        targetAngleRange: 0...30, holdSeconds: 20, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Extend arm", instruction: "Hold your arm out straight, palm facing up."),
            ExerciseStep(stepNumber: 2, title: "Press down", instruction: "Use the other hand to press fingers gently downward."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 20 seconds. You should feel a stretch in the forearm."),
        ],
        caregiverTip: "This should be a gentle pull, not pain. Stop if tingling or sharp pain occurs."
    )

    static let towel_squeeze = Exercise(
        name: "Towel Squeeze", bodyArea: .elbow,
        visualDescription: "Hold a rolled towel in your hand. Squeeze firmly, hold, then release.",
        targetAngleRange: 0...10, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Grip", instruction: "Hold a rolled towel loosely in the affected hand."),
            ExerciseStep(stepNumber: 2, title: "Squeeze", instruction: "Squeeze the towel as firmly as comfortable."),
            ExerciseStep(stepNumber: 3, title: "Hold & release", instruction: "Hold 5 seconds, then fully release. Repeat 10 times."),
        ],
        caregiverTip: "Observe the forearm muscles. They should engage visibly. This rebuilds grip strength around the elbow."
    )

    static let active_elbow_flexion = Exercise(
        name: "Active Elbow Flexion", bodyArea: .elbow,
        visualDescription: "Sit upright. Slowly bend and straighten the elbow through full comfortable range.",
        targetAngleRange: 10...130, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Start", instruction: "Sit with your arm at your side, palm facing forward."),
            ExerciseStep(stepNumber: 2, title: "Bend", instruction: "Slowly bend the elbow, bringing your hand toward your shoulder."),
            ExerciseStep(stepNumber: 3, title: "Extend & repeat", instruction: "Slowly straighten back to start. Hold each end position 3 seconds."),
        ],
        caregiverTip: "After a dislocation, watch for hesitation near 90°. Encourage slow, controlled movement."
    )

    static let forearm_rotation = Exercise(
        name: "Forearm Rotation", bodyArea: .elbow,
        visualDescription: "Elbow at 90°, rotate the forearm palm-up then palm-down in a slow, controlled motion.",
        targetAngleRange: 0...80, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Sit with your elbow bent 90° at your side, thumb pointing up."),
            ExerciseStep(stepNumber: 2, title: "Rotate palm up", instruction: "Turn the palm to face the ceiling (supination). Hold 3 seconds."),
            ExerciseStep(stepNumber: 3, title: "Rotate palm down", instruction: "Turn the palm to face the floor (pronation). Hold 3 seconds. Repeat."),
        ],
        caregiverTip: "Keep the elbow tucked at the side throughout — don't let the upper arm swing."
    )

    static let gravity_elbow_extension = Exercise(
        name: "Gravity-Assisted Extension", bodyArea: .elbow,
        visualDescription: "Lie face-up. Let the forearm hang off the edge of a surface, allowing gravity to gently straighten the elbow.",
        targetAngleRange: 0...15, holdSeconds: 10, reps: 5,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Position", instruction: "Lie on your back. Rest the upper arm on a firm surface so the elbow hangs over the edge."),
            ExerciseStep(stepNumber: 2, title: "Relax", instruction: "Let gravity gently pull the forearm down to straighten the elbow."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Stay relaxed for 10 seconds. Repeat 5 times."),
        ],
        caregiverTip: "Do not push or force. Gravity does the work — muscle tension will block the stretch."
    )

    static let elbow_extension_stretch = Exercise(
        name: "Elbow Extension Stretch", bodyArea: .elbow,
        visualDescription: "Support the upper arm and gently press the forearm down to straighten the elbow.",
        targetAngleRange: 0...10, holdSeconds: 15, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Support arm", instruction: "Hold the upper arm steady with your other hand."),
            ExerciseStep(stepNumber: 2, title: "Press gently", instruction: "Use gentle pressure to push the forearm toward a straight position."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 15 seconds at the comfortable limit. Repeat 3 times."),
        ],
        caregiverTip: "Apply gentle, sustained pressure — not a quick push. This helps restore terminal extension after dislocation."
    )

    // MARK: ── HIP / BACK ──────────────────────────────────────────

    static let glute_bridges = Exercise(
        name: "Glute Bridges", bodyArea: .hip,
        visualDescription: "Lie on your back, knees bent. Push through the heels to lift the hips off the floor.",
        targetAngleRange: 20...45, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie back", instruction: "Lie on your back, knees bent at 90°, feet flat and hip-width apart."),
            ExerciseStep(stepNumber: 2, title: "Lift", instruction: "Push through heels to raise hips until shoulders, hips, and knees form a line."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 3 seconds at the top, then slowly lower. Repeat 10 times."),
        ],
        caregiverTip: "Place your hand at the patient's lower back to confirm they're lifting off the floor. No excessive arching."
    )

    static let hip_flexor_stretch = Exercise(
        name: "Hip Flexor Stretch", bodyArea: .hip,
        visualDescription: "Kneel on one knee. Gently push the hips forward to stretch the front of the hip.",
        targetAngleRange: 10...30, holdSeconds: 20, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Kneeling lunge", instruction: "Kneel on the affected knee, other foot forward."),
            ExerciseStep(stepNumber: 2, title: "Shift forward", instruction: "Shift weight forward gently until you feel a stretch in the front of the hip."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 20 seconds, then return. Repeat 3 times each side."),
        ],
        caregiverTip: "Support the patient's hands if balance is an issue. Avoid excessive anterior tilt of the pelvis."
    )

    static let seated_hip_rotation = Exercise(
        name: "Seated Hip Rotation", bodyArea: .hip,
        visualDescription: "Sit upright in a chair. Cross one ankle over the opposite knee and gently press the knee down.",
        targetAngleRange: 20...40, holdSeconds: 20, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Cross leg", instruction: "Sit upright. Cross the affected ankle over the opposite knee."),
            ExerciseStep(stepNumber: 2, title: "Press down", instruction: "Gently press the raised knee toward the floor to feel a hip stretch."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 20 seconds. Repeat 3 times each side."),
        ],
        caregiverTip: "Ensure the patient stays upright — leaning forward deepens the stretch safely."
    )

    static let supine_hip_rotation = Exercise(
        name: "Supine Hip Rotation", bodyArea: .hip,
        visualDescription: "Lie on your back with knees bent. Slowly drop both knees to one side, hold, then the other.",
        targetAngleRange: 20...40, holdSeconds: 10, reps: 5,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie back", instruction: "Lie on your back, knees bent, feet flat on the floor."),
            ExerciseStep(stepNumber: 2, title: "Drop knees", instruction: "Slowly let both knees fall to one side, keeping shoulders flat."),
            ExerciseStep(stepNumber: 3, title: "Hold & switch", instruction: "Hold 10 seconds, then bring knees back and drop to the other side."),
        ],
        caregiverTip: "Keep shoulders flat throughout. This should be a comfortable rotation, not a strain."
    )

    static let cat_cow = Exercise(
        name: "Cat-Cow Stretch", bodyArea: .hip,
        visualDescription: "On hands and knees, alternate between arching the back upward and letting it sag downward.",
        targetAngleRange: 10...30, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Start", instruction: "Start on hands and knees, wrists under shoulders, knees under hips."),
            ExerciseStep(stepNumber: 2, title: "Cat", instruction: "Inhale, then exhale and round the back up toward the ceiling."),
            ExerciseStep(stepNumber: 3, title: "Cow", instruction: "Inhale and let the back sag gently downward. Alternate slowly 10 times."),
        ],
        caregiverTip: "Keep the movement slow and rhythmic. Ideal for morning stiffness and lower back tightness."
    )

    static let hip_hinge = Exercise(
        name: "Hip Hinge", bodyArea: .hip,
        visualDescription: "Stand with feet hip-width apart. Hinge forward at the hips with a flat back, then return upright.",
        targetAngleRange: 30...60, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand tall", instruction: "Stand with feet hip-width apart, soft bend in the knees."),
            ExerciseStep(stepNumber: 2, title: "Hinge forward", instruction: "Push hips back and lean forward with a flat back (not a round spine)."),
            ExerciseStep(stepNumber: 3, title: "Return", instruction: "Drive hips forward to return upright. Repeat 10 times."),
        ],
        caregiverTip: "Place a hand on the lower back to ensure it stays neutral. This is the foundation for safe bending."
    )

    static let standing_hip_flexion = Exercise(
        name: "Standing Hip Flexion", bodyArea: .hip,
        visualDescription: "Stand and lift the knee up toward the chest in a controlled march movement.",
        targetAngleRange: 30...60, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand", instruction: "Stand near a wall or chair for balance support."),
            ExerciseStep(stepNumber: 2, title: "Lift knee", instruction: "Slowly raise the affected knee toward the chest as high as comfortable."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 3 seconds at the top, then slowly lower. Repeat 10 times."),
        ],
        caregiverTip: "Ensure the patient doesn't lean backward. A slight forward lean is fine."
    )

    static let pelvic_tilt = Exercise(
        name: "Pelvic Tilt", bodyArea: .hip,
        visualDescription: "Lie on your back, knees bent. Gently flatten the lower back against the floor by tightening the abs.",
        targetAngleRange: 0...10, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie back", instruction: "Lie on your back, knees bent at 90°, feet flat."),
            ExerciseStep(stepNumber: 2, title: "Tilt", instruction: "Tighten your abs and flatten your lower back against the floor."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 5 seconds, then release. Repeat 10 times."),
        ],
        caregiverTip: "You should be able to barely slide a hand under their lower back at rest — the tilt removes that gap."
    )

    // MARK: ── ANKLE ──────────────────────────────────────────

    static let ankle_circles = Exercise(
        name: "Ankle Circles", bodyArea: .ankle,
        visualDescription: "Sit with leg elevated. Rotate the foot in full circles — 10 clockwise, 10 counter-clockwise.",
        targetAngleRange: 0...45, holdSeconds: 0, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Elevate", instruction: "Sit in a chair and elevate the affected foot on a stool."),
            ExerciseStep(stepNumber: 2, title: "Circles", instruction: "Rotate the foot in large, slow circles — 10 clockwise."),
            ExerciseStep(stepNumber: 3, title: "Reverse", instruction: "Repeat 10 circles counter-clockwise."),
        ],
        caregiverTip: "Encourage full range in each direction. Watch for hesitation in any direction — that's where stiffness lives."
    )

    static let seated_calf_raises = Exercise(
        name: "Seated Calf Raises", bodyArea: .ankle,
        visualDescription: "Sit upright. Raise both heels as high as possible, hold, then lower slowly.",
        targetAngleRange: 20...40, holdSeconds: 3, reps: 15,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit upright", instruction: "Sit with feet flat on the floor, hip-width apart."),
            ExerciseStep(stepNumber: 2, title: "Raise heels", instruction: "Push up onto your toes, raising heels as high as possible."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 3 seconds at the top, then lower slowly. Repeat 15 times."),
        ],
        caregiverTip: "For severe ankle issues, start with both feet together. Progress to single-leg when comfortable."
    )

    static let towel_scrunches = Exercise(
        name: "Towel Scrunches", bodyArea: .ankle,
        visualDescription: "Place a small towel flat on the floor. Use your toes to scrunch and pull it toward you.",
        targetAngleRange: 0...15, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Sit in a chair. Place a small towel flat under your affected foot."),
            ExerciseStep(stepNumber: 2, title: "Scrunch", instruction: "Use your toes to scrunch and grab the towel, pulling it toward you."),
            ExerciseStep(stepNumber: 3, title: "Release", instruction: "Relax the toes, smoothing the towel out. Repeat 10 times."),
        ],
        caregiverTip: "This rebuilds intrinsic foot and lower ankle stability after a sprain."
    )

    static let single_leg_balance = Exercise(
        name: "Single Leg Balance", bodyArea: .ankle,
        visualDescription: "Stand near a wall. Lift the unaffected foot and balance on the injured side.",
        targetAngleRange: 0...10, holdSeconds: 10, reps: 5,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Stand near wall", instruction: "Stand beside a wall for safety. Keep a finger lightly touching it."),
            ExerciseStep(stepNumber: 2, title: "Lift foot", instruction: "Slowly lift the unaffected foot and balance on the affected ankle."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 10 seconds. Aim to reduce wall reliance over time. Repeat 5 times."),
        ],
        caregiverTip: "Stay close — the patient may wobble especially in early recovery. Remove the wall touch as balance improves."
    )

    static let resistance_dorsiflexion = Exercise(
        name: "Resistance Band Dorsiflexion", bodyArea: .ankle,
        visualDescription: "Sit with a resistance band around the foot. Pull the foot toward the shin against the band.",
        targetAngleRange: 10...20, holdSeconds: 3, reps: 15,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Sit with leg straight. Loop a resistance band around the foot, anchored to a fixed point."),
            ExerciseStep(stepNumber: 2, title: "Pull up", instruction: "Pull your foot toward your shin (dorsiflexion) against the band's resistance."),
            ExerciseStep(stepNumber: 3, title: "Hold & release", instruction: "Hold 3 seconds, then slowly return. Repeat 15 times."),
        ],
        caregiverTip: "Anchor the band securely. Start with light resistance and progress as tolerance improves."
    )

    static let ankle_pumps = Exercise(
        name: "Ankle Pumps", bodyArea: .ankle,
        visualDescription: "Lie or sit with leg elevated. Slowly pump the foot up and down — toes toward shin, then away.",
        targetAngleRange: 5...15, holdSeconds: 3, reps: 20,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Elevate", instruction: "Lie or sit with the affected foot elevated above heart level."),
            ExerciseStep(stepNumber: 2, title: "Pull up", instruction: "Pull the foot toward your shin as far as comfortable. Hold 3 seconds."),
            ExerciseStep(stepNumber: 3, title: "Push down", instruction: "Push the foot away from you (point toes). Hold 3 seconds. Repeat 20 times."),
        ],
        caregiverTip: "Ideal as a first exercise after fracture or surgery — promotes circulation and reduces swelling."
    )

    static let seated_toe_raises = Exercise(
        name: "Seated Toe Raises", bodyArea: .ankle,
        visualDescription: "Sit with feet flat. Lift the toes and forefoot off the ground while keeping the heel down.",
        targetAngleRange: 10...20, holdSeconds: 3, reps: 15,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit upright", instruction: "Sit with feet flat on the floor."),
            ExerciseStep(stepNumber: 2, title: "Raise toes", instruction: "Lift your toes and forefoot off the floor, keeping the heel down."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 3 seconds, then lower slowly. Repeat 15 times."),
        ],
        caregiverTip: "This restores dorsiflexion range critical for walking normally after ankle fractures."
    )

    static let seated_heel_raises = Exercise(
        name: "Seated Heel Raises", bodyArea: .ankle,
        visualDescription: "Sit with feet flat. Raise the heels while keeping toes on the ground.",
        targetAngleRange: 10...20, holdSeconds: 3, reps: 15,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit upright", instruction: "Sit with feet flat, hip-width apart."),
            ExerciseStep(stepNumber: 2, title: "Raise heels", instruction: "Lift both heels off the floor while keeping toes planted."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 3 seconds, then lower slowly. Repeat 15 times."),
        ],
        caregiverTip: "A gentle, safe starting point for restoring plantar flexion after ankle injury."
    )

    // MARK: ── SHOULDER ──────────────────────────────────────────

    static let shoulder_rolls = Exercise(
        name: "Shoulder Rolls", bodyArea: .shoulder,
        visualDescription: "Sit or stand upright. Roll both shoulders forward in circles, then backward.",
        targetAngleRange: 0...30, holdSeconds: 0, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit tall", instruction: "Sit or stand upright with arms relaxed at your sides."),
            ExerciseStep(stepNumber: 2, title: "Roll forward", instruction: "Slowly roll both shoulders forward in large circles 10 times."),
            ExerciseStep(stepNumber: 3, title: "Roll backward", instruction: "Reverse the direction for 10 rolls backward."),
        ],
        caregiverTip: "Encourage slow, full circles. This is ideal as a gentle warm-up for any shoulder condition."
    )

    static let cross_body_stretch = Exercise(
        name: "Cross-Body Stretch", bodyArea: .shoulder,
        visualDescription: "Bring the affected arm across the chest. Use the other hand to gently increase the stretch.",
        targetAngleRange: 10...40, holdSeconds: 20, reps: 3,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Cross arm", instruction: "Bring the affected arm straight across your chest."),
            ExerciseStep(stepNumber: 2, title: "Apply pressure", instruction: "Use the other hand to gently pull the elbow further across."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 20 seconds. Feel the stretch in the back of the shoulder. Repeat 3 times."),
        ],
        caregiverTip: "This targets the posterior capsule — a common source of shoulder stiffness."
    )

    static let wall_slides_shoulder = Exercise(
        name: "Wall Slides", bodyArea: .shoulder,
        visualDescription: "Stand facing a wall. Walk your fingers up the wall as high as comfortable, then slide them back down.",
        targetAngleRange: 60...120, holdSeconds: 3, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Face wall", instruction: "Stand facing the wall, fingertips touching it at shoulder height."),
            ExerciseStep(stepNumber: 2, title: "Walk up", instruction: "Slowly 'walk' your fingers up the wall as high as comfortable."),
            ExerciseStep(stepNumber: 3, title: "Hold & slide down", instruction: "Hold at the top 3 seconds, then walk fingers back down. Repeat 10 times."),
        ],
        caregiverTip: "Mark today's highest point on the wall — watching the mark rise daily is incredibly motivating."
    )

    static let external_rotation = Exercise(
        name: "External Rotation", bodyArea: .shoulder,
        visualDescription: "Elbow at 90°, tucked at the side. Rotate the forearm outward like opening a door.",
        targetAngleRange: 0...45, holdSeconds: 3, reps: 15,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Setup", instruction: "Stand with elbow bent 90°, tucked firmly at your side."),
            ExerciseStep(stepNumber: 2, title: "Rotate out", instruction: "Keeping elbow at your side, rotate the forearm outward away from your body."),
            ExerciseStep(stepNumber: 3, title: "Hold & return", instruction: "Hold 3 seconds, then return to start. Repeat 15 times."),
        ],
        caregiverTip: "Keep a small rolled towel between the elbow and ribs to ensure the elbow stays tucked."
    )

    static let scapular_setting = Exercise(
        name: "Scapular Setting", bodyArea: .shoulder,
        visualDescription: "Sit upright. Gently squeeze the shoulder blades together and downward, as if tucking them into your back pockets.",
        targetAngleRange: 0...15, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Sit tall", instruction: "Sit upright with arms relaxed."),
            ExerciseStep(stepNumber: 2, title: "Squeeze blades", instruction: "Gently draw the shoulder blades together and downward — don't shrug."),
            ExerciseStep(stepNumber: 3, title: "Hold", instruction: "Hold 5 seconds, then relax. Repeat 10 times."),
        ],
        caregiverTip: "This is the foundation of rotator cuff recovery. No arm movement — just the shoulder blades."
    )

    static let supine_shoulder_flexion = Exercise(
        name: "Supine Shoulder Flexion", bodyArea: .shoulder,
        visualDescription: "Lie on your back. Raise the affected arm overhead as far as comfortable, using the other arm to assist.",
        targetAngleRange: 60...150, holdSeconds: 5, reps: 10,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie flat", instruction: "Lie on your back, both arms at your sides."),
            ExerciseStep(stepNumber: 2, title: "Raise arm", instruction: "Hold the affected wrist with the other hand. Slowly raise both arms overhead."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold at the comfortable limit 5 seconds, then lower slowly. Repeat 10 times."),
        ],
        caregiverTip: "Gravity assists the stretch at full elevation. Encourage relaxation at the end range for maximum benefit."
    )

    static let side_lying_external_rotation = Exercise(
        name: "Side-Lying External Rotation", bodyArea: .shoulder,
        visualDescription: "Lie on your unaffected side. Elbow bent 90° against the body. Rotate the forearm upward toward the ceiling.",
        targetAngleRange: 0...45, holdSeconds: 3, reps: 15,
        steps: [
            ExerciseStep(stepNumber: 1, title: "Lie on side", instruction: "Lie on your unaffected side, elbow bent 90°, forearm resting on the body."),
            ExerciseStep(stepNumber: 2, title: "Rotate up", instruction: "Keeping elbow against the body, rotate the forearm up toward the ceiling."),
            ExerciseStep(stepNumber: 3, title: "Hold & lower", instruction: "Hold 3 seconds, then lower slowly. Repeat 15 times."),
        ],
        caregiverTip: "This is the most effective exercise for rebuilding rotator cuff strength after dislocation or impingement."
    )
}
```
## 4. ExerciseLibrary lookup
```swift
enum ExerciseLibrary {
    static let all: [Exercise] = [
        // Knee
        .quad_sets, .short_arc_quads, .seated_knee_extension,
        .straight_leg_raises, .heel_slides, .terminal_knee_extension,
        .seated_knee_flexion, .prone_knee_flexion,
        // Elbow
        .elbow_flexion_extension, .wrist_flexor_stretch, .towel_squeeze,
        .active_elbow_flexion, .forearm_rotation, .gravity_elbow_extension,
        .elbow_extension_stretch,
        // Hip
        .clamshells, .glute_bridges, .hip_flexor_stretch,
        .seated_hip_rotation, .supine_hip_rotation, .cat_cow,
        .hip_hinge, .standing_hip_flexion, .pelvic_tilt,
        // Ankle
        .ankle_alphabet, .ankle_circles, .seated_calf_raises,
        .towel_scrunches, .single_leg_balance, .resistance_dorsiflexion,
        .ankle_pumps, .seated_toe_raises, .seated_heel_raises,
        // Shoulder
        .pendulum_swings, .shoulder_rolls, .cross_body_stretch,
        .sleeper_stretch, .wall_slides_shoulder, .external_rotation,
        .scapular_setting, .supine_shoulder_flexion, .side_lying_external_rotation
    ]

    static func exercises(for condition: Condition) -> [Exercise] {
        condition.recommendedExerciseIDs.compactMap { id in
            all.first { $0.name.lowercased().replacingOccurrences(of: " ", with: "_") == id }
        }
    }
}
```


-- 

## Feature update -> Correctly mapping exercises with the new anglemath for all the exercises 

- Now that we have over 45 exercises in our library, we need to ensure that the targetAngleRange for each exercise is correctly defined according to the new angle math system. This will allow us to provide accurate feedback and guidance to users during their rehabilitation exercises.


Now we have the full ARKit joint name map. Here's the complete feature map: every exercise → which 3 ARKit joints to track → what math to run → what "good form" means.

## Key insight: ARKit joint names
From the ARKit skeleton, the joints we care about are:
​
​

```text
"left_upLeg_joint"      → Left Hip
"left_leg_joint"        → Left Knee
"left_foot_joint"       → Left Ankle
"right_upLeg_joint"     → Right Hip
"right_leg_joint"       → Right Knee
"right_foot_joint"      → Right Ankle
"left_shoulder_1_joint" → Left Shoulder
"left_arm_joint"        → Left Upper Arm
"left_forearm_joint"    → Left Elbow/Forearm
"left_hand_joint"       → Left Wrist/Hand
"right_shoulder_1_joint"→ Right Shoulder
"right_arm_joint"       → Right Upper Arm
"right_forearm_joint"   → Right Elbow/Forearm
"right_hand_joint"      → Right Wrist/Hand
"hips_joint"            → Pelvis center
"spine_4_joint"         → Mid-spine (approx torso)
"spine_7_joint"         → Upper spine
```
##Joint Tracking Config model
First, define a struct that tells the AR engine which joints to track for any exercise:

```swift
// models/JointTrackingConfig.swift

import Foundation

/// Defines which 3 ARKit joints form the angle triple for a given exercise,
/// plus what "good form" means for that exercise.
struct JointTrackingConfig: Hashable {
    let proximalJoint: String   // e.g. "right_upLeg_joint" (hip)
    let middleJoint: String     // e.g. "right_leg_joint"   (knee)
    let distalJoint: String     // e.g. "right_foot_joint"  (ankle)
    let trackingMode: TrackingMode
    let formCues: [FormCue]     // extra checks beyond angle
}

enum TrackingMode: Hashable {
    case angleBased             // primary: measure joint angle
    case holdDuration           // primary: hold a position steady
    case rangeOfMotion          // primary: track max ROM achieved
    case repetitionCounting     // primary: count full cycles
}

struct FormCue: Hashable {
    let description: String     // e.g. "Keep back flat on floor"
    let checkJoint: String?     // optional joint to monitor
    let rule: FormRule
}

enum FormRule: Hashable {
    case jointShouldStayStill(joint: String, toleranceCm: Float)
    case jointShouldNotRise(joint: String, aboveStartBy: Float)
    case angleShouldStayBelow(maxDegrees: Double)
    case angleShouldStayAbove(minDegrees: Double)
    case none
}
```
Full exercise → tracking map
Here's every exercise mapped to its tracking config. This is the feature map your agents will reference:

## Table for the exercises and their corresponding ARKit joint tracking configurations:
Knee exercises
Exercise	Proximal	Middle	Distal	Mode	Target Range	Form Check
Quad Sets	right_upLeg_joint	right_leg_joint	right_foot_joint	holdDuration	0°–5°	Back of knee should press down (knee joint Y shouldn't rise)
Short Arc Quads	right_upLeg_joint	right_leg_joint	right_foot_joint	angleBased	0°–5°	Thigh stays still (hip joint stable)
Seated Knee Extension	right_upLeg_joint	right_leg_joint	right_foot_joint	angleBased	0°–5°	Hip angle shouldn't change (torso stays upright)
Straight Leg Raises	right_upLeg_joint	right_leg_joint	right_foot_joint	angleBased	0°–5°	Knee must stay locked straight during lift
Heel Slides	right_upLeg_joint	right_leg_joint	right_foot_joint	rangeOfMotion	80°–95°	Back stays flat
Terminal Knee Extension	right_upLeg_joint	right_leg_joint	right_foot_joint	angleBased	0°–5°	Knee tracks over second toe (lateral drift check)
Seated Knee Flexion	right_upLeg_joint	right_leg_joint	right_foot_joint	rangeOfMotion	90°–110°	Torso upright
Prone Knee Flexion	right_upLeg_joint	right_leg_joint	right_foot_joint	rangeOfMotion	80°–120°	Hip stays flat on surface
Elbow exercises
Exercise	Proximal	Middle	Distal	Mode	Target Range	Form Check
Elbow Flexion & Extension	right_arm_joint	right_forearm_joint	right_hand_joint	repetitionCounting	10°–130°	Shoulder stays still
Wrist Flexor Stretch	right_arm_joint	right_forearm_joint	right_hand_joint	holdDuration	0°–30°	Elbow stays straight
Towel Squeeze	N/A (grip)	N/A	N/A	holdDuration	N/A	Cannot track with body skeleton — use timer only
Active Elbow Flexion	right_arm_joint	right_forearm_joint	right_hand_joint	repetitionCounting	10°–130°	Upper arm stays at side
Forearm Rotation	N/A (rotation)	N/A	N/A	holdDuration	N/A	Pronation/supination not trackable via skeleton angle — use timer only
Gravity-Assisted Extension	right_arm_joint	right_forearm_joint	right_hand_joint	holdDuration	0°–15°	Elbow stays relaxed (no muscle engagement)
Elbow Extension Stretch	right_arm_joint	right_forearm_joint	right_hand_joint	holdDuration	0°–10°	Shoulder stays still
Hip/back exercises
Exercise	Proximal	Middle	Distal	Mode	Target Range	Form Check
Clamshells	hips_joint	right_upLeg_joint	right_leg_joint	angleBased	30°–50°	Pelvis shouldn't roll backward
Glute Bridges	right_leg_joint	right_upLeg_joint	hips_joint	angleBased	20°–45°	Shoulders stay on floor
Hip Flexor Stretch	spine_4_joint	hips_joint	right_upLeg_joint	holdDuration	10°–30°	Torso stays upright
Seated Hip Rotation	spine_4_joint	hips_joint	right_upLeg_joint	holdDuration	20°–40°	Spine stays tall
Supine Hip Rotation	spine_4_joint	hips_joint	right_leg_joint	rangeOfMotion	20°–40°	Shoulders stay flat
Cat-Cow	hips_joint	spine_4_joint	spine_7_joint	repetitionCounting	10°–30°	Wrists stay under shoulders
Hip Hinge	spine_7_joint	hips_joint	right_upLeg_joint	angleBased	30°–60°	Spine stays neutral (no rounding)
Standing Hip Flexion	spine_4_joint	hips_joint	right_upLeg_joint	angleBased	30°–60°	No backward lean
Pelvic Tilt	right_upLeg_joint	hips_joint	spine_4_joint	holdDuration	0°–10°	Movement is subtle and controlled
Ankle exercises
Exercise	Proximal	Middle	Distal	Mode	Target Range	Form Check
Ankle Alphabet	right_leg_joint	right_foot_joint	right_toes_joint	rangeOfMotion	0°–45°	Knee stays still
Ankle Circles	right_leg_joint	right_foot_joint	right_toes_joint	repetitionCounting	0°–45°	Knee stays still
Seated Calf Raises	right_leg_joint	right_foot_joint	right_toes_joint	repetitionCounting	20°–40°	Knees stay at 90°
Towel Scrunches	N/A (toes)	N/A	N/A	holdDuration	N/A	Toe grip not trackable — timer only
Single Leg Balance	right_upLeg_joint	right_leg_joint	right_foot_joint	holdDuration	0°–10°	Opposite foot off ground
Resistance Dorsiflexion	right_leg_joint	right_foot_joint	right_toes_joint	repetitionCounting	10°–20°	Knee stays still
Ankle Pumps	right_leg_joint	right_foot_joint	right_toes_joint	repetitionCounting	5°–15°	Leg stays elevated
Seated Toe Raises	right_leg_joint	right_foot_joint	right_toes_joint	repetitionCounting	10°–20°	Heels stay grounded
Seated Heel Raises	right_leg_joint	right_foot_joint	right_toes_joint	repetitionCounting	10°–20°	Toes stay grounded
Shoulder exercises
Exercise	Proximal	Middle	Distal	Mode	Target Range	Form Check
Pendulum Swings	right_shoulder_1_joint	right_arm_joint	right_forearm_joint	rangeOfMotion	0°–30°	Arm fully relaxed (no muscle engagement)
Shoulder Rolls	spine_7_joint	right_shoulder_1_joint	right_arm_joint	repetitionCounting	0°–30°	Arms relaxed at sides
Cross-Body Stretch	left_arm_joint	right_shoulder_1_joint	right_arm_joint	holdDuration	10°–40°	Torso stays forward
Sleeper Stretch	right_shoulder_1_joint	right_arm_joint	right_forearm_joint	holdDuration	30°–60°	Elbow stays at 90°
Wall Slides	spine_7_joint	right_shoulder_1_joint	right_arm_joint	rangeOfMotion	60°–120°	Back stays against wall
External Rotation	right_shoulder_1_joint	right_arm_joint	right_forearm_joint	repetitionCounting	0°–45°	Elbow stays tucked at side
Scapular Setting	spine_7_joint	right_shoulder_1_joint	left_shoulder_1_joint	holdDuration	0°–15°	No shrugging (shoulders stay down)
Supine Shoulder Flexion	spine_7_joint	right_shoulder_1_joint	right_arm_joint	rangeOfMotion	60°–150°	Back stays flat
Side-Lying External Rotation	right_shoulder_1_joint	right_arm_joint	right_forearm_joint	repetitionCounting	0°–45°	Elbow stays against body
Exercises that can't use angle tracking
Some exercises involve movements ARKit body skeleton can't measure (grip, toe curl, rotation):

## Table for exercises that require timer-only mode due to tracking limitations
Exercise	Reason	Fallback
Towel Squeeze	Grip force, not joint angle	Timer-only mode (hold X seconds)
Forearm Rotation	Pronation/supination (axial rotation) not captured by 3-joint angle	Timer-only mode
Towel Scrunches	Toe grip	Timer-only mode
For these, the AR view just shows a countdown timer + instruction card, no angle overlay.

Implementation: attach config to Exercise model
Add a computed property or a static lookup:

```swift
// services/TrackingConfigLibrary.swift

enum TrackingConfigLibrary {
    static func config(for exerciseName: String) -> JointTrackingConfig? {
        switch exerciseName {
        // KNEE
        case "Quad Sets":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint",
                middleJoint: "right_leg_joint",
                distalJoint: "right_foot_joint",
                trackingMode: .holdDuration,
                formCues: [
                    FormCue(description: "Press the back of your knee toward the floor",
                            checkJoint: "right_leg_joint",
                            rule: .jointShouldNotRise(joint: "right_leg_joint", aboveStartBy: 0.02))
                ]
            )
        case "Heel Slides":
            return JointTrackingConfig(
                proximalJoint: "right_upLeg_joint",
                middleJoint: "right_leg_joint",
                distalJoint: "right_foot_joint",
                trackingMode: .rangeOfMotion,
                formCues: [
                    FormCue(description: "Keep your back flat on the floor",
                            checkJoint: "hips_joint",
                            rule: .jointShouldStayStill(joint: "hips_joint", toleranceCm: 3.0))
                ]
            )
        // ... repeat for each exercise

        // TIMER-ONLY fallbacks
        case "Towel Squeeze", "Forearm Rotation", "Towel Scrunches":
            return nil  // nil means timer-only mode in ExerciseARView

        default:
            return nil
        }
    }
}
```
Then in ExerciseARView, the logic branches:

```swift
if let config = TrackingConfigLibrary.config(for: exercise.name) {
    // Full AR tracking mode with angle + form cues
    startARSession(with: config)
} else {
    // Timer-only mode: show instruction + countdown
    startTimerMode(holdSeconds: exercise.holdSeconds, reps: exercise.reps)
}
```
Update RehabEngine to be generic
Your existing AngleMath.computeJointAngle already works for any 3 joints. Now the engine just reads from JointTrackingConfig:

```swift
// In the AR Coordinator's didUpdate anchors:
func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    guard let body = anchors.compactMap({ $0 as? ARBodyAnchor }).first,
          let config = currentConfig else { return }

    let skeleton = body.skeleton

    guard let proximal = jointPosition(skeleton, config.proximalJoint),
          let middle   = jointPosition(skeleton, config.middleJoint),
          let distal   = jointPosition(skeleton, config.distalJoint)
    else { return }

    let angle = AngleMath.computeJointAngle(
        proximal: proximal, joint: middle, distal: distal
    )

    // Zone classification uses the exercise's targetAngleRange
    // Form cue checks use the config.formCues rules
    // All fed into the ViewModel for the UI to display
}

private func jointPosition(_ skeleton: ARSkeleton3D, _ name: String) -> SIMD3<Float>? {
    guard let transform = skeleton.modelTransform(
        for: ARSkeleton.JointName(rawValue: name)
    ) else { return nil }
    return SIMD3<Float>(transform.columns.3.x,
                        transform.columns.3.y,
                        transform.columns.3.z)
}
```

## If we have timer based exercises, we also need to ensure that the RehabEngine can handle those correctly. For timer-based exercises, the engine should simply start a countdown when the exercise begins and provide feedback when the time is up. This can be implemented by checking if the JointTrackingConfig is nil (indicating a timer-based exercise) and then starting a timer instead of tracking joint angles.

### Timer-only exercises (no AR angle tracking)
- Towel Squeeze (grip force)
- Forearm Rotation (axial rotation)
- Towel Scrunches (toe grip)
These use countdown timer + instruction card only.


-- 

## Feature update -> Fixing the ARKIT and making the orbs smaller 

This is a critical reality check. Here's what research shows about ARKit body tracking accuracy and what you should actually do for PhysioPoint.

The honest truth about ARKit body tracking
A lab study comparing ARKit against clinical-grade Vicon motion capture found:
​

Average error: ~18.8° ± 12.1° across all joints and exercises

Best case: ~3.75° error (simple, visible joints like knees from side view)

Worst case: ~47° error (occluded joints, complex movements)

Side view performs better than frontal view

Accuracy depends heavily on which exercise is being performed

Known ARKit body tracking problems:

Overlapping limbs (arm across body, squatting) cause massive joint drift

Wrist joints barely update — left_hand_joint / right_hand_joint transforms often don't change even when waving
​

Squats / deep bends cause the root joint to drift backward by 1+ meters
​

Turning away from camera confuses head/body rotation
​

Small movements (wrist flexion, forearm rotation, toe curls) are not detectable

LiDAR helps somewhat, but doesn't guarantee accuracy
​

What this means for PhysioPoint's exercise library
We need to audit every exercise and classify it by AR trackability. Many exercises we defined simply won't work reliably.

Exercises that ARE trackable (good ARKit visibility)
These involve large, visible joint movements from a side camera view:

## Table for exercises that are reliably trackable with ARKit, along with reasons and recommended camera positions

Exercise	Why it works	Camera position
Heel Slides	Large knee angle change, side view, lying down	Side
Seated Knee Extension	Clear knee angle, seated, side view	Side
Straight Leg Raises	Leg lift from flat, large movement	Side
Quad Sets	Subtle but measurable knee press (marginal)	Side
Glute Bridges	Hip lift, large vertical movement	Side
Standing Hip Flexion	Knee raise, clear hip angle	Side/Front
Clamshells	Knee opening, side-lying (if camera positioned well)	Front
Wall Slides (shoulder)	Arm raising along wall, clear shoulder angle	Side
Elbow Flexion & Extension	Large elbow angle change	Side
Active Elbow Flexion	Same as above	Side
Single Leg Balance	Detect if one foot lifts (hold-based)	Front
Exercises that are MARGINAL (may work with caveats)
Exercise	Problem	Mitigation
Prone Knee Flexion	Face-down = back to camera, joints occluded	Instruct user to place camera at foot-end, angled
Hip Hinge	Root joint drifts during forward bend
​	Use relative angle only, not absolute position
Cat-Cow	Spine joints are inferred, not directly tracked	Use rough spine angle, accept ±15° tolerance
Pendulum Swings	Arm hanging + leaning = occlusion	Only track if arm is visible
Seated Hip Rotation	Crossed legs confuse skeleton	Wider tolerance zones
Exercises that CANNOT be tracked by ARKit
Exercise	Why it fails	Solution
Wrist Flexor Stretch	Wrist joints don't meaningfully update
​	Timer-only mode
Towel Squeeze	Grip force, no joint angle	Timer-only mode
Forearm Rotation	Axial rotation not captured by skeleton angles	Timer-only mode
Towel Scrunches	Toe movement not tracked	Timer-only mode
Sleeper Stretch	Side-lying + arm across body = heavy occlusion	Timer-only mode
Cross-Body Stretch	Arm crosses torso = overlapping joints
​	Timer-only mode
Scapular Setting	Shoulder blade squeeze = no visible joint angle change	Timer-only mode
Ankle Alphabet	Foot/toe movements too small for body skeleton	Timer-only mode
Ankle Circles	Same issue	Timer-only mode
Ankle Pumps	Same issue	Timer-only mode
Seated Toe Raises	Same issue	Timer-only mode
Seated Heel Raises	Same issue	Timer-only mode
Resistance Band Dorsiflexion	Same issue	Timer-only mode
Seated Calf Raises	Marginal foot movement	Timer-only mode
Pelvic Tilt	Movement is too subtle (a few degrees of spine tilt)	Timer-only mode
Improving accuracy for trackable exercises
You can't change ARKit itself, but you can work around its weaknesses:


There are some issues we need to address in the ARKIT specifically make the balls smaller as well on the tracking UI, since the joints are not perfectly accurate, having smaller orbs will make it less likely for users to get confused by the joint positions. Additionally, we can add a visual indicator of the acceptable range of motion (e.g., a shaded area or a color change) to help users understand when they are within the target angle range, even if the exact joint position is slightly off due to tracking inaccuracies.

## 2. Apply temporal smoothing
Raw ARKit data jitters frame-to-frame. Apply a simple moving average:

```swift
// utils/AngleSmoothing.swift

final class AngleSmoother {
    private var buffer: [Double] = []
    private let windowSize: Int

    init(windowSize: Int = 5) {
        self.windowSize = windowSize
    }

    func smooth(_ newValue: Double) -> Double {
        buffer.append(newValue)
        if buffer.count > windowSize {
            buffer.removeFirst()
        }
        return buffer.reduce(0, +) / Double(buffer.count)
    }

    func reset() {
        buffer.removeAll()
    }
}
```

Use in the AR coordinator:

```swift
let rawAngle = AngleMath.computeJointAngle(...)
let smoothedAngle = angleSmoother.smooth(rawAngle)
This reduces jitter from ±5° per frame to ±1–2°.
```

## 3. Use relative angles, not absolute positions
Don't rely on world-space position of joints (which drifts badly). Instead, always compute the angle between three joints — this is relative and much more stable:
​

```swift
// GOOD: relative angle (stable)
let angle = AngleMath.computeJointAngle(
    proximal: hip, joint: knee, distal: ankle
)

// BAD: absolute position (drifts)
let kneeHeight = knee.y  // unreliable
```
## 4. Widen tolerance zones
Given ~18° average error, your "green zone" should be generous:
​

```swift
// Instead of tight clinical ranges:
// targetAngleRange: 90...95  ← too tight for ARKit

// Use wider educational ranges:
// targetAngleRange: 75...105  ← accounts for ARKit error margin
```
## 5. Validate tracking quality before counting
Check that ARKit is actually confident before recording data:

```swift
func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
    guard let body = anchors.compactMap({ $0 as? ARBodyAnchor }).first else { return }

    // Only process if tracking is normal quality
    guard session.currentFrame?.camera.trackingState == .normal else {
        // Show "Move to a better position" warning in UI
        return
    }

    // ... process joints
}
```
Updated Exercise model additions
Add camera position and tracking mode info to the exercise:

```swift
enum CameraPosition: String, Codable {
    case side
    case front
}

enum ExerciseTrackingMode: Codable, Hashable {
    case arTracked      // full AR angle tracking
    case timerOnly      // countdown + instruction card only
}
```

// Add to Exercise struct:
let recommendedCameraPosition: CameraPosition
let trackingMode: ExerciseTrackingMode
Updated tracking summary
Category	Count	Mode
AR-tracked exercises	~15	Full angle + form feedback
Timer-only exercises	~20	Instruction card + countdown
Marginal (AR with caveats)	~10	AR tracking with wider tolerances + form warnings
This is honest and realistic, and actually makes your app stronger for the Challenge because you can say:

"We evaluated ARKit's tracking capabilities per exercise and built two modes: full AR validation where the technology is reliable, and guided timer mode where joint visibility is limited. This reflects real-world constraints of consumer-grade motion capture."

That shows technical maturity, which judges value highly.
​

