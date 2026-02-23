import SwiftUI

// MARK: - Learn Home View (Level 1)

struct LearnHomeView: View {
    @State private var searchText = ""

    private var filteredAreas: [LearnBodyArea] {
        if searchText.isEmpty { return LearnBodyArea.allCases }
        return LearnBodyArea.allCases.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.subtitle.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PPGradient.pageBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {

                        // Hero header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recovery\nKnowledge Hub")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [PPColor.vitalityTeal, PPColor.actionBlue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Explore guides, techniques, and tips\nfor better healing.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)

                        // Search bar
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search conditions, body parts...", text: $searchText)
                                .font(.subheadline)
                        }
                        .padding(12)
                        .physioGlass(.inputBar)

                        // 2×2 body area grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredAreas) { area in
                                NavigationLink(destination: BodyAreaLearnView(area: area)) {
                                    BodyAreaCard(area: area)
                                }
                                .buttonStyle(.plain)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("\(area.displayName) recovery guide. \(area.subtitle)")
                                .accessibilityHint("Double-tap to open exercises for \(area.displayName)")
                            }
                        }

                        // Recovery Essentials section
                        Text("Recovery Essentials")
                            .font(.title3.bold())
                            .padding(.top, 8)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(RecoveryEssential.all) { essential in
                                    NavigationLink(destination: EssentialDetailView(essential: essential)) {
                                        EssentialCard(essential: essential)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }

                // AI Chat floating button
                ChatFABOverlay()
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Body Area Card

private struct BodyAreaCard: View {
    let area: LearnBodyArea

    var body: some View {
        VStack(spacing: 10) {
            // Custom anatomical icon from Resources/
            BundledImage(area.imageName, maxHeight: 70)
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(PPColor.actionBlue.opacity(0.06))
                )

            Text(area.displayName)
                .font(.headline)
                .foregroundColor(.primary)

            Text(area.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .physioGlass(.card)
    }
}

// MARK: - Essential Card

private struct EssentialCard: View {
    let essential: RecoveryEssential

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: essential.icon)
                .font(.title2)
                .foregroundColor(PPColor.actionBlue)

            Text(essential.title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 140, alignment: .leading)
        .frame(minHeight: 50)
        .padding(14)
        .physioGlass(.card)
    }
}

// MARK: - Essential Detail View

struct EssentialDetailView: View {
    let essential: RecoveryEssential

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(PPColor.actionBlue.opacity(0.12))
                            .frame(width: 56, height: 56)
                        Image(systemName: essential.icon)
                            .font(.title2)
                            .foregroundColor(PPColor.actionBlue)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(essential.title)
                            .font(.title2.bold())
                        Text(essential.summary)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Tips
                Text("Key Tips")
                    .font(.title3.bold())

                ForEach(Array(essential.tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(PPColor.vitalityTeal.opacity(0.15))
                                .frame(width: 28, height: 28)
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(PPColor.vitalityTeal)
                        }
                        Text(tip)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Disclaimer
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("For educational purposes only. Always consult a healthcare professional.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 16)
            }
            .padding(20)
        }
        .navigationTitle(essential.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
