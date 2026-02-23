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
                        repConsistencyCard
                        vsLastSessionCard
                        bottomRow
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

            Text("Great effort. Here's how you did.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Stats Card (3 metrics)

    private var statsCard: some View {
        HStack(spacing: 0) {
            // Reps completed ring
            statItem(label: "Reps\nCompleted") {
                ZStack {
                    Circle()
                        .stroke(PPColor.actionBlue.opacity(0.15), lineWidth: 5)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: metrics.targetReps > 0 ? CGFloat(metrics.repsCompleted) / CGFloat(metrics.targetReps) : 1)
                        .stroke(PPColor.actionBlue, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    Text("\(metrics.repsCompleted)/\(metrics.targetReps)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(PPColor.actionBlue)
                }
            }

            thinDivider

            // Best bend
            statItem(label: "Best Bend") {
                VStack(spacing: 2) {
                    HStack(alignment: .top, spacing: 1) {
                        Image(systemName: "angle")
                            .font(.system(size: 14))
                            .foregroundColor(PPColor.vitalityTeal)
                        Text("\(Int(metrics.bestAngle))°")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    }
                    Text("Target: \(metrics.targetRangeLabel)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }

            thinDivider

            // Time in good form
            statItem(label: "Time in\nGood Form") {
                VStack(spacing: 2) {
                    HStack(alignment: .top, spacing: 1) {
                        Image(systemName: "timer")
                            .font(.system(size: 14))
                            .foregroundColor(PPColor.recoveryIndigo)
                        Text("\(Int(metrics.timeInGoodForm))s")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(glassCard)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    // MARK: - Rep Consistency

    private var repConsistencyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Rep Consistency")
                .font(.headline)

            let columns = [GridItem(.adaptive(minimum: 90), spacing: 8)]
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(metrics.repResults) { rep in
                    repChip(rep)
                }
            }
        }
        .padding(16)
        .background(glassCard)
        .opacity(animateCards ? 1 : 0)
        .offset(y: animateCards ? 0 : 20)
    }

    private func repChip(_ rep: RepResult) -> some View {
        HStack(spacing: 6) {
            Image(systemName: rep.quality == .good ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 13))
                .foregroundColor(rep.quality == .good ? PPColor.vitalityTeal : .orange)

            Text("Rep \(rep.repNumber)")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(rep.quality == .good ? PPColor.vitalityTeal.opacity(0.12) : Color.orange.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(rep.quality == .good ? PPColor.vitalityTeal.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
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
                .background(glassCard)
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
            .background(glassCard)

            // How did it feel?
            VStack(spacing: 10) {
                Text("How did it feel?")
                    .font(.system(size: 14, weight: .semibold))

                VStack(spacing: 8) {
                    ForEach(SessionFeeling.allCases, id: \.self) { feeling in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedFeeling = feeling
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
            .background(glassCard)
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

    private var glassCard: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(PPColor.actionBlue.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, y: 2)
    }
}
