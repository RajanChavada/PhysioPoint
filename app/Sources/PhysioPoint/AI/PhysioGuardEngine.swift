import SwiftUI

// MARK: - PhysioGuard Engine
// PhysioGuardEngine runs entirely on-device — no network calls.
// Responses are generated from KnowledgeStore.swift (static rehab data).

/// Observable session manager for the AI chat.
/// Works in two modes:
///   1. **Rule-based** (always available) — uses KnowledgeStore keyword matching directly
///   2. **LLM-enhanced** (Xcode 26 + Apple Intelligence) — on-device model for richer responses
@MainActor
class PhysioGuardEngine: ObservableObject {

    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false

    /// Whether the on-device LLM is available at runtime
    var hasLLM: Bool {
        #if canImport(FoundationModels)
        return _checkLLMAvailability()
        #else
        return false
        #endif
    }

    // MARK: - Send Message

    func send(concern: String, bodyArea: BodyArea?) async {
        let userMessage = ChatMessage(text: concern, role: .user)
        messages.append(userMessage)
        isLoading = true

        defer { isLoading = false }

        // Brief delay for typing indicator
        try? await Task.sleep(nanoseconds: 600_000_000)

        // Step 1: Retrieve matching conditions (RAG layer — always works)
        let matched = KnowledgeStore.match(userInput: concern, bodyArea: bodyArea)

        // Step 2: Try LLM if available, else rule-based
        #if canImport(FoundationModels)
        if hasLLM {
            await _sendWithLLM(concern: concern, bodyArea: bodyArea, matched: matched)
            return
        }
        #endif

        _sendRuleBased(matched: matched)
    }

    // MARK: - Rule-Based Response (Always Available)

    private func _sendRuleBased(matched: [KnowledgeCondition]) {
        if matched.isEmpty {
            messages.append(ChatMessage(
                text: "I couldn't find a close match. Try selecting a body area above or describe the location of your discomfort in more detail.",
                role: .assistant,
                encouragement: "Our Recovery Knowledge Hub has guides for all major body areas."
            ))
            return
        }

        let top = matched[0]
        let exercises = KnowledgeStore.resolveExercises(names: top.exerciseNames)

        let reasoning: String
        if matched.count > 1 {
            let otherNames = matched.dropFirst().map { $0.name }.joined(separator: " or ")
            reasoning = "Based on your description, this most closely matches \(top.name). It could also relate to \(otherNames)."
        } else {
            reasoning = "Based on your description, this most closely matches \(top.name). \(top.summary)"
        }

        var fullText = reasoning
        if !top.redFlags.isEmpty {
            fullText += "\n\n⚠️ See a doctor if: " + top.redFlags.joined(separator: "; ") + "."
        }
        fullText += "\n\nThis is educational guidance only, not medical advice."

        let encouragements = [
            "Your recovery journey starts with one small step — you've got this!",
            "Every rep brings you closer to feeling like yourself again.",
            "Movement is medicine — even gentle exercises make a real difference.",
            "Consistency beats intensity. Start small and build from there."
        ]

        messages.append(ChatMessage(
            text: fullText,
            role: .assistant,
            conditionName: top.name,
            suggestedExercises: exercises,
            encouragement: encouragements.randomElement()
        ))
    }

    // MARK: - Clear

    func clearChat() {
        messages.removeAll()
    }
}

// MARK: - LLM Extension (only compiles in Xcode 26+)

#if canImport(FoundationModels)
import FoundationModels

extension PhysioGuardEngine {

    func _checkLLMAvailability() -> Bool {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return true
        default:
            return false
        }
    }

    func _sendWithLLM(concern: String, bodyArea: BodyArea?, matched: [KnowledgeCondition]) async {
        let conditionBlock = matched
            .map { c in
                """
                Condition: \(c.name)
                Summary: \(c.summary)
                Exercises: \(c.exerciseNames.joined(separator: ", "))
                Red flags: \(c.redFlags.joined(separator: "; "))
                """
            }
            .joined(separator: "\n\n")

        let areaContext = bodyArea.map { "The user is focused on: \($0.rawValue.capitalized)." } ?? ""

        let instructions = Instructions(
            """
            You are PhysioPoint's recovery assistant. \
            You only answer questions about physical therapy and musculoskeletal recovery.
            \(areaContext)

            Use ONLY the following conditions from the knowledge base. \
            Do not invent conditions or exercises not listed below.

            \(conditionBlock.isEmpty ? "No matching conditions found." : conditionBlock)

            If the user's concern does not match any condition, say: \
            "I couldn't find a close match. Try selecting a body area or describe the location of your discomfort."

            Always end with: "This is educational guidance only, not medical advice."
            """
        )

        let promptText = """
        The user says: "\(concern)"

        Based on the conditions above, identify the most likely condition, \
        explain why in one sentence, and list the most appropriate exercises.
        """

        let session = LanguageModelSession(instructions: instructions)

        do {
            let response = try await session.respond(to: promptText)
            let text = "\(response)"

            let condName = matched.first?.name
            let exercises = KnowledgeStore.resolveExercises(
                names: matched.first?.exerciseNames ?? []
            )

            messages.append(ChatMessage(
                text: text,
                role: .assistant,
                conditionName: condName,
                suggestedExercises: exercises,
                encouragement: "Your recovery journey starts with one small step — you've got this!"
            ))
        } catch {
            // Fall back to rule-based if LLM fails
            _sendRuleBased(matched: KnowledgeStore.match(userInput: concern, bodyArea: bodyArea))
        }
    }
}
#endif
