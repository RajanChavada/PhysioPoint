import SwiftUI

// MARK: - Learn Condition Detail View (Level 3)

struct LearnConditionDetailView: View {
    let condition: LearnCondition
    @EnvironmentObject var appState: PhysioPointState

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // 1. Overview
                sectionCard(title: "Overview", icon: "doc.text.fill", iconColor: PPColor.actionBlue) {
                    Text(condition.overview)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }

                // 2. Recovery Timeline
                sectionCard(title: "Recovery Timeline", icon: "chart.line.uptrend.xyaxis", iconColor: PPColor.vitalityTeal) {
                    RecoveryTimelineView(phases: condition.recoveryPhases)
                }

                // 3. Therapy Techniques
                sectionCard(title: "Techniques", icon: "hand.raised.fill", iconColor: .orange) {
                    TechniqueCardsView(techniques: condition.techniques)
                }

                // 4. At-Home Rehab
                sectionCard(title: "At-Home Rehab", icon: "figure.run", iconColor: PPColor.vitalityTeal) {
                    AtHomeRehabSection(
                        exerciseNames: condition.recommendedExerciseNames,
                        appState: appState
                    )
                }

                // 5. When to See a Doctor
                sectionCard(title: "When to See a Doctor", icon: "exclamationmark.triangle.fill", iconColor: .red) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(condition.redFlags, id: \.self) { flag in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.top, 2)
                                Text(flag)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Disclaimer
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                    Text("For educational purposes only. Not a substitute for professional medical advice.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .padding(.top, 8)
        }
        .background(PPGradient.pageBackground.ignoresSafeArea())
        .navigationTitle(condition.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Section Card

    private func sectionCard<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
                Text(title)
                    .font(.headline)
            }

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Recovery Timeline

private struct RecoveryTimelineView: View {
    let phases: [RecoveryPhase]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                HStack(alignment: .top, spacing: 14) {
                    // Timeline connector
                    VStack(spacing: 0) {
                        Circle()
                            .fill(phaseColor(index))
                            .frame(width: 14, height: 14)

                        if index < phases.count - 1 {
                            Rectangle()
                                .fill(phaseColor(index).opacity(0.3))
                                .frame(width: 2)
                                .frame(minHeight: 50)
                        }
                    }

                    // Phase content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(phase.title)
                                .font(.subheadline.bold())
                            Text(phase.duration)
                                .font(.caption)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(phaseColor(index).opacity(0.8))
                                .cornerRadius(6)
                        }
                        Text(phase.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 12)
                    }
                }
            }
        }
    }

    private func phaseColor(_ index: Int) -> Color {
        let colors: [Color] = [.red, .orange, PPColor.vitalityTeal, PPColor.actionBlue]
        return colors[index % colors.count]
    }
}

// MARK: - Technique Cards

private struct TechniqueCardsView: View {
    let techniques: [TherapyTechnique]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(techniques) { technique in
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: technique.icon)
                            .font(.title3)
                            .foregroundColor(PPColor.actionBlue)

                        Text(technique.name)
                            .font(.subheadline.bold())
                            .foregroundColor(.primary)

                        Text(technique.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding(14)
                    .frame(width: 180, alignment: .leading)
                    .background(PPColor.actionBlue.opacity(0.06))
                    .cornerRadius(14)
                }
            }
        }
    }
}

// MARK: - At-Home Rehab Section

private struct AtHomeRehabSection: View {
    let exerciseNames: [String]
    let appState: PhysioPointState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("These exercises are available in your AR session tracker.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 4)

            ForEach(exerciseNames, id: \.self) { name in
                HStack(spacing: 10) {
                    Image(systemName: "figure.walk")
                        .font(.subheadline)
                        .foregroundColor(PPColor.vitalityTeal)

                    Text(name)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer()

                    Button {
                        // Find the exercise by name and navigate to it
                        let allExercises = Exercise.kneeExercises
                            + Exercise.elbowExercises
                            + Exercise.shoulderExercises
                            + Exercise.hipExercises
                        if let exercise = allExercises.first(where: { $0.name == name }) {
                            appState.selectedExercise = exercise
                            appState.selectedTab = .home
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                appState.navigationPath.append("SessionIntro")
                            }
                        }
                    } label: {
                        Text("Start →")
                            .font(.caption.bold())
                            .foregroundColor(PPColor.actionBlue)
                    }
                }
                .padding(.vertical, 6)

                if name != exerciseNames.last {
                    Divider()
                }
            }
        }
    }
}
