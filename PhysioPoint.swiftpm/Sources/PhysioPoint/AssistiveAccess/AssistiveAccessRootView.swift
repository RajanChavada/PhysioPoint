import SwiftUI

// MARK: - Assistive Access Root View
// ✅ No iOS 26 APIs — compiles in Swift Playgrounds

struct AssistiveAccessRootView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var engine: PhysioGuardEngine
    @EnvironmentObject var storage: StorageService
    @State private var navResetID = UUID()

    var body: some View {
        NavigationStack {
            List {
                // Recovery card (shown after first session)
                if storage.sessionCount > 0 || storage.lastFeeling != nil {
                    Section {
                        AccessibilityRecoveryCard()
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
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
