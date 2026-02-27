import SwiftUI

// MARK: - Profile View (Stub)

struct ProfileView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService

    var body: some View {
        NavigationStack {
            ZStack {
                PPGradient.pageBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {

                        // Avatar + name
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [PPColor.vitalityTeal, PPColor.actionBlue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .shadow(color: PPColor.actionBlue.opacity(0.2), radius: 12, y: 4)

                                Image(systemName: "person.fill")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white)
                            }

                            Text("Patient")
                                .font(.title2.bold())

                            Text("PhysioPoint User")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)

                        // Stats strip
                        HStack(spacing: 0) {
                            profileStat(value: "\(storage.completedSlotCount)", label: "Sessions\nCompleted", icon: "checkmark.circle.fill")
                            Divider().frame(height: 50)
                            profileStat(value: "\(storage.dailyPlans.count)", label: "Active\nPlans", icon: "list.clipboard.fill")
                            Divider().frame(height: 50)
                            profileStat(value: "—", label: "Streak\nDays", icon: "flame.fill")
                        }
                        .padding(.vertical, 16)
                        .physioGlass(.card)

                        // Settings rows
                        VStack(spacing: 0) {
                            NavigationLink(destination: AccessibilitySettingsView()) {
                                settingsRow(icon: "accessibility", title: "Accessibility", color: PPColor.actionBlue)
                            }
                            
                            Divider().padding(.leading, 52)
                            
                            NavigationLink(destination: AboutView()) {
                                settingsRow(icon: "info.circle.fill", title: "About PhysioPoint", color: .secondary)
                            }
                        }
                        .physioGlass(.card)

                        // Disclaimer
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("For educational demo only. Not medical advice.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 8)

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func profileStat(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(PPColor.vitalityTeal)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func settingsRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 32)
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.001)) // Make entire row tappable
    }
}
