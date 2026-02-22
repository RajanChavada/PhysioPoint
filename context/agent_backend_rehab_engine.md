

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