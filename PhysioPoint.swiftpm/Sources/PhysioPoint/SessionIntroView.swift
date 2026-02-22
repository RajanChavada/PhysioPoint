import SwiftUI

struct SessionIntroView: View {
    @EnvironmentObject var appState: PhysioPointState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let exercise = appState.selectedExercise {
                    // Exercise header
                    VStack(spacing: 8) {
                        Text(exercise.name)
                            .font(.largeTitle)
                            .bold()
                        
                        Text(exercise.bodyArea.rawValue.uppercased())
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.top)
                    
                    // Tracking mode badge — all exercises are now AR-tracked
                    if let config = exercise.trackingConfig {
                        HStack(spacing: 6) {
                            Image(systemName: "dot.radiowaves.left.and.right")
                                .font(.caption2)
                            Text("AR Tracked • \(trackingModeLabel(config.mode))")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.12))
                        .cornerRadius(8)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "timer")
                                .font(.system(size: 13))
                            Text("Timer-Guided")
                                .font(.system(size: 12, weight: .semibold))
                            Text("• Follow the steps below")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    Text(exercise.visualDescription)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    // Quick stats
                    HStack(spacing: 24) {
                        statBadge(icon: "target", label: "\(Int(exercise.targetAngleRange.lowerBound))°–\(Int(exercise.targetAngleRange.upperBound))°", subtitle: "Target")
                        statBadge(icon: "timer", label: "\(exercise.holdSeconds)s", subtitle: "Hold")
                        statBadge(icon: "repeat", label: "\(exercise.reps)", subtitle: "Reps")
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Step-by-step guide
                    if !exercise.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("How to Perform")
                                .font(.title3.bold())
                                .padding(.horizontal)
                            
                            Text("Review these steps with your helper before starting")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                        
                        ForEach(exercise.steps) { step in
                            stepCard(step: step)
                        }
                    }
                    
                    // Caregiver tip
                    if let tip = exercise.caregiverTip {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.purple)
                                Text("Helper's Tip")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                            }
                            Text(tip)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.purple.opacity(0.08))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }
                    
                    // Camera position hint
                    if let config = exercise.trackingConfig {
                        HStack(spacing: 8) {
                            Image(systemName: config.cameraPosition == .side ? "ipad.landscape" : "ipad")
                                .font(.system(size: 14))
                            Text("Best camera position: \(config.cameraPosition == .side ? "Side view" : "Front view")")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.06))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Begin button
                    Button {
                        appState.navigationPath.append("ExerciseAR")
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Begin Practice")
                                .bold()
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    Text("For educational demo only. Not medical advice.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 20)
                    
                } else {
                    Text("No exercise selected.")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Exercise Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Components
    
    private func statBadge(icon: String, label: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
            Text(label)
                .font(.headline)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 70)
    }
    
    private func stepCard(step: ExerciseStep) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 32, height: 32)
                Text("\(step.stepNumber)")
                    .font(.callout.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(step.title)
                    .font(.headline)
                
                // Show image if available
                if let imageName = step.imageName {
                    BundledImage(imageName, maxHeight: 160)
                }
                
                Text(step.instruction)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private func trackingModeLabel(_ mode: TrackingMode) -> String {
        switch mode {
        case .angleBased:          return "Angle-Based"
        case .holdDuration:        return "Hold Duration"
        case .rangeOfMotion:       return "Range of Motion"
        case .repetitionCounting:  return "Rep Counting"
        }
    }
}
