import Foundation

struct Condition: Identifiable, Hashable {
    let id: UUID
    let name: String
    let description: String
    let bodyArea: BodyArea
    let recommendedExercises: [Exercise]

    init(id: UUID = UUID(), name: String, description: String, bodyArea: BodyArea = .knee, recommendedExercises: [Exercise] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.bodyArea = bodyArea
        self.recommendedExercises = recommendedExercises
    }
}

extension Condition {
    /// Full library mapped by body part for the BodyMapView
    static let library: [Condition] = kneeConditions + shoulderConditions + elbowConditions + ankleConditions + hipConditions

    /// Filter conditions by body area
    static func conditions(for area: BodyArea) -> [Condition] {
        library.filter { $0.bodyArea == area }
    }

    // MARK: - Knee
    static let kneeConditions: [Condition] = [
        Condition(
            name: "Hard to bend past 90°",
            description: "Limited flexion after surgery or injury. The goal is to gradually increase bending range.",
            bodyArea: .knee,
            recommendedExercises: Exercise.kneeFlexionExercises
        ),
        Condition(
            name: "Hard to straighten fully",
            description: "Extension lag — the knee won't lock straight. The goal is to achieve full extension.",
            bodyArea: .knee,
            recommendedExercises: Exercise.kneeExtensionExercises
        ),
    ]

    // MARK: - Shoulder
    static let shoulderConditions: [Condition] = [
        Condition(
            name: "Stiff or frozen shoulder",
            description: "Reduced range of motion from adhesive capsulitis, surgery, or disuse.",
            bodyArea: .shoulder,
            recommendedExercises: Exercise.shoulderExercises
        ),
    ]

    // MARK: - Ankle
    static let ankleConditions: [Condition] = [
        Condition(
            name: "Ankle sprain recovery",
            description: "Rebuilding range of motion after a sprain or fracture.",
            bodyArea: .ankle,
            recommendedExercises: Exercise.ankleExercises
        ),
    ]

    // MARK: - Elbow
    static let elbowConditions: [Condition] = [
        Condition(
            name: "Elbow stiffness / post-op",
            description: "Restoring flexion and extension range after fracture, surgery, or prolonged immobilization.",
            bodyArea: .elbow,
            recommendedExercises: Exercise.elbowExercises
        ),
    ]

    // MARK: - Hip
    static let hipConditions: [Condition] = [
        Condition(
            name: "Hip weakness / post-op",
            description: "Strengthening the hip after replacement or injury.",
            bodyArea: .hip,
            recommendedExercises: Exercise.hipExercises
        ),
    ]
}
