import SwiftUI

// MARK: - Session Feedback

enum SessionFeeling: String, CaseIterable {
    case easier = "Easier"
    case same   = "Same"
    case harder = "Harder"

    var emoji: String {
        switch self {
        case .easier: return "😎"
        case .same:   return "🤔"
        case .harder: return "😫"
        }
    }
}

// MARK: - SummaryView

struct SummaryView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService
    @EnvironmentObject var settings: PhysioPointSettings
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFeeling: SessionFeeling? = nil
    @State private var animateCheckmark = false
    @State private var animateCards = false

    private var metrics: SessionMetrics {
        appState.latestMetrics ?? SessionMetrics(
            bestAngle: 92,
            repsCompleted: 3,
            targetReps: 3,
            timeInGoodForm: 21,
            repResults: [
                RepResult(repNumber: 1, peakAngle: 90, timeInTarget: 7, quality: .good),
                RepResult(repNumber: 2, peakAngle: 88, timeInTarget: 6, quality: .fair),
                RepResult(repNumber: 3, peakAngle: 92, timeInTarget: 8, quality: .good),
            ],
            previousBestAngle: 88,
            previousTimeInForm: 13
        )
    }

    var body: some View {
        ZStack {
            PPGradient.pageBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        heroSection
                        statsCard
                        ptFeedbackCard
                        vsLastSessionCard
                        bottomRow
                        feelingResponseCard
                        streakAndNextSection
                        disclaimerText
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }

                doneButton
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle("")
        .onAppear {
            // Mark the active schedule slot as complete
            if let slotID = appState.activeSlotID {
                storage.markSlotComplete(slotID)
            }
            // Persist session metrics
            storage.saveSessionMetrics(metrics)

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
                animateCheckmark = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                animateCards = true
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(PPGradient.action)
                    .frame(width: 72, height: 72)
                    .shadow(color: PPColor.vitalityTeal.opacity(0.3), radius: 12, y: 4)

                Image(systemName: "checkmark")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(animateCheckmark ? 1 : 0.3)
                    .opacity(animateCheckmark ? 1 : 0)
            }
            .padding(.top, 24)

            Text("Session Complete!")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(praiseMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - Quality Cards

    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                SummaryMetricCard(
                    value: metrics.controlLabel,
                    label: "Movement control",
                    sublabel: "smoothness rating",
                    icon: "waveform.path.ecg",
                    color: .blue
                )

                SummaryMetricCard(
                    value: String(format: "%.0f%%", rangeAchieved * 100),
                    label: "Range achieved",
                    sublabel: "of target bend",
                    icon: "ruler.fill",
                    color: .orange
                )
            }
            
            // Beta Rep Counter
            if settings.repCountingBeta {
                HStack(spacing: 8) {
                    Image(systemName: "flask.fill")
                        .foregroundColor(.orange)
                    Text("Rep counting (beta): \(metrics.repsCompleted) cycles detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    private var rangeAchieved: Double {
        guard let config = appState.selectedExercise?.trackingConfig else { return 0 }
        let target = config.targetRange.upperBound
        return min(1.0, metrics.bestAngle / target)
    }

    private var ptFeedbackCard: some View {
        VStack(spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "person.fill.checkmark")
                    .foregroundColor(PPColor.actionBlue)
                    .font(.subheadline)
                Text("Your PT Feedback")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }

            // ── Positive row ──
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("What you did well")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(metrics.sessionFeedback.positiveObservation.isEmpty ? "Great job completing your session!" : metrics.sessionFeedback.positiveObservation)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineSpacing(3)
                }
            }

            Divider().opacity(0.4)

            // ── Growth row ──
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Focus for next time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                    Text(metrics.sessionFeedback.growthObservation.isEmpty ? "Keep up the consistent effort." : metrics.sessionFeedback.growthObservation)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                        .lineSpacing(3)
                }
            }

            Divider().opacity(0.4)

            // ── Journey message ──
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(PPColor.actionBlue)
                    .font(.subheadline)
                Text(metrics.sessionFeedback.journeyMessage.isEmpty ? "Consistency is the path to recovery." : metrics.sessionFeedback.journeyMessage)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                    .italic()
            }
        }
        .padding(16)
        .physioGlass(.card)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Vs. Last Session

    private var vsLastSessionCard: some View {
        Group {
            if metrics.angleDelta != nil || metrics.timeDelta != nil {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Vs. Last Session")
                        .font(.headline)

                    if let ad = metrics.angleDelta {
                        comparisonRow(label: "Best Angle:", delta: ad, suffix: "°")
                    }
                    if let td = metrics.timeDelta {
                        comparisonRow(label: "Time in Form:", delta: td, suffix: "s")
                    }
                }
                .padding(16)
                .physioGlass(.card)
                .opacity(animateCards ? 1 : 0)
                .offset(y: animateCards ? 0 : 20)
            }
        }
    }

    private func comparisonRow(label: String, delta: Double, suffix: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            HStack(spacing: 2) {
                Text(delta >= 0 ? "+\(Int(delta))\(suffix)" : "\(Int(delta))\(suffix)")
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(delta >= 0 ? PPColor.vitalityTeal : .orange)
                Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                    .font(.caption)
                    .foregroundColor(delta >= 0 ? PPColor.vitalityTeal : .orange)
            }
        }
    }

    // MARK: - Bottom Row: Today's Plan + Feeling

    private var bottomRow: some View {
        HStack(spacing: 12) {
            // Today's Plan progress ring — reads live from storage
            VStack(spacing: 10) {
                Text("Today's Plan")
                    .font(.system(size: 14, weight: .semibold))

                ZStack {
                    Circle()
                        .stroke(PPColor.actionBlue.opacity(0.12), lineWidth: 6)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: planTotal > 0 ? CGFloat(planCompleted) / CGFloat(planTotal) : 0)
                        .stroke(PPColor.vitalityTeal, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(planCompleted) of \(planTotal)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                        Text("done")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                // All done banner
                if planCompleted == planTotal {
                    Text("All done! 🎉")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(PPColor.vitalityTeal)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .physioGlass(.card)

            // How did it feel?
            VStack(spacing: 10) {
                Text("How did it feel?")
                    .font(.system(size: 14, weight: .semibold))

                VStack(spacing: 8) {
                    ForEach(SessionFeeling.allCases, id: \.self) { feeling in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedFeeling = feeling
                                storage.lastFeeling = feeling.rawValue
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(feeling.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                                Text(feeling.emoji)
                                    .font(.system(size: 13))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selectedFeeling == feeling
                                          ? PPColor.vitalityTeal.opacity(0.18)
                                          : Color.white)
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selectedFeeling == feeling
                                            ? PPColor.vitalityTeal
                                            : PPColor.actionBlue.opacity(0.12), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .physioGlass(.card)
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Feeling Response Card

    private var feelingResponseCard: some View {
        Group {
            if let feeling = selectedFeeling, !feelingResponse(feeling).isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "quote.opening")
                        .font(.title3)
                        .foregroundColor(PPColor.vitalityTeal)
                    Text(feelingResponse(feeling))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(16)
                .physioGlass(.card)
                .transition(.opacity.combined(with: .move(edge: .top)))
                .animation(.easeInOut, value: selectedFeeling)
            }
        }
    }

    // MARK: - Streak & What's Next

    private var streakAndNextSection: some View {
        VStack(spacing: 12) {
            // Streak badge
            if storage.currentStreak >= 2 {
                Label("\(storage.currentStreak)-day streak 🔥", systemImage: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.subheadline.bold())
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .physioGlass(.pill)
            }

            // What's next
            if let nextSlot = storage.nextIncompleteSlot() {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.forward.circle.fill")
                            .foregroundColor(PPColor.actionBlue)
                        Text("Up Next")
                            .font(.headline)
                    }

                    Text("\(nextSlot.exerciseName) · \(nextSlot.label)")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    Text("\(nextSlot.exerciseReps) reps × \(nextSlot.exerciseSets) sets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(PPColor.actionBlue.opacity(0.08))
                .cornerRadius(14)
            }
        }
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Disclaimer

    private var disclaimerText: some View {
        Text("This app is for informational purposes only. Consult a healthcare professional for medical advice.")
            .font(.caption2)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
    }

    // MARK: - Coaching Logic

    private var praiseMessage: String {
        let exercise = appState.selectedExercise
        let hitRange = exercise.map {
            metrics.bestAngle >= $0.targetAngleRange.lowerBound
        } ?? true
        let hitReps = metrics.repsCompleted >= metrics.targetReps && metrics.targetReps > 0

        switch (hitRange, hitReps) {
        case (true, true):
            return "You nailed it — full range and all your reps. 🎯"
        case (true, false):
            return "Great range of motion today! Try pushing for more reps next time."
        case (false, true):
            return "All reps done! Work on bending a little deeper each time."
        default:
            return "Every session counts. You showed up — that's what matters. 💪"
        }
    }

    private func feelingResponse(_ feeling: SessionFeeling) -> String {
        switch feeling {
        case .easier:
            return "That's a great sign — your body is adapting. We'll gradually increase range next session."
        case .same:
            return "Steady progress. Consistency is the most important thing right now."
        case .harder:
            return "That's okay — some days are tougher. Make sure you've rested and had water."
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        VStack(spacing: 12) {
            // Redo this session button
            if appState.activeSlotID != nil {
                Button {
                    if let slotID = appState.activeSlotID {
                        storage.unmarkSlotComplete(slotID)
                    }
                    appState.navigationPath.removeLast() // back to AR/session
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Redo this session")
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }

            Button {
                appState.activeSlotID = nil
                appState.navigationPath.removeLast(appState.navigationPath.count)
                // Signal Assistive root to pop to home, then dismiss cover
                NotificationCenter.default.post(name: .assistiveReturnHome, object: nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    dismiss()
                }
            } label: {
                Text("Done")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(PPGradient.action)
                    .cornerRadius(18)
                    .shadow(color: PPColor.vitalityTeal.opacity(0.25), radius: 10, y: 4)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 8)
        .background(
            Color.white.opacity(0.9)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Plan Progress Computed (consolidated across all plans)

    private var planCompleted: Int {
        storage.completedSlotCount
    }

    private var planTotal: Int {
        max(storage.totalSlotCount, 1)
    }

    // MARK: - Helpers

    private func statItem<Content: View>(label: String, @ViewBuilder icon: () -> Content) -> some View {
        VStack(spacing: 8) {
            icon()
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var thinDivider: some View {
        Rectangle()
            .fill(PPColor.actionBlue.opacity(0.1))
            .frame(width: 1, height: 60)
    }
}

// MARK: - Helper Views

struct SummaryMetricCard: View {
    let value: String
    let label: String
    let sublabel: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                Text(sublabel)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .physioGlass(.card)
    }
}
