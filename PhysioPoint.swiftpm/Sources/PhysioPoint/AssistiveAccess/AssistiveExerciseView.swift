import SwiftUI

// MARK: - Assistive Exercise View
// ✅ Compiles on iOS 16+ — no iOS 26 APIs

struct AssistiveExerciseView: View {
    let exercise: Exercise
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService
    @State private var showAR = false

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer(minLength: 20)

                // Exercise image
                if let guideImage = exercise.guideImageName {
                    BundledImage(guideImage, maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 24)
                        .accessibilityLabel("Illustration of \(exercise.name)")
                }

                Text(exercise.name)
                    .font(.largeTitle).bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                Text(exercise.description)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 32)

                // Simple stats
                HStack(spacing: 32) {
                    VStack(spacing: 4) {
                        Text("\(exercise.reps)")
                            .font(.title.bold())
                        Text("times")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    VStack(spacing: 4) {
                        Text("\(exercise.holdSeconds)s")
                            .font(.title.bold())
                        Text("hold each")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .physioGlass(.card)

                // Step-by-step instructions (simplified)
                if !exercise.steps.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Steps")
                            .font(.title2.bold())

                        ForEach(exercise.steps, id: \.stepNumber) { step in
                            HStack(alignment: .top, spacing: 14) {
                                Text("\(step.stepNumber)")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(PPColor.actionBlue)
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title)
                                        .font(.headline)
                                    Text(step.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(20)
                    .physioGlass(.card)
                    .padding(.horizontal, 20)
                }

                // Start button — launches AR directly
                Button {
                    appState.selectedExercise = exercise
                    showAR = true
                } label: {
                    Text("Start Exercise")
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                }
                .buttonStyle(.borderedProminent)
                .tint(PPColor.actionBlue)
                .padding(.horizontal, 24)
                .accessibilityLabel("Start \(exercise.name)")

                Spacer(minLength: 40)
            }
        }
        .navigationTitle(exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showAR, onDismiss: {
            // Reset nav path when cover is dismissed
            appState.navigationPath.removeLast(appState.navigationPath.count)
        }) {
            // Wrap in NavigationStack so the full flow works:
            // SessionIntro → ExerciseAR → Summary
            NavigationStack(path: $appState.navigationPath) {
                SessionIntroView()
                    .environmentObject(appState)
                    .environmentObject(storage)
                    .navigationDestination(for: String.self) { destination in
                        switch destination {
                        case "ExerciseAR":
                            ExerciseARView()
                        case "Summary":
                            SummaryView()
                                .toolbar {
                                    ToolbarItem(placement: .navigationBarTrailing) {
                                        Button {
                                            showAR = false
                                        } label: {
                                            Label("Back to Home", systemImage: "house.fill")
                                                .font(.headline)
                                        }
                                    }
                                }
                        default:
                            EmptyView()
                        }
                    }
            }
            .environmentObject(appState)
            .environmentObject(storage)
        }
    }
}
