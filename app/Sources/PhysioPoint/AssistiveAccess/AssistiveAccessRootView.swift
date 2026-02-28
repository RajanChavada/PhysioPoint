import SwiftUI

// MARK: - Assistive Access Root View
// AssistiveAccess is a parallel view hierarchy, not a modifier,
// to allow completely different interaction paradigms for elderly users.
// ✅ No iOS 26 APIs — compiles in Swift Playgrounds

struct AssistiveAccessRootView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var engine: PhysioGuardEngine
    @EnvironmentObject var storage: StorageService
    @State private var navResetID = UUID()
    @AppStorage("hasDismissedGuidance") private var hasDismissedGuidance = false

    var body: some View {
        NavigationStack {
            List {
                // Assistive Guidance Banner (Empty State equivalent)
                if storage.dailyPlans.isEmpty && !hasDismissedGuidance {
                    Section {
                        AssistiveModeGuidanceBanner {
                            hasDismissedGuidance = true
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .padding(.bottom, 8)
                    }
                }

                // Recovery card (shown after first session)
                if storage.sessionCount > 0 || storage.lastFeeling != nil {
                    Section {
                        AccessibilityRecoveryCard()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }
                
                // Helpful Tip Blurb (Dynamic)
                if let card = InsightLibrary.selectCards(storage: storage).first {
                    Section {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: card.icon)
                                .font(.system(size: 24))
                                .foregroundColor(card.category.tint)
                                .padding(.top, 2)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(card.headline)
                                    .font(.title3.bold())
                                    .foregroundColor(.primary)
                                Text(card.body)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(card.headline). \(card.body)")
                    }
                }

                NavigationLink(destination: AssistiveBodyPickerView()) {
                    AssistiveMenuRow(
                        icon: "figure.walk",
                        title: "Start Exercises",
                        subtitle: "Do your exercises for today"
                    )
                }
                NavigationLink(destination: AssistiveScheduleView()) {
                    AssistiveMenuRow(
                        icon: "calendar",
                        title: "My Schedule",
                        subtitle: "See what to do today"
                    )
                }
                NavigationLink(destination: AssistiveLearnView()) {
                    AssistiveMenuRow(
                        icon: "book.fill",
                        title: "Learn About My Injury",
                        subtitle: "Guides for your recovery"
                    )
                }
                NavigationLink(destination: AssistiveAIChatView()) {
                    AssistiveMenuRow(
                        icon: "questionmark.circle.fill",
                        title: "Ask For Help",
                        subtitle: "Describe what hurts"
                    )
                }

                Section {
                    AssistiveAccessToggleRow()
                }
            }
            .navigationTitle("PhysioPoint")
            .listStyle(.insetGrouped)
        }
        .id(navResetID)
        .onReceive(NotificationCenter.default.publisher(for: .assistiveReturnHome)) { _ in
            navResetID = UUID()
        }
    }
}

// MARK: - Menu Row

struct AssistiveMenuRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(PPColor.actionBlue)
                .frame(width: 50, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Toggle Row (also used in ProfileView)

struct AssistiveAccessToggleRow: View {
    @AppStorage("simulateAssistiveAccess") private var simulate = false

    var body: some View {
        Toggle(isOn: $simulate) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Simplified Mode")
                    .font(.subheadline.bold())
                Text("Larger text, fewer steps — great for all users")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .tint(.blue)
        .padding(.vertical, 4)
    }
}

// MARK: - Assistive Mode Guidance Banner

struct AssistiveModeGuidanceBanner: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.dynamicTypeSize) var typeSize
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.point.right.fill")
                .foregroundStyle(.white)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text("Ready to begin?")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(.white)
                Text("Tap 'Start Exercises' below to create your first session.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }

            Spacer()

            Button {
                withAnimation { onDismiss() }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(minWidth: 44, minHeight: 44) // HIG tap target
        }
        .padding()
        .background(PPColor.actionBlue.gradient, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Guidance: Tap Start Exercises to create your first rehab plan.")
        .accessibilityAddTraits(.isStaticText)
    }
}
