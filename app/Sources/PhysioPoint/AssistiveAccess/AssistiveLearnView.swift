import SwiftUI

// MARK: - Assistive Learn View
// Simplified learn hub with large text and simple navigation

struct AssistiveLearnView: View {
    var body: some View {
        List {
            ForEach(LearnBodyArea.allCases) { area in
                NavigationLink(destination: AssistiveLearnAreaView(area: area)) {
                    HStack(spacing: 16) {
                        Image(systemName: area.systemImage)
                            .font(.title)
                            .foregroundColor(PPColor.vitalityTeal)
                            .frame(width: 50, height: 50)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(area.displayName)
                                .font(.title3.bold())
                            Text(area.subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .navigationTitle("Learn About Injuries")
        .listStyle(.insetGrouped)
    }
}

// MARK: - Assistive Learn Area View

struct AssistiveLearnAreaView: View {
    let area: LearnBodyArea

    var body: some View {
        List {
            ForEach(area.conditions) { condition in
                NavigationLink(destination: AssistiveLearnConditionView(condition: condition)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(condition.name)
                            .font(.title3.bold())
                        Text(condition.shortDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(area.displayName)
        .listStyle(.insetGrouped)
    }
}

// MARK: - Assistive Learn Condition View

struct AssistiveLearnConditionView: View {
    let condition: LearnCondition

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Overview
                Text(condition.overview)
                    .font(.body)
                    .padding(.horizontal)

                // Recovery phases
                if !condition.recoveryPhases.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recovery Steps")
                            .font(.title2.bold())

                        ForEach(Array(condition.recoveryPhases.enumerated()), id: \.offset) { index, phase in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 32, height: 32)
                                        .background(PPColor.actionBlue)
                                        .clipShape(Circle())
                                    Text(phase.title)
                                        .font(.headline)
                                }
                                Text(phase.duration)
                                    .font(.caption)
                                    .foregroundColor(PPColor.vitalityTeal)
                                Text(phase.description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .physioGlass(.card)
                        }
                    }
                    .padding(.horizontal)
                }

                // Techniques
                if !condition.techniques.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Helpful Techniques")
                            .font(.title2.bold())

                        ForEach(condition.techniques) { technique in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: technique.icon)
                                    .font(.title2)
                                    .foregroundColor(PPColor.actionBlue)
                                    .frame(width: 40)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(technique.name)
                                        .font(.headline)
                                    Text(technique.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
            .padding(.top)
        }
        .navigationTitle(condition.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
