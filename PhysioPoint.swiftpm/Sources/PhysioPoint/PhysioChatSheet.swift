import SwiftUI
import Combine

// MARK: - Chat Sheet

struct PhysioChatSheet: View {
    @EnvironmentObject var engine: PhysioGuardEngine
    @EnvironmentObject var appState: PhysioPointState
    @State private var input = ""
    @State private var selectedArea: BodyArea? = nil

    /// Starter prompts for judges — tap to immediately see AI in action.
    private let starterPrompts = [
        "My knee hurts when I go down stairs",
        "I have lower back pain from sitting",
        "My shoulder clicks when I raise my arm"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Body area quick filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        areaPill(label: "Any", area: nil)
                        areaPill(label: "Knee", area: .knee)
                        areaPill(label: "Shoulder", area: .shoulder)
                        areaPill(label: "Back", area: .hip)
                        areaPill(label: "Ankle", area: .ankle)
                        areaPill(label: "Elbow", area: .elbow)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                Divider()

                // Message list — fills available space
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if engine.messages.isEmpty {
                                starterPromptsSection
                            }

                            ForEach(engine.messages) { msg in
                                ChatBubble(message: msg)
                                    .environmentObject(appState)
                                    .id(msg.id)
                            }

                            if engine.isLoading {
                                typingIndicator
                            }
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: engine.messages.count) { _, _ in
                        if let last = engine.messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                Divider()

                // Input bar
                HStack(spacing: 10) {
                    TextField("Describe your concern...", text: $input, axis: .vertical)
                        .lineLimit(1...3)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                    Button {
                        let text = input.trimmingCharacters(in: .whitespaces)
                        guard !text.isEmpty else { return }
                        input = ""
                        Task { await engine.send(concern: text, bodyArea: selectedArea) }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(
                                input.trimmingCharacters(in: .whitespaces).isEmpty
                                ? Color.gray : PPColor.actionBlue
                            )
                    }
                    .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || engine.isLoading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .navigationTitle("PhysioPoint AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !engine.messages.isEmpty {
                        Button { engine.clearChat() } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.caption)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Starter Prompts

    private var starterPromptsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Welcome message
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(PPColor.actionBlue)
                    Text("PhysioPoint AI")
                        .font(.headline)
                }
                Text("Tell me what's bothering you and I'll find the right exercises for you.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if !engine.hasLLM {
                    Text("Using built-in exercise matching. Apple Intelligence makes responses even better when available.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }

                Text("This is educational guidance only, not medical advice.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 4)

            // Tap-to-ask chips
            Text("Try asking:")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            ForEach(starterPrompts, id: \.self) { prompt in
                Button {
                    Task { await engine.send(concern: prompt, bodyArea: selectedArea) }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "text.bubble")
                            .font(.caption)
                            .foregroundColor(PPColor.actionBlue)
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "arrow.right.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Area Pill

    private func areaPill(label: String, area: BodyArea?) -> some View {
        Button {
            selectedArea = area
        } label: {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(selectedArea == area ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(
                        selectedArea == area
                        ? PPColor.actionBlue
                        : Color(.systemGray5)
                    )
                )
        }
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(PPColor.actionBlue.opacity(0.5))
                    .frame(width: 8, height: 8)
                    .offset(y: engine.isLoading ? -4 : 0)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(i) * 0.15),
                        value: engine.isLoading
                    )
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
