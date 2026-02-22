import Foundation

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
