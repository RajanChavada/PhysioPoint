import SwiftUI

struct SessionIntroView: View {
    @EnvironmentObject var appState: PhysioPointState
    
    var body: some View {
        VStack(spacing: 24) {
            if let exercise = appState.selectedExercise {
                Text(exercise.name)
                    .font(.largeTitle)
                    .bold()
                
                Text(exercise.visualDescription)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(spacing: 12) {
                    Text("Goal angle: \(Int(exercise.targetAngleRange.lowerBound))° - \(Int(exercise.targetAngleRange.upperBound))°")
                        .font(.headline)
                    Text("Hold time: \(exercise.holdSeconds) seconds")
                    Text("Target Reps: \(exercise.reps)")
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                
                Button("Begin Practice") {
                    appState.navigationPath.append("ExerciseAR")
                }
                .buttonStyle(.borderedProminent)
                .font(.title3)
                .padding(.top, 20)
                
            } else {
                Text("No exercise selected.")
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Exercise Intro")
    }
}
