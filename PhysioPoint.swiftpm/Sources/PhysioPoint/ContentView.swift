import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: PhysioPointState

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            VStack(spacing: 24) {
                Text("PhysioPoint")
                    .font(.largeTitle)
                    .bold()

                Text("An educational tool to help you follow home rehab exercises more consistently.\n\nThis is not medical advice.")
                    .multilineTextAlignment(.center)
                    .font(.subheadline)
                    .padding()

                Button("Get Started") {
                    appState.navigationPath.append("Triage")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "Triage":
                    TriageView()
                case "Schedule":
                    ScheduleView()
                case "SessionIntro":
                    SessionIntroView()
                case "ExerciseAR":
                    ExerciseARView()
                case "Summary":
                    SummaryView()
                default:
                    EmptyView()
                }
            }
        }
    }
}
