import Foundation

struct Exercise: Identifiable, Hashable {
    let id: UUID
    let name: String
    let visualDescription: String
    let targetAngleRange: ClosedRange<Double>
    let holdSeconds: Int
    let reps: Int
    
    init(id: UUID = UUID(), name: String, visualDescription: String, targetAngleRange: ClosedRange<Double>, holdSeconds: Int, reps: Int) {
        self.id = id
        self.name = name
        self.visualDescription = visualDescription
        self.targetAngleRange = targetAngleRange
        self.holdSeconds = holdSeconds
        self.reps = reps
    }
}

extension Exercise {
    static let kneeFlexionExercises = [
        Exercise(
            name: "Heel Slides",
            visualDescription: "Slowly slide your heel towards your glutes. Hold for a moment, then straighten.",
            targetAngleRange: 80...95,
            holdSeconds: 3,
            reps: 3
        )
    ]
    
    static let kneeExtensionExercises = [
        Exercise(
            name: "Straight Leg Raises",
            visualDescription: "Keep your leg perfectly straight, tighten your thigh muscle, and lift.",
            targetAngleRange: 0...5,
            holdSeconds: 3,
            reps: 3
        )
    ]
}
