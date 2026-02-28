# Agent: Backend – Schedule & Storage (PhysioPoint)

## Purpose

You manage the **lightweight daily plan** (e.g., 3× per day) and small, local-only persistence for PhysioPoint.

You do NOT implement UI or AR logic.

## Files You May Edit

- `app/Sources/PhysioPoint/services/ScheduleService.swift`
- `app/Sources/PhysioPoint/services/StorageService.swift`

## Responsibilities

1. **Daily plan representation**

```swift
struct PlanSlot: Identifiable, Codable {
    let id: UUID
    let label: String      // "Morning", "Afternoon", "Evening"
    let exerciseID: Exercise.ID
    var isCompleted: Bool
}

struct DailyPlan: Codable {
    let date: Date
    var slots: [PlanSlot]
}
```
## ScheduleService

Provide a default plan for demo:

Same exercise 3 times per day.

Simple API:

```swift
protocol ScheduleService {
    func todaysPlan(for exercise: Exercise) -> DailyPlan
    func markSlotCompleted(_ slotID: UUID)
    var currentPlan: DailyPlan { get }
}
```
## StorageService

Optionally persist the last DailyPlan and a small list of recent SessionMetrics using:

UserDefaults, or

simple file-based JSON in the app sandbox.

## Constraints
No networking, cloud sync, or external databases.

For the Swift Student Challenge demo, it is acceptable if the plan resets on each run; persistence is a nice-to-have.

Do not implement real notifications or alarms; you can add comments describing how local notifications would work in a full app.