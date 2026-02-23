import SwiftUI

// MARK: - Assistive Body Picker
// Simplified body area selection with large tappable rows

struct AssistiveBodyPickerView: View {
    @EnvironmentObject var appState: PhysioPointState

    var body: some View {
        List {
            ForEach(BodyArea.allCases) { area in
                NavigationLink(destination: AssistiveExerciseListView(area: area)) {
                    HStack(spacing: 16) {
                        Image(systemName: area.systemImage)
                            .font(.title)
                            .foregroundColor(PPColor.vitalityTeal)
                            .frame(width: 50, height: 50)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(area.rawValue)
                                .font(.title3.bold())
                            Text("Exercises for your \(area.rawValue.lowercased())")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .accessibilityLabel("\(area.rawValue) exercises")
                .accessibilityHint("Double-tap to see exercises for your \(area.rawValue.lowercased())")
            }
        }
        .navigationTitle("Where does it hurt?")
        .listStyle(.insetGrouped)
    }
}

// MARK: - Exercise List for a Body Area

struct AssistiveExerciseListView: View {
    let area: BodyArea
    @EnvironmentObject var appState: PhysioPointState

    /// Uses the curated per-area arrays (includes placeholder exercises for ankle)
    private var exercises: [Exercise] {
        switch area {
        case .knee:     return Exercise.kneeExercises
        case .elbow:    return Exercise.elbowExercises
        case .shoulder: return Exercise.shoulderExercises
        case .hip:      return Exercise.hipExercises
        case .ankle:    return Exercise.ankleExercises
        }
    }

    var body: some View {
        List {
            ForEach(exercises) { exercise in
                NavigationLink(destination: AssistiveExerciseView(exercise: exercise)) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(exercise.name)
                            .font(.title3.bold())
                        Text(exercise.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 8)
                }
                .accessibilityLabel("\(exercise.name). \(exercise.description)")
            }
        }
        .navigationTitle("\(area.rawValue) Exercises")
        .listStyle(.insetGrouped)
    }
}
