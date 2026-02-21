import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var appState: PhysioPointState
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Session Complete!")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.green)
            
            if let metrics = appState.latestMetrics {
                VStack(spacing: 15) {
                    Text("Reps Completed: \(metrics.repsCompleted) / \(metrics.targetReps)")
                        .font(.title2)
                    
                    Text(String(format: "Best Angle: %.1f°", metrics.bestAngle))
                        .font(.title2)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
            
            Text("Disclaimer: This app is for informational and educational purposes only. For medical advice, diagnosis, or treatment, consult a healthcare professional.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Return to Home") {
                appState.navigationPath.removeLast(appState.navigationPath.count) // Go back to root
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Summary")
        .navigationBarBackButtonHidden(true)
    }
}
