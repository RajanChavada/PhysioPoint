import SwiftUI

// MARK: - Recovery Pulse Card (HomeView)
// Contextual coaching blurb based on last feeling, session count, and today's progress

struct RecoveryPulseCard: View {
    @EnvironmentObject var storage: StorageService

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.pink)
                    .font(.title3)
                Text("Your Recovery Pulse")
                    .font(.headline)
            }

            Text(pulseBlurb)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(4)

            HStack(spacing: 16) {
                if storage.currentStreak >= 2 {
                    Label("\(storage.currentStreak)-day streak",
                          systemImage: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption.bold())
                }

                let done = storage.todayCompletedCount
                Label("\(done) of \(max(storage.totalSlotCount, 3)) done today",
                      systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption.bold())
            }
        }
        .padding(16)
        .physioGlass(.card)
    }

    // MARK: - Blurb Engine

    private var pulseBlurb: String {
        let feeling = storage.lastFeeling
        let count = storage.sessionCount
        let done = storage.todayCompletedCount

        switch (feeling, count, done) {

        case ("Harder", let n, _) where n < 5:
            return "You mentioned your last session felt tough — that's completely normal early on. Focus on slow, controlled reps today."

        case ("Harder", _, _):
            return "Tough sessions happen to everyone. Rest well tonight and remember — showing up is already half the battle."

        case ("Easier", _, let d) where d >= 3:
            return "You crushed today's full plan and it felt easy! Your recovery is clearly working. Keep the momentum going."

        case ("Easier", _, _):
            return "Your last session felt easier — that's your body getting stronger. Keep the streak going today."

        case ("Same", let n, _) where n >= 7:
            return "You've been consistent for over a week. Steady progress like this is exactly how long-term recovery works."

        case (nil, let n, _) where n == 0:
            return "Welcome to PhysioPoint. Start your first session and we'll track your recovery from day one."

        default:
            return "You're showing up consistently — that's the single most important thing in recovery. Keep it going."
        }
    }
}
