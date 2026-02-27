Now I have the full picture. The fix requires three interlocking pieces: (1) exercise-specific live cue logic in the Coordinator, (2) a SessionFeedback model that accumulates what actually happened during the session, and (3) a new PTFeedbackCard in SummaryView that shows one positive + one actionable.
​

Here's the complete implementation across all three files.

Part 1: SessionFeedback model — new file
This is the bridge between the AR session and SummaryView. It records what actually happened so the summary can speak specifically about it.

```swift
// MARK: - SessionFeedback.swift
// Accumulates exercise-specific events during a session.
// Passed from RehabSessionViewModel → SessionMetrics → SummaryView.

public struct SessionFeedback {
    // What the user did well (picked at session end)
    public var positiveObservation: String = ""
    // What they should work on next time
    public var growthObservation: String = ""
    // Recovery journey message tied to the positive
    public var journeyMessage: String = ""
}

// Fired from Coordinator into ViewModel as events occur
public enum SessionEvent {
    case goodFormHeld(seconds: Double)         // spent ≥2s in zone continuously
    case cheatDetected(jointName: String)      // secondary joint deviated
    case rangeImproving(percent: Double)       // best angle > previous best
    case consistentMovement                    // low jitter across session
    case roughMovement                         // high jitter
    case fullRangeReached                      // hit upper bound of targetRange
    case rangeShort(gapDegrees: Double)        // never reached target upper bound
}
```
Part 2: RehabSessionViewModel — add event log + feedback generation
Add event tracking and the feedback generator that SummaryView reads at the end.

```swift
public class RehabSessionViewModel: ObservableObject {
    // --- existing published properties unchanged ---
    @Published public var currentAngle: Double = 0
    @Published public var repsCompleted: Int = 0
    @Published public var isInZone: Bool = false
    @Published public var feedbackMessage: String = "Position yourself in frame"
    @Published public var formCueText: String = ""
    @Published public var trackingQuality: String = "Initializing..."
    @Published public var cameraHint: String = ""
    @Published public var reliabilityBadge: String = ""
    @Published public var isBodyDetected: Bool = false
    @Published public var bestAngle: Double = 0
    @Published public var angleZone: AngleZone = .aboveTarget
    @Published public var debugText: String = "Initializing..."
    @Published public var targetAngle: Double = 90
    @Published public var tolerance: Double = 15
    @Published public var isTrackingQualityGood: Bool = true

    @Published public var totalFrames: Int = 0
    @Published public var framesInGoodForm: Int = 0
    @Published public var goodFormSeconds: Double = 0
    @Published public var jitterAccumulated: Double = 0

    // --- NEW: event log ---
    public private(set) var sessionEvents: [SessionEvent] = []
    // Tracks what exercise was running (set by ExerciseARView.onAppear)
    public var exerciseName: String = ""

    private var consecutiveGoodFrames: Int = 0
    private var goodFormStreakReported: Bool = false  // avoid spamming the same event
    private var cheatJointsDetected: Set<String> = []
    private var lastRawAngle: Double?
    private let framesPerSecond: Double = 30.0
    private let angleSmoother = AngleSmoother(windowSize: 5)
    public var engine: RehabEngine

    public var qualityScore: Double {
        guard totalFrames > 0 else { return 0 }
        return Double(framesInGoodForm) / Double(totalFrames)
    }

    public var controlRating: Double {
        guard totalFrames > 1 else { return 1.0 }
        let avgJitter = jitterAccumulated / Double(totalFrames - 1)
        return max(0, min(1, 1.0 - avgJitter / 15.0))
    }

    public var controlLabel: String {
        switch controlRating {
        case 0.8...: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        default: return "Keep going"
        }
    }

    public init(engine: RehabEngine = SimpleRehabEngine()) {
        self.engine = engine
    }

    public func setup(targetAngle: Double, tolerance: Double, holdTime: TimeInterval,
                      repDirection: RepDirection = .increasing, restAngle: Double = 90.0) {
        self.engine = SimpleRehabEngine(
            targetAngle: targetAngle, tolerance: tolerance,
            requiredHoldTime: holdTime, repDirection: repDirection, restAngle: restAngle
        )
    }

    // Called by Coordinator when a secondary joint cheat is detected
    public func recordCheat(jointName: String) {
        guard !cheatJointsDetected.contains(jointName) else { return }
        cheatJointsDetected.insert(jointName)
        sessionEvents.append(.cheatDetected(jointName: jointName))
    }

    public func processJoints(proximal: SIMD3<Float>, joint: SIMD3<Float>, distal: SIMD3<Float>) {
        let state = engine.update(proximal: proximal, joint: joint, distal: distal)
        let repState = engine.currentRepState
        let rawAngle = state.degrees
        let smoothedAngle = angleSmoother.smooth(rawAngle)

        totalFrames += 1
        if state.zone == .target {
            framesInGoodForm += 1
            consecutiveGoodFrames += 1
            goodFormSeconds += 1.0 / framesPerSecond

            // Record a "held good form" event once per streak ≥ 2s
            let streak = Double(consecutiveGoodFrames) / framesPerSecond
            if streak >= 2.0 && !goodFormStreakReported {
                goodFormStreakReported = true
                sessionEvents.append(.goodFormHeld(seconds: streak))
            }
        } else {
            consecutiveGoodFrames = 0
            goodFormStreakReported = false
        }

        if let last = lastRawAngle { jitterAccumulated += abs(rawAngle - last) }
        lastRawAngle = rawAngle

        let consecutiveSnapshot = consecutiveGoodFrames
        let currentTargetAngle = self.targetAngle
        let currentTolerance = self.tolerance

        DispatchQueue.main.async {
            self.isBodyDetected = true
            self.currentAngle = smoothedAngle
            self.angleZone = state.zone
            self.repsCompleted = repState.repsCompleted
            if smoothedAngle > self.bestAngle { self.bestAngle = smoothedAngle }

            // Escalating hold messages
            if repState.isHolding {
                let holdSecs = Double(consecutiveSnapshot) / self.framesPerSecond
                if holdSecs >= 2.5 {
                    self.feedbackMessage = "Perfect — hold strong! 🔥"
                } else if holdSecs >= 1.0 {
                    self.feedbackMessage = "That's it — keep holding! 💪"
                } else {
                    self.feedbackMessage = "Hold it! 💪"
                }
            } else {
                switch state.zone {
                case .belowTarget:
                    let gap = currentTargetAngle - smoothedAngle - currentTolerance
                    if gap < 5 {
                        self.feedbackMessage = "Almost there — just a bit more 🎯"
                    } else if gap < 15 {
                        self.feedbackMessage = "Getting closer! Keep going ↑"
                    } else {
                        self.feedbackMessage = "Slowly extend a little further"
                    }
                case .target:
                    if consecutiveSnapshot > Int(self.framesPerSecond * 2) {
                        self.feedbackMessage = "Excellent form! Keep it up 🌟"
                    } else if consecutiveSnapshot > Int(self.framesPerSecond * 0.5) {
                        self.feedbackMessage = "Great! You're in the zone ✅"
                    } else {
                        self.feedbackMessage = "In range — hold! ✅"
                    }
                case .aboveTarget:
                    self.feedbackMessage = "Ease back slightly — past the target"
                }
            }
        }
    }

    public func processJoints(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: SIMD3<Float>) {
        processJoints(proximal: hip, joint: knee, distal: ankle)
    }

    // MARK: - Generate feedback at session end
    // Called right before Finish button navigates to SummaryView.
    // Returns exercise-specific positive + growth observations.
    public func generateFeedback(for exerciseName: String, targetRange: ClosedRange<Double>) -> SessionFeedback {
        var feedback = SessionFeedback()

        let hitFullRange = bestAngle >= targetRange.upperBound - 5
        let gapToBest = targetRange.upperBound - bestAngle
        let hasCheat = !cheatJointsDetected.isEmpty
        let firstCheat = cheatJointsDetected.first

        // ── POSITIVE observation (what they genuinely did well) ──
        let heldGoodForm = sessionEvents.contains {
            if case .goodFormHeld = $0 { return true }
            return false
        }

        if hitFullRange && heldGoodForm {
            feedback.positiveObservation = "You reached your full target range AND held good form for multiple seconds. That's exactly the right combination."
        } else if hitFullRange {
            feedback.positiveObservation = "You hit your full target range today. Your \(bodyPartLabel(for: exerciseName)) is moving well."
        } else if heldGoodForm {
            feedback.positiveObservation = "You held steady in the target zone — that controlled hold time is what builds real strength."
        } else if qualityScore > 0.5 {
            feedback.positiveObservation = "Over half your session was in good form. That consistency adds up more than you'd think."
        } else {
            feedback.positiveObservation = "You showed up and did the work. Every session — even the hard ones — moves recovery forward."
        }

        // ── GROWTH observation (specific, not generic) ──
        if hasCheat, let joint = firstCheat {
            feedback.growthObservation = compensationCue(for: joint, exercise: exerciseName)
        } else if !hitFullRange && gapToBest > 10 {
            feedback.growthObservation = rangeGrowthCue(for: exerciseName, gapDegrees: gapToBest)
        } else if controlRating < 0.5 {
            feedback.growthObservation = "Try slowing the movement down — smoother reps build more tissue strength than fast ones."
        } else if !hitFullRange && gapToBest <= 10 {
            feedback.growthObservation = "You were close to full range — just a small amount more each session will get you there."
        } else {
            feedback.growthObservation = "Keep the same controlled pace next session to reinforce the movement pattern."
        }

        // ── JOURNEY message (forward-looking, tied to positive) ──
        feedback.journeyMessage = journeyMessage(
            for: exerciseName,
            qualityScore: qualityScore,
            hitFullRange: hitFullRange
        )

        return feedback
    }

    // MARK: - Exercise-specific copy helpers

    private func bodyPartLabel(for exercise: String) -> String {
        switch exercise {
        case _ where exercise.lowercased().contains("knee"): return "knee"
        case _ where exercise.lowercased().contains("elbow"): return "elbow"
        case _ where exercise.lowercased().contains("shoulder"): return "shoulder"
        case _ where exercise.lowercased().contains("hip"): return "hip"
        case _ where exercise.lowercased().contains("ankle"): return "ankle"
        default: return "joint"
        }
    }

    private func compensationCue(for joint: String, exercise: String) -> String {
        switch joint {
        case "spine_4_joint", "spine_7_joint":
            return "Your back shifted a little during the movement — focus on keeping your spine still while the \(bodyPartLabel(for: exercise)) does the work."
        case "right_shoulder_1_joint", "left_shoulder_1_joint":
            return "Your shoulder was moving during the exercise — try pinning your upper arm to your side so the elbow takes the load."
        case "hips_joint":
            return "Your hip shifted slightly — try squeezing your core before each rep to keep the pelvis stable."
        case "right_foot_joint", "left_foot_joint":
            return "Your foot position drifted — plant it flat and keep it still throughout the movement."
        default:
            return "There was some compensating movement — focus on isolating the target joint next session."
        }
    }

    private func rangeGrowthCue(for exercise: String, gapDegrees: Double) -> String {
        let gap = Int(gapDegrees)
        switch exercise {
        case "Seated Knee Extension", "Terminal Knee Extension":
            return "You were \(gap)° short of full extension — try holding at your max point for 2 extra seconds to encourage the knee to open further."
        case "Heel Slides", "Seated Knee Flexion":
            return "You were \(gap)° short of full bend — after each slide, hold at the deepest point before returning."
        case "Wall Slides", "Supine Shoulder Flexion", "Standing Shoulder Flexion":
            return "You were \(gap)° from overhead — keep your back flat against the wall/surface and let gravity assist the last range."
        case "Elbow Flexion & Extension", "Active Elbow Flexion":
            return "You were \(gap)° from full range — make sure you fully straighten at the bottom of each rep, not just curl at the top."
        case "Standing Hip Flexion":
            return "You were \(gap)° short — try lifting the knee a little higher each time, keeping the stance leg fully straight."
        case "Hip Hinge":
            return "You were \(gap)° from target depth — focus on pushing the hips further back rather than bending the knees more."
        default:
            return "You were \(gap)° from the target range — aim to add just 2–3° more each session."
        }
    }

    private func journeyMessage(for exercise: String, qualityScore: Double, hitFullRange: Bool) -> String {
        let part = bodyPartLabel(for: exercise)
        if hitFullRange && qualityScore > 0.6 {
            return "If you keep sessions like this up 3× per week, research shows measurable \(part) strength gains within 2–3 weeks."
        } else if qualityScore > 0.4 {
            return "Consistent sessions like this — even imperfect ones — are what drive tissue healing in the \(part). You're on the right track."
        } else {
            return "Every session reintroduces safe load to the \(part). Even short, partial efforts help maintain circulation and prevent stiffness."
        }
    }

    public func resetQualityMetrics() {
        totalFrames = 0
        framesInGoodForm = 0
        goodFormSeconds = 0
        jitterAccumulated = 0
        consecutiveGoodFrames = 0
        goodFormStreakReported = false
        cheatJointsDetected = []
        sessionEvents = []
        lastRawAngle = nil
        bestAngle = 0
        repsCompleted = 0
        angleSmoother.reset()
    }

    public func bodyLost() {
        feedbackMessage = "Step back into view"
        isInZone = false
        consecutiveGoodFrames = 0
        angleSmoother.reset()
    }

    public func addDebug(_ msg: String) {
        DispatchQueue.main.async {
            self.debugText = msg
            print("📱 \(msg)")
        }
    }
}
```
Part 3: Coordinator — call recordCheat when secondary joint fires
In selectFormCue, when a cheat is detected, also tell the ViewModel so it gets logged:

```swift
func selectFormCue(
    primaryZone: AngleZone,
    config: JointTrackingConfig,
    skeleton: ARSkeleton3D
) -> String? {
    let cues = config.formCues
    guard !cues.isEmpty else { return nil }

    for cue in cues {
        guard
            let watchJoint = cue.jointToWatch,
            let maxDev = cue.maxAngleDeviation,
            let watchIdx = jointIndexMap[watchJoint],
            watchIdx < skeleton.jointModelTransforms.count
        else { continue }

        let watchWorldM = skeleton.jointModelTransforms[watchIdx]
        let deviation = abs(Double(watchWorldM.columns.3.y))
        if deviation > maxDev / 100.0 {
            // ← NEW: log it so the summary can reference it specifically
            viewModel.recordCheat(jointName: watchJoint)
            return cue.description
        }
    }

    if let zoneCue = cues.first(where: { $0.zone == primaryZone }) {
        return zoneCue.description
    }

    return cues.first?.description
}
```
Part 4: ExerciseARView — pass exercise name + generate feedback on Finish
In onAppear, set the exercise name on the ViewModel. In the Finish button, call generateFeedback and pass it into SessionMetrics:

```swift
// In onAppear:
viewModel.exerciseName = appState.selectedExercise?.name ?? ""

// In Finish button action — replace existing latestMetrics assignment:
let exerciseName = appState.selectedExercise?.name ?? ""
let targetRange = appState.selectedExercise?.targetAngleRange ?? 80...95
let feedback = viewModel.generateFeedback(for: exerciseName, targetRange: targetRange)

appState.latestMetrics = SessionMetrics(
    bestAngle: viewModel.bestAngle,
    repsCompleted: viewModel.repsCompleted,
    targetReps: appState.selectedExercise?.reps ?? 3,
    targetAngleLow: targetRange.lowerBound,
    targetAngleHigh: targetRange.upperBound,
    timeInGoodForm: viewModel.goodFormSeconds,
    repResults: repResults,
    previousBestAngle: 88,
    previousTimeInForm: 13,
    todayCompleted: 1,
    todayTotal: 3,
    sessionFeedback: feedback    // ← pass through
)
```
Add sessionFeedback: SessionFeedback = SessionFeedback() to SessionMetrics.

Part 5: SummaryView — new PTFeedbackCard
Replace repConsistencyCard (currently EmptyView) with this. Place it right after statsCard:

```swift
private var ptFeedbackCard: some View {
    VStack(spacing: 14) {
        // Header
        HStack(spacing: 8) {
            Image(systemName: "person.fill.checkmark")
                .foregroundColor(PPColor.vitalityTeal)
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
                Text(metrics.sessionFeedback.positiveObservation)
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
                Text(metrics.sessionFeedback.growthObservation)
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
            Text(metrics.sessionFeedback.journeyMessage)
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
```
Then in body, insert it in the scroll stack:

```swift
VStack(spacing: 20) {
    heroSection
    statsCard
    ptFeedbackCard      // ← replaces EmptyView repConsistencyCard
    vsLastSessionCard
    bottomRow
    feelingResponseCard
    streakAndNextSection
    disclaimerText
}
```
What this produces, end-to-end
What fired during the session	Positive shown in SummaryView	Growth shown in SummaryView	Journey message
Hit full range + held form	"You reached your full target range AND held good form for multiple seconds."	"Keep the same controlled pace next session."	"3× per week → measurable knee strength in 2–3 weeks."
Good form held but short of range	"You held steady in the target zone — that controlled hold time builds real strength."	"You were 18° short of full extension — try holding at max for 2 extra seconds."	"Consistent sessions drive tissue healing. You're on the right track."
Back compensation detected	"Over half your session was in good form."	"Your back shifted — focus on keeping your spine still while the knee does the work."	"Even imperfect efforts help maintain circulation and prevent stiffness."
Rough/jittery movement	"You showed up and did the work."	"Try slowing the movement down — smoother reps build more tissue strength."	"Every session reintroduces safe load to the joint."


-- 

## Feature updat - change the AR view 
## 2. Smart Feedback Header (.ultraThinMaterial)
Replace scattered floating text with a grounded pill-shaped header.
​

```swift
struct SmartFeedbackHeader: View {
    let feedbackMessage: String
    let isBodyDetected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Body detection status
            Image(systemName: isBodyDetected ? "figure.walk.motion" : "figure.stand")
                .foregroundStyle(isBodyDetected ? .green : .secondary)
                .symbolEffect(.pulse, isActive: isBodyDetected)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(feedbackMessage)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8) // Dynamic Type safety
            }

            Spacer()

            // Tracking quality indicator
            Image(systemName: "waveform.path.ecg")
                .foregroundStyle(isBodyDetected ? .green : .orange)
                .font(.title3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 16)
    }
}
```
## 3. Animated Angle Display with numericText
The angle display should roll like a slot machine instead of flickering.

```swift
struct AngleDisplay: View {
    let angle: Double
    @State private var inTargetZone: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Image(systemName: "angle")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("\(Int(angle))°")
                .font(.system(.largeTitle, design: .rounded).bold())
                .contentTransition(.numericText(value: angle)) // ← smooth roll animation
                .animation(.spring(duration: 0.3), value: angle)
                .foregroundStyle(inTargetZone ? .green : .orange)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .scaleEffect(inTargetZone ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: inTargetZone)
        .sensoryFeedback(.impact(weight: .heavy), trigger: inTargetZone) // haptic on target
        .onChange(of: angle) { _, newVal in
            inTargetZone = newVal >= targetMinAngle && newVal <= targetMaxAngle
        }
    }
}
```
## 4. Circular Rep Counter
Replace the raw number with a filling ring.
```
swift
struct RepProgressRing: View {
    let current: Int
    let target: Int

    private var progress: Double { Double(current) / Double(target) }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.2), lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.green, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: progress)
            VStack(spacing: 0) {
                Text("\(current)")
                    .font(.system(.title2, design: .rounded).bold())
                    .contentTransition(.numericText())
                    .animation(.default, value: current)
                Text("/ \(target)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 72, height: 72)
        .sensoryFeedback(.success, trigger: current == target)
    }
}
```
## 5. Instruction Cue Pill (SF Symbol + Text)
Replace the plain "Best results: place camera..." text with a dual-icon instructional pill:
​

```swift
struct InstructionCuePill: View {
    let symbol: String
    let message: String
    var symbolColor: Color = .orange

    var body: some View {
        Label(message, systemImage: symbol)
            .font(.system(.footnote, design: .rounded).bold())
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .labelStyle(.titleAndIcon)
    }
}

// Usage:
InstructionCuePill(symbol: "lightbulb.fill",
                   message: "Keep elbow against wall",
                   symbolColor: .orange)

InstructionCuePill(symbol: "arrow.up.and.down.and.sparkles",
                   message: "Move until body is centered",
                   symbolColor: .blue)
```
## 6. Fixed "Finish" Button
Full-width capsule, properly un-mirrored, with haptic confirmation:
​

```swift
struct FinishButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Finish Session", systemImage: "checkmark.circle.fill")
                .font(.system(.body, design: .rounded).bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .tint(.red)
        .clipShape(Capsule())
        .padding(.horizontal, 24)
        .sensoryFeedback(.success, trigger: false) // fires on tap
    }
}
```
## 7. Master Overlay Composition
Wire everything into your main AR overlay ZStack:

```swift
struct PhysioOverlayView: View {
    @ObservedObject var viewModel: PhysioViewModel

    var body: some View {
        VStack {
            // TOP: Feedback header
            SmartFeedbackHeader(
                feedbackMessage: viewModel.feedbackMessage,
                isBodyDetected: viewModel.isBodyDetected
            )
            .padding(.top, 52) // safe area

            Spacer()

            // MID-FLOAT: Angle + Ring side by side
            HStack {
                AngleDisplay(angle: viewModel.currentAngle)
                Spacer()
                RepProgressRing(current: viewModel.repCount, target: viewModel.targetReps)
                    .padding(.trailing, 16)
            }
            .padding(.horizontal, 16)

            // INSTRUCTION CUES
            VStack(spacing: 8) {
                ForEach(viewModel.activeCues, id: \.self) { cue in
                    InstructionCuePill(symbol: cue.symbol, message: cue.message)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.35), value: viewModel.activeCues)
            .padding(.bottom, 12)

            // BOTTOM: Finish button
            FinishButton { viewModel.endSession() }
                .padding(.bottom, 32)
        }
    }
}
```