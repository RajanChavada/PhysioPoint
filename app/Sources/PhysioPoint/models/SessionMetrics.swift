import Foundation

struct SessionMetrics: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var exerciseID: UUID?
    var bestAngle: Double = 0.0
    var repsCompleted: Int = 0
    var targetReps: Int = 0
    
    init(id: UUID = UUID(), date: Date = Date(), exerciseID: UUID? = nil, bestAngle: Double = 0.0, repsCompleted: Int = 0, targetReps: Int = 0) {
        self.id = id
        self.date = date
        self.exerciseID = exerciseID
        self.bestAngle = bestAngle
        self.repsCompleted = repsCompleted
        self.targetReps = targetReps
    }
}
