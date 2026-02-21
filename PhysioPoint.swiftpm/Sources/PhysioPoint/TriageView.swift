import SwiftUI

struct TriageView: View {
    @EnvironmentObject var appState: PhysioPointState
    
    var body: some View {
        VStack {
            Text("Where is your main issue today?")
                .font(.title2)
                .bold()
                .padding()
            
            Text("Select an issue below (Knee Demo):")
                .foregroundColor(.secondary)
            
            List(Condition.library) { condition in
                Button {
                    appState.selectedCondition = condition
                    appState.navigationPath.append("Schedule")
                } label: {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(condition.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(condition.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 5)
                }
            }
            
            Spacer()
        }
        .navigationTitle("Triage")
    }
}
