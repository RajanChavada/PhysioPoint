import SwiftUI

// MARK: - Accessibility Recovery Card
// Simplified large-text version for Assistive Access mode

struct AccessibilityRecoveryCard: View {
    @EnvironmentObject var storage: StorageService

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 40))
                .foregroundColor(PPColor.actionBlue)

            Text(blurb)
                .font(.title3.bold())
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .lineSpacing(6)
                .padding(.horizontal)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(PPColor.actionBlue.opacity(0.08))
        .cornerRadius(20)
        .padding(.horizontal)
    }

    private var blurb: String {
        let done = storage.todayCompletedCount
        let streak = storage.currentStreak
        let feeling = storage.lastFeeling

        if done >= 3 {
            return "You completed all your exercises today. 🎉 Keep this up and you'll see real improvement in your mobility."
        } else if streak >= 3 && feeling == "Easier" {
            return "You've done \(streak) days in a row and your last session felt easier. You're on track — keep going!"
        } else if feeling == "Harder" {
            return "Your last session was tough. That's okay — rest up and try again today. Recovery isn't a straight line."
        } else if done > 0 {
            return "You've completed \(done) exercise\(done == 1 ? "" : "s") today. Finish the rest to keep your recovery on track."
        } else {
            return "Start today's first session to keep your recovery moving forward."
        }
    }
}
