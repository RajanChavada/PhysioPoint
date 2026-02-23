import SwiftUI

// MARK: - Assistive AI Chat View
// Simplified chat with large buttons and quick prompts

struct AssistiveAIChatView: View {
    @EnvironmentObject var engine: PhysioGuardEngine
    @EnvironmentObject var appState: PhysioPointState
    @State private var input = ""
    @State private var hasAsked = false

    let quickPrompts = [
        "My knee hurts",
        "My back is sore",
        "My shoulder aches",
        "My ankle is swollen",
        "My hip hurts when I walk"
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !hasAsked {
                    Text("What is bothering you?")
                        .font(.title2.bold())
                        .padding(.top)

                    // Quick prompt buttons
                    ForEach(quickPrompts, id: \.self) { prompt in
                        Button {
                            sendMessage(prompt)
                        } label: {
                            Text(prompt)
                                .font(.title3)
                                .frame(maxWidth: .infinity, minHeight: 60)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel(prompt)
                    }

                    Divider().padding(.vertical)

                    // Manual input
                    TextField("Or type here...", text: $input)
                        .font(.title3)
                        .padding(14)
                        .physioGlass(.inputBar)
                        .submitLabel(.go)
                        .onSubmit {
                            guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            sendMessage(input)
                        }

                    if !input.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button {
                            sendMessage(input)
                        } label: {
                            Text("Ask PhysioPoint")
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity, minHeight: 60)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(PPColor.actionBlue)
                    }
                }

                // Response
                if let result = engine.messages.last(where: { $0.role == .assistant }) {
                    AssistiveResultCard(message: result)
                        .environmentObject(appState)
                }

                if engine.isLoading {
                    ProgressView("Finding exercises for you...")
                        .font(.title3)
                        .padding(.top, 16)
                }

                // Ask again button
                if hasAsked && !engine.isLoading {
                    Button {
                        engine.clearChat()
                        hasAsked = false
                        input = ""
                    } label: {
                        Label("Ask another question", systemImage: "arrow.counterclockwise")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 50)
                    }
                    .buttonStyle(.bordered)
                    .padding(.top)
                }
            }
            .padding(24)
        }
        .navigationTitle("Ask For Help")
    }

    private func sendMessage(_ text: String) {
        hasAsked = true
        Task {
            await engine.send(concern: text, bodyArea: nil)
        }
    }
}

// MARK: - Assistive Result Card

struct AssistiveResultCard: View {
    let message: ChatMessage
    @EnvironmentObject var appState: PhysioPointState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Condition name
            if let condition = message.conditionName {
                Label(condition, systemImage: "stethoscope")
                    .font(.headline)
                    .foregroundColor(PPColor.actionBlue)
            }

            // Response text
            Text(message.text)
                .font(.body)

            // Exercise suggestions
            if !message.suggestedExercises.isEmpty {
                VStack(spacing: 10) {
                    Text("Suggested Exercises")
                        .font(.headline)

                    ForEach(message.suggestedExercises) { exercise in
                        NavigationLink(destination: AssistiveExerciseView(exercise: exercise)) {
                            HStack {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(PPColor.vitalityTeal)
                                Text(exercise.name)
                                    .font(.headline)
                                Spacer()
                                Text("Start →")
                                    .font(.subheadline.bold())
                                    .foregroundColor(PPColor.actionBlue)
                            }
                            .padding(14)
                            .physioGlass(.card)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Encouragement
            if let enc = message.encouragement {
                Text(enc)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(20)
        .physioGlass(.card)
    }
}
