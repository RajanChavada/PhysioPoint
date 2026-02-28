import SwiftUI

// MARK: - Assistive Schedule View
// Simplified daily schedule with large text

struct AssistiveScheduleView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService

    var body: some View {
        List {
            if storage.dailyPlans.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                    Text("No schedule yet")
                        .font(.title2.bold())
                    Text("Go to Start Exercises to pick your exercises, then they'll appear here.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .listRowBackground(Color.clear)
            } else {
                ForEach(storage.dailyPlans) { plan in
                    Section(header: Text(plan.conditionName).font(.headline)) {
                        ForEach(plan.slots) { slot in
                            if let exercise = resolveExerciseFromSlot(slot) {
                                NavigationLink(destination: AssistiveExerciseView(exercise: exercise)) {
                                    HStack(spacing: 14) {
                                        Image(systemName: slot.isCompleted ? "checkmark.circle.fill" : "circle")
                                            .font(.title2)
                                            .foregroundColor(slot.isCompleted ? .green : .secondary)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(slot.exerciseName)
                                                .font(.title3.bold())
                                                .strikethrough(slot.isCompleted)
                                            Text("\(slot.label) • \(slot.exerciseReps) reps × \(slot.exerciseSets) sets")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("\(slot.exerciseName), \(slot.label), \(slot.isCompleted ? "completed" : "not done")")
                                }
                                .simultaneousGesture(TapGesture().onEnded {
                                    // Make sure we track which slot is being performed
                                    appState.activeSlotID = slot.id
                                })
                            } else {
                                // Fallback row if the exercise definition is missing
                                HStack(spacing: 14) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.title2)
                                        .foregroundColor(.orange)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(slot.exerciseName)
                                            .font(.title3.bold())
                                            .foregroundColor(.primary)
                                        Text("Exercise data missing")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("My Schedule")
        .listStyle(.insetGrouped)
    }
    
    // Support resolution of exercises purely from slot IDs
    private func resolveExerciseFromSlot(_ slot: PlanSlot) -> Exercise? {
        let allExs = Exercise.kneeExercises + Exercise.shoulderExercises + Exercise.elbowExercises + Exercise.hipExercises + Exercise.ankleExercises
        return allExs.first { $0.id == slot.exerciseID }
    }
}
