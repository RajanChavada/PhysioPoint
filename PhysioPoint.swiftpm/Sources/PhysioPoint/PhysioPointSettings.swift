import SwiftUI

/// Single source of truth for toggleable feature flags.
/// Uses `@AppStorage` so values persist via `UserDefaults` — no StorageService changes needed.
final class PhysioPointSettings: ObservableObject {
    @AppStorage("pp_rep_counting_beta") var repCountingBeta: Bool = false
}

// MARK: - Beta Rep Counting Toggle Row

struct BetaRepCountingToggleRow: View {
    @AppStorage("pp_rep_counting_beta") private var repBeta = false

    var body: some View {
        Toggle(isOn: $repBeta) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: "flask.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Rep Counting (Beta)")
                        .font(.subheadline.bold())
                }
                Text("Counts movement cycles. May be inaccurate — works best in side view with good lighting.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .tint(.orange)
        .padding(.vertical, 4)
    }
}
