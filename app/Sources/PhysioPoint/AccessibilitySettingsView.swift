import SwiftUI

struct AccessibilitySettingsView: View {
    @AppStorage("simulateAssistiveAccess") private var simulateAssistiveAccess = false
    @AppStorage("enableRepConsistency") private var enableRepConsistency = false
    
    var body: some View {
        ZStack {
            PPGradient.pageBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Welcome / Explanation Blurb
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            Image(systemName: "accessibility")
                                .font(.title)
                                .foregroundColor(PPColor.actionBlue)
                            Text("Inclusive Design")
                                .font(.title3.bold())
                        }
                        
                        Text("PhysioPoint is designed to be usable by everyone, including those with limited mobility, visual impairments, or cognitive constraints. We leverage native Apple frameworks like Dynamic Type to ensure text is always legible, and we maintain high-contrast UI elements to reduce cognitive load during recovery.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(24)
                    .physioGlass(.card)
                    
                    // Assistive Access Simulation
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Testing Tools")
                            .font(.headline)
                            .padding(.horizontal, 4)
                        
                        VStack(spacing: 0) {
                            Toggle(isOn: $simulateAssistiveAccess.animation(.spring())) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Simulate Assistive Access")
                                        .font(.system(.body, design: .rounded).weight(.medium))
                                    Text("Replaces the standard UI with a highly simplified, large-format interface mimicking iOS Assistive Access.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .tint(PPColor.vitalityTeal)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            
                            Divider().padding(.leading, 16)
                            
                            Toggle(isOn: $enableRepConsistency.animation(.spring())) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("AI Rep Consistency (Beta)")
                                        .font(.system(.body, design: .rounded).weight(.medium))
                                    Text("Enables advanced per-rep consistency tracking in the summary view.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .tint(PPColor.vitalityTeal)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                        }
                        .physioGlass(.card)
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("Accessibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}
