import SwiftUI

// MARK: - Body Area Learn View (Level 2)

struct BodyAreaLearnView: View {
    let area: LearnBodyArea

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {

                // Hero banner
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [PPColor.vitalityTeal.opacity(0.15), PPColor.actionBlue.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 160)

                    VStack(spacing: 12) {
                        BundledImage(area.imageName, maxHeight: 80)

                        Text(area.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)

                // Section header
                Text("Common Conditions")
                    .font(.title3.bold())
                    .padding(.horizontal)

                // Condition cards
                ForEach(area.conditions) { condition in
                    NavigationLink(destination: LearnConditionDetailView(condition: condition)) {
                        ConditionRowCard(condition: condition)
                    }
                    .buttonStyle(.plain)
                }

                // Quick info
                HStack(spacing: 16) {
                    infoChip(icon: "clock", text: "Recovery varies by severity")
                    infoChip(icon: "heart.text.square", text: "Consult your physio")
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Disclaimer
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("For educational purposes only. Not medical advice.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .background(PPGradient.pageBackground.ignoresSafeArea())
        .navigationTitle(area.displayName)
        .navigationBarTitleDisplayMode(.large)
    }

    private func infoChip(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(PPColor.actionBlue)
            Text(text)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

// MARK: - Condition Row Card

private struct ConditionRowCard: View {
    let condition: LearnCondition

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(PPColor.actionBlue.opacity(0.10))
                    .frame(width: 48, height: 48)

                Image(systemName: condition.systemIcon)
                    .font(.title3)
                    .foregroundColor(PPColor.actionBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(condition.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(condition.shortDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .padding(.horizontal)
    }
}
