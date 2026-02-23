import SwiftUI

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ChatMessage
    @EnvironmentObject var appState: PhysioPointState

    var body: some View {
        switch message.role {
        case .user:
            userBubble
        case .assistant:
            assistantBubble
        case .system:
            systemBubble
        }
    }

    // MARK: - User Bubble

    private var userBubble: some View {
        HStack {
            Spacer()
            Text(message.text)
                .font(.subheadline)
                .padding(12)
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        colors: [PPColor.actionBlue, PPColor.vitalityTeal],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .frame(maxWidth: 280, alignment: .trailing)
        }
    }

    // MARK: - Assistant Bubble

    private var assistantBubble: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Condition badge
            if let condition = message.conditionName {
                Label(condition, systemImage: "stethoscope")
                    .font(.caption.bold())
                    .foregroundColor(PPColor.actionBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(PPColor.actionBlue.opacity(0.10))
                    .cornerRadius(8)
            }

            // Reasoning text
            Text(message.text)
                .font(.subheadline)
                .foregroundColor(.primary)

            // Exercise cards — tappable CTAs
            if !message.suggestedExercises.isEmpty {
                VStack(spacing: 6) {
                    ForEach(message.suggestedExercises) { exercise in
                        Button {
                            appState.selectedExercise = exercise
                            appState.selectedTab = .home
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                appState.navigationPath.append("SessionIntro")
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.caption)
                                    .foregroundColor(PPColor.vitalityTeal)
                                Text(exercise.name)
                                    .font(.subheadline.bold())
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("Start →")
                                    .font(.caption.bold())
                                    .foregroundColor(PPColor.actionBlue)
                            }
                            .padding(10)
                            .physioGlass(.card)
                        }
                    }
                }
            }

            // Encouragement
            if let enc = message.encouragement {
                Text(enc)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(12)
        .physioGlass(.card)
        .frame(maxWidth: 300, alignment: .leading)
    }

    // MARK: - System Bubble

    private var systemBubble: some View {
        Text(message.text)
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, 4)
    }
}
