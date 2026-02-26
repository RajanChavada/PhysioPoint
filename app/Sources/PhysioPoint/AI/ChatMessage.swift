import Foundation

// MARK: - Chat Role

enum ChatRole {
    case user
    case assistant
    case system
}

// MARK: - Chat Message

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let role: ChatRole
    var conditionName: String? = nil
    var suggestedExercises: [Exercise] = []
    var encouragement: String? = nil
}
