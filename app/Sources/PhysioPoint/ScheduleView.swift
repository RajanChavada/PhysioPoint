import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject var appState: PhysioPointState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let condition = appState.selectedCondition {
                    // Header
                    VStack(spacing: 8) {
                        Text("Today's Plan")
                            .font(.largeTitle)
                            .bold()
                        
                        Text(condition.name)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Caregiver callout
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.purple)
                            Text("Have your helper ready — review each exercise together first")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.purple.opacity(0.06))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Exercise cards
                    ForEach(condition.recommendedExercises) { exercise in
                        exerciseCard(exercise: exercise)
                    }
                    
                    Spacer(minLength: 40)
                } else {
                    Text("No condition selected.")
                        .foregroundColor(.secondary)
                        .padding(.top, 40)
                }
            }
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func exerciseCard(exercise: Exercise) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                        .font(.headline)
                    
                    Text(exercise.visualDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    HStack(spacing: 16) {
                        Label("\(exercise.reps) reps", systemImage: "repeat")
                        Label("\(exercise.holdSeconds)s hold", systemImage: "timer")
                    }
                    .font(.caption2)
                    .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Thumbnail
                if let thumb = exercise.thumbnailName {
                    BundledImage(thumb, maxHeight: 70)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.tertiarySystemBackground))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: "figure.walk")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        )
                }
            }
            
            Button {
                appState.selectedExercise = exercise
                appState.navigationPath.append("SessionIntro")
            } label: {
                Text("View Guide & Start")
                    .font(.subheadline.bold())
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .padding(.horizontal)
    }
}
