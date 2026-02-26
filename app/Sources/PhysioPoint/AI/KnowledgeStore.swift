import Foundation

// MARK: - Knowledge Condition

struct KnowledgeCondition {
    let name: String
    let bodyArea: BodyArea
    let keywords: [String]
    let summary: String            // Max ~60 words — tight token budget
    let exerciseNames: [String]    // Must match Exercise.name exactly
    let redFlags: [String]
}

// MARK: - Knowledge Store (Static RAG Layer)

/// In-memory knowledge base. All data is hardcoded Swift structs — zero runtime I/O.
/// Retrieval is done in Swift (fast, no tokens wasted), then only matched
/// condition summaries are injected into the model prompt.
struct KnowledgeStore {

    static let conditions: [KnowledgeCondition] = [

        // ── KNEE ──────────────────────────────────────────────

        KnowledgeCondition(
            name: "ACL Tear",
            bodyArea: .knee,
            keywords: ["acl", "ligament", "tear", "popping", "pop", "unstable", "knee", "gave", "buckle", "twist"],
            summary: "ACL tears affect knee stability. Rehab focuses on quad/hamstring balance, ROM restoration, proprioception, and gradual return to activity.",
            exerciseNames: ["Straight Leg Raises", "Seated Knee Extension", "Single Leg Balance"],
            redFlags: ["Knee buckles during walking", "Significant swelling after 48 hours", "Unable to bear weight"]
        ),

        KnowledgeCondition(
            name: "Knee Dislocation",
            bodyArea: .knee,
            keywords: ["dislocated", "kneecap", "popped", "cap", "slipped", "knee", "out", "displaced"],
            summary: "Knee dislocation involves the kneecap slipping out of the femoral groove. Recovery focuses on quad strengthening, ROM restoration, and gradual weight-bearing.",
            exerciseNames: ["Heel Slides", "Seated Knee Flexion", "Terminal Knee Extension"],
            redFlags: ["Sudden increase in swelling", "Loss of feeling in foot", "Knee locks and won't straighten"]
        ),

        KnowledgeCondition(
            name: "General Knee Pain",
            bodyArea: .knee,
            keywords: ["knee", "pain", "stiff", "sore", "ache", "hurt", "stairs", "walk", "bend", "creak", "click"],
            summary: "General knee pain often results from overuse, arthritis, or muscle imbalances. Gentle movement and quad/hip strengthening are more effective than complete rest.",
            exerciseNames: ["Seated Knee Extension", "Straight Leg Raises", "Heel Slides"],
            redFlags: ["Pain waking you at night", "Redness and warmth around knee", "Pain persisting beyond 6 weeks"]
        ),

        // ── SHOULDER ──────────────────────────────────────────

        KnowledgeCondition(
            name: "Rotator Cuff Injury",
            bodyArea: .shoulder,
            keywords: ["rotator", "cuff", "shoulder", "overhead", "lift", "pain", "reaching", "tear", "strain"],
            summary: "Rotator cuff issues range from tendinitis to tears. Rehab restores pain-free ROM first, then strengthens cuff and scapular muscles progressively.",
            exerciseNames: ["Wall Slides", "Supine Shoulder Flexion", "Standing Shoulder Flexion"],
            redFlags: ["Complete inability to lift arm", "Shoulder pain after fall", "Persistent night pain", "Visible deformity"]
        ),

        KnowledgeCondition(
            name: "Shoulder Impingement",
            bodyArea: .shoulder,
            keywords: ["shoulder", "impingement", "pinch", "overhead", "clicking", "arc", "raise", "arm"],
            summary: "Shoulder impingement is pinching of rotator cuff tendons during overhead movements. Treatment corrects posture and strengthens scapular stabilizers.",
            exerciseNames: ["Wall Slides", "Standing Shoulder Flexion", "Supine Shoulder Flexion"],
            redFlags: ["Sharp catching pain lowering arm", "Weakness in daily tasks", "Pain radiating past elbow"]
        ),

        // ── BACK & CORE ──────────────────────────────────────

        KnowledgeCondition(
            name: "Lower Back Pain",
            bodyArea: .hip,
            keywords: ["back", "lower", "lumbar", "spine", "sitting", "stiff", "disc", "sciatica", "core"],
            summary: "Lower back pain affects 80% of people. Staying active with gentle movement and core strengthening is far more effective than bed rest.",
            exerciseNames: ["Hip Hinge", "Standing Hip Flexion"],
            redFlags: ["Numbness in both legs", "Loss of bladder control", "Pain after significant fall"]
        ),

        KnowledgeCondition(
            name: "Poor Posture",
            bodyArea: .hip,
            keywords: ["posture", "slouch", "rounded", "forward", "head", "neck", "tech", "desk", "computer"],
            summary: "Poor posture from prolonged phone/computer use strains spine and shoulders. Strengthening upper back and stretching chest muscles restores alignment.",
            exerciseNames: ["Wall Slides", "Standing Shoulder Flexion"],
            redFlags: ["Sharp neck pain into arm", "Headaches worsening daily", "Tingling in hands"]
        ),

        // ── ANKLE & FOOT ──────────────────────────────────────

        KnowledgeCondition(
            name: "Ankle Sprain",
            bodyArea: .ankle,
            keywords: ["ankle", "sprain", "rolled", "twisted", "swollen", "inversion", "lateral"],
            summary: "Ankle sprains occur from rolling the ankle. 40% recur without adequate balance training. Focus on ROM, then stability and proprioception.",
            exerciseNames: ["Single Leg Balance", "Standing Hip Flexion"],
            redFlags: ["Unable to bear weight after 48 hours", "Severe bruising to toes", "Bony tenderness at ankle bones"]
        ),

        KnowledgeCondition(
            name: "Ankle Stiffness",
            bodyArea: .ankle,
            keywords: ["ankle", "stiff", "tight", "range", "motion", "boot", "cast", "dorsiflexion", "squat"],
            summary: "Ankle stiffness after injury or immobilization limits walking and balance. Daily stretching and progressive loading restore full mobility in 4–8 weeks.",
            exerciseNames: ["Single Leg Balance", "Seated Knee Extension"],
            redFlags: ["Sudden swelling after stretching", "Sharp pain in Achilles", "Grinding in joint"]
        ),

        // ── ELBOW ─────────────────────────────────────────────

        KnowledgeCondition(
            name: "Elbow Stiffness",
            bodyArea: .elbow,
            keywords: ["elbow", "stiff", "bend", "straighten", "extension", "flexion", "locked"],
            summary: "Elbow stiffness often follows injury or immobilization. Active ROM exercises restore flexion and extension progressively.",
            exerciseNames: ["Elbow Flexion & Extension", "Active Elbow Flexion", "Elbow Extension Stretch"],
            redFlags: ["Sudden loss of extension", "Sharp pain with movement", "Numbness in fingers"]
        )
    ]

    // MARK: - Keyword Matching (RAG Retrieval)

    /// Filters conditions to top-3 matches using keyword overlap scoring.
    static func match(userInput: String, bodyArea: BodyArea?) -> [KnowledgeCondition] {
        let tokens = userInput.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        var scored = conditions.map { condition -> (KnowledgeCondition, Int) in
            var score = 0
            for keyword in condition.keywords {
                if tokens.contains(keyword) {
                    score += 1
                }
                // Bonus for substring matches (e.g., "knees" matches "knee")
                if tokens.contains(where: { $0.contains(keyword) || keyword.contains($0) }) {
                    score += 1
                }
            }
            return (condition, score)
        }

        if let area = bodyArea {
            scored = scored.filter { $0.0.bodyArea == area }
        }

        return scored
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(3)
            .map { $0.0 }
    }

    // MARK: - Exercise Resolution

    /// Maps exercise names back to real Exercise objects.
    static func resolveExercises(names: [String]) -> [Exercise] {
        let allExercises = Exercise.kneeExercises
            + Exercise.elbowExercises
            + Exercise.shoulderExercises
            + Exercise.hipExercises

        return names.compactMap { name in
            allExercises.first { $0.name == name }
        }
    }
}
