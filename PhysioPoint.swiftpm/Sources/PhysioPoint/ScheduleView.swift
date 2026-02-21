import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var appState: PhysioPointState
    
    var body: some View {
        VStack(spacing: 20) {
            if let condition = appState.selectedCondition {
                Text("Today's Plan")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)
                
                Text(condition.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                List(condition.recommendedExercises) { exercise in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(exercise.name)
                            .font(.headline)
                        
                        Text("\(exercise.reps) reps • Hold for \(exercise.holdSeconds)s")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Start Now") {
                            appState.selectedExercise = exercise
                            appState.navigationPath.append("SessionIntro")
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 5)
                    }
                    .padding(.vertical, 10)
                }
            } else {
                Text("No condition selected.")
            }
            Spacer()
        }
        .navigationTitle("Schedule")
    }
}
