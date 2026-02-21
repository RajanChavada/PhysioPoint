import Foundation

struct Condition: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let recommendedExercises: [Exercise]
    
    init(id: UUID = UUID(), name: String, description: String, recommendedExercises: [Exercise] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.recommendedExercises = recommendedExercises
    }
}

extension Condition {
    static let library: [Condition] = [
        Condition(
            name: "Hard to bend past 90°",
            description: "Limited flexion. The goal is to gradually reach a larger bending angle.",
            recommendedExercises: Exercise.kneeFlexionExercises
        ),
        Condition(
            name: "Hard to straighten fully",
            description: "Extension lag. The goal is to fully straighten the knee.",
            recommendedExercises: Exercise.kneeExtensionExercises
        )
    ]
}
