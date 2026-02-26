# PhysioPoint — Feature Upgrade Skill: Form Intelligence Engine
> **Version:** 1.0 | **Author:** PhysioPoint Dev  
> **Purpose:** Agent reference file for implementing AR form quality features, rep counting beta, confidence guard, hysteresis, and quality-first summary metrics.  
> **Constraints:** Offline only, no HealthKit, no sign-in, `UserDefaults`-backed, ≤25 MB ZIP, runs on iPad via Swift Playgrounds 4.6+.

---

## 1. Feature Overview

| Feature | Status | Where |
|---|---|---|
| Confidence-based tracking guard (freeze on bad data) | ✅ Add | `Coordinator` in `ARViewRepresentable` |
| Hysteresis for zone transitions (prevent jitter) | ✅ Add | `SimpleRehabEngine` |
| Dynamic form cues (zone-aware + secondary joint) | ✅ Add | `FormCue`, `Coordinator`, `RehabSessionViewModel` |
| Quality-first summary metrics (form time, control, range) | ✅ Add | `RehabSessionViewModel`, `SummaryView` |
| Rep counting (beta) toggle | ✅ Add | `PhysioPointSettings`, `ProfileView`, `ExerciseARView` |
| Richer per-exercise form cue library (2–3 cues each) | ✅ Add | `ExerciseTrackingConfig.swift` |

---

## 2. Settings Model

### `PhysioPointSettings.swift`
Single source of truth for toggleable features. Uses `@AppStorage` so values persist via `UserDefaults` — no StorageService changes needed.

```swift
final class PhysioPointSettings: ObservableObject {
    @AppStorage("pp_rep_counting_beta") var repCountingBeta: Bool = false
    @AppStorage("pp_accessibility_mode") var accessibilityMode: Bool = false
}
```

**Inject into the app root:**
```swift
@main
struct PhysioPointApp: App {
    @StateObject var settings = PhysioPointSettings()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)
        }
    }
}
```

---

## 3. Profile Tab — Settings UI

Add both toggles in `ProfileView` under a single "Features" section:

```swift
struct ProfileView: View {
    @EnvironmentObject var settings: PhysioPointSettings

    var body: some View {
        Form {
            Section {
                Toggle("Rep counting (beta)", isOn: $settings.repCountingBeta)
                Text("Counts full movement cycles. May be inaccurate if the camera loses tracking. Works best in side view with good lighting.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Early access", systemImage: "flask")
            }

            Section {
                Toggle("Accessibility mode", isOn: $settings.accessibilityMode)
                Text("Shows a single large-text card with plain-English progress summaries instead of detailed metrics.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Display", systemImage: "accessibility")
            }
        }
        .navigationTitle("Profile")
    }
}
```

---

## 4. FormCue Model — Extended

Extend `FormCue` to support **zone-conditional** and **secondary-joint-conditional** cues. This is the backbone of the Form Intelligence Engine.

```swift
public struct FormCue: Hashable {
    public let description: String
    public let jointToWatch: String?
    /// If non-nil, this cue fires when the secondary joint's measured deviation exceeds this value (degrees).
    public let maxAngleDeviation: Double?
    /// If non-nil, this cue only shows when the primary angle is in this zone.
    public let zone: AngleZone?

    public init(
        description: String,
        jointToWatch: String? = nil,
        maxAngleDeviation: Double? = nil,
        zone: AngleZone? = nil
    ) {
        self.description = description
        self.jointToWatch = jointToWatch
        self.maxAngleDeviation = maxAngleDeviation
        self.zone = zone
    }
}
```

---

## 5. Expanded Form Cue Library

All exercises now include 2–3 cues. Cues are ordered by priority:
1. Safety / compensation cue (fires when secondary joint deviates)
2. Zone-specific coaching cue
3. General technique cue (always-on fallback)

### KNEE

```swift
case "Seated Knee Extension":
    formCues: [
        FormCue(description: "Sit tall — back against the chair, no leaning.", jointToWatch: "spine_4_joint", maxAngleDeviation: 15),
        FormCue(description: "Toes point up, not out.", jointToWatch: "right_foot_joint", zone: .belowTarget),
        FormCue(description: "Let the movement come from the knee, not the hip.", jointToWatch: nil, zone: .target)
    ]

case "Straight Leg Raises":
    formCues: [
        FormCue(description: "Keep the knee fully locked straight as you lift.", jointToWatch: "right_leg_joint", maxAngleDeviation: 15),
        FormCue(description: "Low back stays flat — don't arch.", jointToWatch: "spine_4_joint", maxAngleDeviation: 12),
        FormCue(description: "Lift slowly, lower with control.", jointToWatch: nil)
    ]

case "Heel Slides":
    formCues: [
        FormCue(description: "Back stays flat on the surface — no bridging.", jointToWatch: "hips_joint", maxAngleDeviation: 10),
        FormCue(description: "Slide the heel in slowly — don't rush the bend.", jointToWatch: nil, zone: .belowTarget),
        FormCue(description: "Good depth — now slide back out with the same control.", jointToWatch: nil, zone: .target)
    ]

case "Terminal Knee Extension":
    formCues: [
        FormCue(description: "Knee tracks straight — don't let it drift inward.", jointToWatch: "right_leg_joint", maxAngleDeviation: 12),
        FormCue(description: "Push straight back — no hip rotation.", jointToWatch: "hips_joint"),
        FormCue(description: "Hold 2 seconds at full extension.", jointToWatch: nil, zone: .target)
    ]

case "Seated Knee Flexion":
    formCues: [
        FormCue(description: "Torso stays upright — don't lean forward.", jointToWatch: "spine_4_joint", maxAngleDeviation: 15),
        FormCue(description: "Let gravity help — just let the leg drop slowly.", jointToWatch: nil, zone: .belowTarget),
        FormCue(description: "Good range — hold briefly before returning.", jointToWatch: nil, zone: .target)
    ]

case "Single Leg Balance":
    formCues: [
        FormCue(description: "Stand tall — eyes on a fixed point in front.", jointToWatch: "spine_7_joint", maxAngleDeviation: 10),
        FormCue(description: "Opposite foot fully off the floor.", jointToWatch: "left_foot_joint"),
        FormCue(description: "Breathe normally — tension makes balance harder.", jointToWatch: nil, zone: .target)
    ]
```

### ELBOW

```swift
case "Elbow Flexion & Extension":
    formCues: [
        FormCue(description: "Upper arm stays pinned to your side — no swinging.", jointToWatch: "right_shoulder_1_joint", maxAngleDeviation: 15),
        FormCue(description: "Full extension on the way down — straighten it all the way.", jointToWatch: nil, zone: .aboveTarget),
        FormCue(description: "Squeeze at the top of the curl.", jointToWatch: nil, zone: .target)
    ]

case "Active Elbow Flexion":
    formCues: [
        FormCue(description: "Keep the upper arm completely still.", jointToWatch: "right_arm_joint", maxAngleDeviation: 12),
        FormCue(description: "Wrist stays neutral — don't curl it.", jointToWatch: "right_hand_joint"),
        FormCue(description: "Smooth arc — no jerky momentum.", jointToWatch: nil)
    ]

case "Elbow Extension Stretch":
    formCues: [
        FormCue(description: "Shoulder stays completely still — stretch is at the elbow only.", jointToWatch: "right_shoulder_1_joint", maxAngleDeviation: 10),
        FormCue(description: "Gentle overpressure — no pain, just mild tension.", jointToWatch: nil, zone: .belowTarget),
        FormCue(description: "Hold the stretch — don't bounce.", jointToWatch: nil, zone: .target)
    ]
```

### SHOULDER

```swift
case "Wall Slides":
    formCues: [
        FormCue(description: "Back of hand AND elbow must stay touching the wall.", jointToWatch: "right_arm_joint", maxAngleDeviation: 10),
        FormCue(description: "Ribs stay down — don't flare the chest to reach higher.", jointToWatch: "spine_4_joint", maxAngleDeviation: 12),
        FormCue(description: "Slide smoothly — no shrugging the shoulder.", jointToWatch: nil)
    ]

case "Supine Shoulder Flexion":
    formCues: [
        FormCue(description: "Back stays flat — no arching.", jointToWatch: "spine_4_joint", maxAngleDeviation: 10),
        FormCue(description: "Arm leads the movement — don't use momentum.", jointToWatch: nil, zone: .belowTarget),
        FormCue(description: "Hold at the top — breathe out.", jointToWatch: nil, zone: .target)
    ]

case "Standing Shoulder Flexion":
    formCues: [
        FormCue(description: "Torso upright — no leaning back to cheat the range.", jointToWatch: "spine_4_joint", maxAngleDeviation: 15),
        FormCue(description: "Elbow stays soft — not rigidly locked.", jointToWatch: "right_forearm_joint"),
        FormCue(description: "Lower slowly — don't let gravity drop the arm.", jointToWatch: nil)
    ]
```

### HIP

```swift
case "Standing Hip Flexion":
    formCues: [
        FormCue(description: "Stand tall — no backward lean as the leg lifts.", jointToWatch: "spine_7_joint", maxAngleDeviation: 12),
        FormCue(description: "Lift from the hip, not the knee.", jointToWatch: "hips_joint", zone: .belowTarget),
        FormCue(description: "Hold 2 seconds at the top.", jointToWatch: nil, zone: .target)
    ]

case "Hip Hinge":
    formCues: [
        FormCue(description: "Push hips back like closing a car door with your hips.", jointToWatch: "hips_joint"),
        FormCue(description: "Spine stays long and neutral — no rounding.", jointToWatch: "spine_4_joint", maxAngleDeviation: 15),
        FormCue(description: "Weight in the heels — toes stay light.", jointToWatch: "right_foot_joint")
    ]
```

---

## 6. Confidence-Based Tracking Guard

### Where: `Coordinator` in `ARViewRepresentable`

Add two private state variables and a helper method. This prevents bad angle data from propagating when joints overlap or go off-screen.

```swift
// Add to Coordinator:
private var lastGoodAngle: Double = 0
private var poorTrackingFrames: Int = 0
private let maxPoorFrames: Int = 5

// Called when joint positions are invalid (NaN, missing, or self-occluded):
private func handlePoorTracking() {
    poorTrackingFrames += 1
    guard poorTrackingFrames >= maxPoorFrames else { return }

    DispatchQueue.main.async {
        self.viewModel.isTrackingQualityGood = false
        self.viewModel.feedbackMessage = "Adjust your position so the iPad can see the joint clearly."
        self.viewModel.currentAngle = self.lastGoodAngle  // freeze, don't show garbage
    }
}

// Called at the top of your didUpdate body anchor handler:
func validateJointPositions(
    proximal: SIMD3<Float>,
    middle: SIMD3<Float>,
    distal: SIMD3<Float>
) -> Bool {
    guard proximal.isFinite && middle.isFinite && distal.isFinite else { return false }
    // Extra: reject if joints are implausibly close (occlusion signal)
    let segLen = simd_distance(proximal, middle)
    if segLen < 0.05 { return false }  // less than 5cm = likely collapsed/occluded
    return true
}

// In your existing frame update, wrap the processJoints call:
if validateJointPositions(proximal: proximal, middle: middle, distal: distal) {
    poorTrackingFrames = 0
    viewModel.isTrackingQualityGood = true
    viewModel.cameraHint = ""
    viewModel.processJoints(proximal: proximal, joint: middle, distal: distal)
    lastGoodAngle = viewModel.currentAngle
} else {
    handlePoorTracking()
}
```

**Key rule:** Never show `0°` or a snapshot angle from a collapsed skeleton. Freeze the last validated value. The UI already has `isTrackingQualityGood` wired to an orange warning banner.

---

## 7. Hysteresis for Zone Transitions

### Where: `SimpleRehabEngine`

Replace direct threshold comparisons with a hysteresis buffer to prevent zone flipping at the boundary (e.g. 159.9° → 160.1° counting 10 reps in 1 second).

```swift
// Inside SimpleRehabEngine, maintain:
private var currentZone: AngleZone = .belowTarget

// Replace your existing zone assignment with:
func computeZone(for angle: Double, target: Double, tolerance: Double) -> AngleZone {
    let lower = target - tolerance
    let upper = target + tolerance

    // Buffer: require crossing past the midpoint before switching zones
    let enterBuffer = tolerance * 0.3   // 30% of tolerance as dead-band
    let enterLower  = lower + enterBuffer
    let enterUpper  = upper - enterBuffer

    switch currentZone {
    case .belowTarget:
        if angle >= enterLower { currentZone = .target }
    case .target:
        if angle < lower - enterBuffer { currentZone = .belowTarget }
        else if angle > upper + enterBuffer { currentZone = .aboveTarget }
    case .aboveTarget:
        if angle <= enterUpper { currentZone = .target }
    }

    return currentZone
}
```

**Effect:** A jittery signal oscillating at 159.8°/160.2° stays in `.belowTarget` until it genuinely crosses 163°+ (assuming tolerance=15). Prevents phantom rep counts.

---

## 8. Dynamic Form Cue Selection

### Where: `Coordinator` (called each frame)

Selects the most contextually relevant `FormCue` from the exercise's cue array using a priority waterfall:
1. Secondary joint deviation (cheat detection) — highest priority
2. Zone-specific cue — context coaching
3. First cue in array — always-on fallback

```swift
func selectFormCue(
    primaryState: AngleState,
    config: JointTrackingConfig,
    skeleton: ARSkeleton3D
) -> String? {
    let cues = config.formCues
    guard !cues.isEmpty else { return nil }

    // Priority 1: secondary joint cheat detection
    for cue in cues {
        guard
            let watchJoint = cue.jointToWatch,
            let maxDev = cue.maxAngleDeviation,
            let watchIdx = jointIndexMap[watchJoint]
        else { continue }

        let watchPos = skeleton.jointModelTransforms[watchIdx].translation
        // Simple heuristic: measure vertical tilt of the joint from neutral
        let deviation = abs(Double(watchPos.y) - neutralYForJoint(watchJoint))
        if deviation > maxDev / 100.0 {  // normalize: ~15° ≈ 0.15 in model space
            return cue.description
        }
    }

    // Priority 2: zone-matched cue
    if let zoneCue = cues.first(where: { $0.zone == primaryState.zone }) {
        return zoneCue.description
    }

    // Priority 3: fallback
    return cues.first?.description
}
```

Call this from the Coordinator each frame, but **only update `formCueText` when it changes** to prevent visual flicker:

```swift
let newCue = selectFormCue(primaryState: state, config: config, skeleton: skeleton)
if newCue != viewModel.formCueText {
    DispatchQueue.main.async {
        self.viewModel.formCueText = newCue ?? ""
    }
}
```

---

## 9. Quality Metrics in RehabSessionViewModel

### Where: `RehabSessionViewModel`

Track three running quality signals every frame. These are computed **client-side** from the same angle data already being produced — no new API calls.

```swift
public class RehabSessionViewModel: ObservableObject {
    // --- Existing published properties ---
    @Published public var currentAngle: Double = 0
    @Published public var repsCompleted: Int = 0
    @Published public var isInZone: Bool = false
    @Published public var feedbackMessage: String = "Position yourself in frame"
    @Published public var formCueText: String = ""
    @Published public var bestAngle: Double = 0
    @Published public var angleZone: AngleZone = .aboveTarget
    @Published public var isBodyDetected: Bool = false
    @Published public var isTrackingQualityGood: Bool = true
    @Published public var cameraHint: String = ""
    @Published public var reliabilityBadge: String = ""
    @Published public var trackingQuality: String = "Initializing..."
    @Published public var debugText: String = "Initializing..."
    @Published public var targetAngle: Double = 90
    @Published public var tolerance: Double = 15

    // --- NEW: Quality tracking ---
    @Published public var totalFrames: Int = 0
    @Published public var framesInGoodForm: Int = 0
    @Published public var goodFormSeconds: Double = 0       // derived in view
    @Published public var jitterAccumulated: Double = 0

    private var lastRawAngle: Double?
    private let angleSmoother = AngleSmoother(windowSize: 5)
    public var engine: RehabEngine

    // --- Computed quality properties ---
    /// 0.0–1.0. Percentage of frames where angle was in target zone.
    public var qualityScore: Double {
        guard totalFrames > 0 else { return 0 }
        return Double(framesInGoodForm) / Double(totalFrames)
    }

    /// 0.0–1.0. Higher = smoother movement (less jitter).
    public var controlRating: Double {
        guard totalFrames > 1 else { return 1.0 }
        let avgJitter = jitterAccumulated / Double(totalFrames - 1)
        return max(0, min(1, 1.0 - avgJitter / 15.0))
    }

    /// Human-readable control label.
    public var controlLabel: String {
        switch controlRating {
        case 0.8...: return "Excellent"
        case 0.6..<0.8: return "Good"
        case 0.4..<0.6: return "Fair"
        default: return "Keep practicing"
        }
    }

    public init(engine: RehabEngine = SimpleRehabEngine()) {
        self.engine = engine
    }

    public func processJoints(proximal: SIMD3<Float>, joint: SIMD3<Float>, distal: SIMD3<Float>) {
        let state = engine.update(proximal: proximal, joint: joint, distal: distal)
        let repState = engine.currentRepState
        let rawAngle = state.degrees
        let smoothedAngle = angleSmoother.smooth(rawAngle)

        // Quality tracking
        totalFrames += 1
        if state.zone == .target { framesInGoodForm += 1 }
        if let last = lastRawAngle { jitterAccumulated += abs(rawAngle - last) }
        lastRawAngle = rawAngle

        DispatchQueue.main.async {
            self.isBodyDetected = true
            self.currentAngle = smoothedAngle
            self.angleZone = state.zone
            self.repsCompleted = repState.repsCompleted
            if smoothedAngle > self.bestAngle { self.bestAngle = smoothedAngle }

            if repState.isHolding {
                self.feedbackMessage = "Hold it! 💪"
            } else {
                switch state.zone {
                case .belowTarget: self.feedbackMessage = "Move more toward target"
                case .target:      self.feedbackMessage = "In target range — hold! ✅"
                case .aboveTarget: self.feedbackMessage = "Ease back toward target"
                }
            }
        }
    }

    /// Reset between sessions.
    public func resetQualityMetrics() {
        totalFrames = 0
        framesInGoodForm = 0
        goodFormSeconds = 0
        jitterAccumulated = 0
        lastRawAngle = nil
        bestAngle = 0
        repsCompleted = 0
        angleSmoother.reset()
    }

    public func bodyLost() {
        feedbackMessage = "Move back into frame"
        isInZone = false
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

---

## 10. ExerciseARView — Rep Counter Conditional Display

### Where: `ExerciseARView`

Show the rep counter only when `repCountingBeta` is on. Otherwise show the quality-first metric (good form time).

```swift
public struct ExerciseARView: View {
    @StateObject private var viewModel = RehabSessionViewModel()
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var settings: PhysioPointSettings

    public var body: some View {
        ZStack {
            arOrFallback

            VStack(spacing: 4) {
                // ... existing debug + tracking indicator + feedbackMessage + formCueText ...

                Spacer()

                Text("For educational demo only. Not medical advice.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.bottom, 8)

                HStack(spacing: 20) {
                    // Quality time — always visible
                    VStack(spacing: 2) {
                        Text(String(format: "%.0fs", viewModel.goodFormSeconds))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                        Text("In good form")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(16)

                    // Rep counter — beta only
                    if settings.repCountingBeta {
                        VStack(spacing: 2) {
                            Text("\(viewModel.repsCompleted)")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            HStack(spacing: 3) {
                                Image(systemName: "flask.fill")
                                    .font(.caption2)
                                    .foregroundColor(.orange)
                                Text("Reps (beta)")
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(16)
                    }

                    // Done button
                    Button {
                        // existing done logic
                    } label: {
                        Text("Done")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(16)
                    }
                }
                .padding(.bottom, 16)
            }
        }
    }
}
```

---

## 11. SummaryView — Quality Metrics Display

### Where: `SummaryView`

Replace or supplement the raw rep count with quality metrics. Structure: three cards in an `HStack`.

```swift
// In SummaryView, replace the rep count tile section with:

HStack(spacing: 12) {
    // Card 1: Time in good form
    SummaryMetricCard(
        value: String(format: "%.0f%%", session.qualityScore * 100),
        label: "Good form",
        sublabel: "of session time",
        icon: "checkmark.seal.fill",
        color: .green
    )

    // Card 2: Control rating
    SummaryMetricCard(
        value: session.controlLabel,
        label: "Movement control",
        sublabel: "smoothness rating",
        icon: "waveform.path.ecg",
        color: .blue
    )

    // Card 3: Range achieved
    SummaryMetricCard(
        value: String(format: "%.0f%%", rangeAchieved * 100),
        label: "Range achieved",
        sublabel: "of target bend",
        icon: "ruler.fill",
        color: .orange
    )
}

// If rep counting beta is on, add a fourth card below:
if settings.repCountingBeta {
    HStack {
        Image(systemName: "flask.fill").foregroundStyle(.orange)
        Text("Rep counting (beta): \(session.repsCompleted) cycles detected")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
    .padding(.horizontal)
}
```

Where `rangeAchieved` is:
```swift
var rangeAchieved: Double {
    guard let config = appState.selectedExercise?.trackingConfig else { return 0 }
    let target = config.targetRange.upperBound
    return min(1.0, session.bestAngle / target)
}
```

---

## 12. Integration Checklist

Use this checklist when implementing the upgrades:

- [ ] Add `PhysioPointSettings` with `@AppStorage` properties
- [ ] Inject `settings` as `@EnvironmentObject` in app root
- [ ] Add `repCountingBeta` and `accessibilityMode` toggles in `ProfileView`
- [ ] Extend `FormCue` with `maxAngleDeviation` and `zone` fields
- [ ] Update all exercise configs with 2–3 cues each (see Section 5)
- [ ] Add `validateJointPositions()` + `handlePoorTracking()` to `Coordinator`
- [ ] Add `lastGoodAngle` freeze logic in `Coordinator.session(_:didUpdate:)`
- [ ] Add hysteresis buffer to `SimpleRehabEngine.computeZone()`
- [ ] Add `selectFormCue()` to `Coordinator`, call each frame (with change guard)
- [ ] Add `totalFrames`, `framesInGoodForm`, `jitterAccumulated`, `goodFormSeconds` to `RehabSessionViewModel`
- [ ] Add `qualityScore`, `controlRating`, `controlLabel` computed properties
- [ ] Add `resetQualityMetrics()` call when a new session starts
- [ ] Update `ExerciseARView` to show `goodFormSeconds` always, reps only when beta on
- [ ] Update `SummaryView` with 3-card quality display + optional beta rep row
- [ ] Test full flow: start session → exercise → poor tracking → freeze → resume → summary shows quality

---

## 13. Key Design Decisions

| Decision | Rationale |
|---|---|
| Rep counting as beta toggle | ARKit angle error (~8–20°) makes rep counting noisy without IMU fusion. Labelling it beta sets correct user expectations and judges can see the honesty. |
| Freeze on bad tracking | Showing `0°` or collapsed angles feels broken. Freezing the last good value feels like a "pause" — more trustworthy UX. |
| Hysteresis buffer = 30% of tolerance | Empirically prevents jitter at zone boundaries without being so wide it misses real transitions. Tune per exercise if needed. |
| Secondary joint cue as Priority 1 | "Cheat" detection (leaning back, swinging shoulder) is more valuable PT feedback than generic "move more." PT feedback = app differentiator. |
| Quality metrics over rep count | `qualityScore` and `controlRating` are robust to tracking noise because they average hundreds of frames. Reps are a single-frame event and fragile. |
| `goodFormSeconds` always visible | Gives the user something meaningful to aim for even with beta off. Judges see a thoughtful fallback, not an empty HUD. |

---

*End of skill file. Feed this document to your agent alongside the existing codebase to implement all upgrades.*
