import Foundation

struct PlanSlot: Identifiable, Codable {
    let id: UUID
    let label: String          // "Morning", "Afternoon", "Evening"
    let exerciseID: Exercise.ID
    let exerciseName: String   // Stored for display without re-looking up
    let exerciseSets: Int
    let exerciseReps: Int
    var scheduledHour: Int     // 24-hr, e.g. 8, 13, 18
    var isCompleted: Bool
    var completedAt: Date?
}

struct DailyPlan: Identifiable, Codable {
    var id: UUID = UUID()
    let conditionID: UUID      // links back to the Condition
    let conditionName: String  // e.g. "Hard to bend past 90°"
    let bodyArea: String       // e.g. "Knee"
    let date: Date
    var slots: [PlanSlot]

    /// Build a default 3-slot plan from a condition's exercises, rotating through them.
    static func make(for condition: Condition) -> DailyPlan {
        let exercises = condition.recommendedExercises
        let defaultHours = [8, 13, 18]
        let labels = ["Morning", "Afternoon", "Evening"]

        var slots: [PlanSlot] = []
        for i in 0..<3 {
            let ex = exercises[i % max(exercises.count, 1)]
            slots.append(PlanSlot(
                id: UUID(),
                label: labels[i],
                exerciseID: ex.id,
                exerciseName: ex.name,
                exerciseSets: 3,
                exerciseReps: ex.reps,
                scheduledHour: defaultHours[i],
                isCompleted: false,
                completedAt: nil
            ))
        }
        return DailyPlan(
            conditionID: condition.id,
            conditionName: condition.name,
            bodyArea: condition.bodyArea.rawValue,
            date: Date(),
            slots: slots
        )
    }
}
