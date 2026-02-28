🔴 Bug Fixes (Fix Before Filming)
Bug 1 — "Exercise data missing" in Schedule
Your resolveExerciseFromSlot is failing to match exercises because the elbow exercises either aren't in the lookup array or the IDs don't match. The schedule renders the warning triangle when resolveExercise returns nil.
​

```swift
// In ScheduleView / HomeView, update resolveExerciseFromSlot to include ALL exercise arrays:
private func resolveExerciseFromSlot(_ slot: PlanSlot) -> Exercise? {
    let allExercises: [Exercise] = Exercise.kneeExercises
        + Exercise.elbowExercises
        + Exercise.shoulderExercises
        + Exercise.hipExercises
        + Exercise.ankleExercises    // ← add if exists
        + Exercise.backExercises     // ← add if exists

    // Try ID match first, then name match, then fuzzy name contains
    return allExercises.first(where: { $0.id == slot.exerciseID })
        ?? allExercises.first(where: { $0.name == slot.exerciseName })
        ?? allExercises.first(where: { slot.exerciseName.contains($0.name) || $0.name.contains(slot.exerciseName) })
}
```
Also check that Exercise.elbowExercises actually has entries for "Active Elbow Flexion", "Elbow Flexion & Extension", and "Elbow Extension Stretch" — if those static arrays are empty or the names don't match exactly what DailyPlan.make() generates, the slot will always fail to resolve.

Bug 2 — AR Tracking No Person Detected
​
The AR view fires but immediately shows a blank floor — no skeleton, no body detected. This is the SwiftUI ARSCNView reinitialization issue where body tracking silently fails if the ARSession was previously torn down.
​

```swift
// In ExerciseARView / ARViewContainer, ensure the session is configured fresh every appear:
func makeUIView(context: Context) -> ARSCNView {
    let arView = ARSCNView()
    arView.delegate = context.coordinator
    arView.session.delegate = context.coordinator

    let config = ARBodyTrackingConfiguration()
    config.automaticSkeletonScaleEstimationEnabled = true
    arView.session.run(config, options: [.resetTracking, .removeExistingAnchors]) // ← critical
    return arView
}

// Also add in updateUIView to re-run if session is interrupted:
func updateUIView(_ uiView: ARSCNView, context: Context) {
    if uiView.session.currentFrame == nil {
        let config = ARBodyTrackingConfiguration()
        uiView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
}
```
Also add a "no body detected" fallback UI with a pulsing prompt — right now shows a bare 144° angle reading on an empty floor with no guidance:
​

```swift
// In your AR overlay, add a no-body state:
if !isBodyDetected {
    VStack(spacing: 12) {
        Image(systemName: "person.crop.rectangle.badge.plus")
            .font(.system(size: 44))
            .foregroundStyle(.white.opacity(0.8))
            .symbolEffect(.pulse, options: .repeating)

        Text("Stand in view of the camera")
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.white)

        Text("Move back until your full body is visible")
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(.white.opacity(0.75))
            .multilineTextAlignment(.center)
    }
    .padding(24)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
}
```
Bug 3 — Accessibility Mode Back Navigation Stuck
The practice page in Assistive Access has no back button — user is trapped. Fix by adding an explicit back button since AssistiveAccessRootView likely uses a custom nav stack without the default NavigationStack back gesture:
​

```swift
// In AssistiveAccessExerciseView or whatever the practice page is:
VStack {
    // Top bar with explicit back
    HStack {
        Button {
            appState.navigationPath.removeLast()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.title3.bold())
                Text("Back")
                    .font(.system(.body, design: .rounded).bold())
            }
            .foregroundStyle(PPColor.actionBlue)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(PPColor.actionBlue.opacity(0.1), in: Capsule())
            .frame(minWidth: 44, minHeight: 44) // HIG accessibility target
        }
        Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)

    // ... rest of practice view
}
```
If AssistiveAccessRootView uses its own @State var path instead of appState.navigationPath, use presentationMode or pass a dismiss binding:

```swift
// Alternative if using sheet/fullscreenCover:
@Environment(\.dismiss) var dismiss

Button { dismiss() } label: {
    Label("Back", systemImage: "chevron.left")
        .font(.system(.body, design: .rounded).bold())
        .frame(minWidth: 44, minHeight: 44)
}
```
🟠 Feature: Add Elbow to Learn/Knowledge Hub
```swift
// Add to your LearnCondition/BodyArea data source:
static let elbowConditions: [LearnCondition] = [
    LearnCondition(
        id: "elbow_overview",
        title: "Elbow Injuries",
        bodyArea: .elbow,
        icon: "figure.strengthtraining.traditional",
        overview: """
            The elbow is a hinge joint connecting the humerus, radius, and ulna.
            Common injuries include lateral epicondylitis (tennis elbow), medial
            epicondylitis (golfer's elbow), and UCL sprains. Most respond well
            to structured physiotherapy.
            """,
        recoveryPhases: [
            RecoveryPhase(name: "Pain Relief",     weeks: "0–2 weeks",  color: .red,    description: "Rest, ice, avoid aggravating movements."),
            RecoveryPhase(name: "ROM Recovery",    weeks: "2–6 weeks",  color: .orange, description: "Gentle flexion/extension and forearm rotation."),
            RecoveryPhase(name: "Strengthening",   weeks: "6–12 weeks", color: .green,  description: "Isometric then progressive resistance exercises."),
            RecoveryPhase(name: "Full Function",   weeks: "3–6 months", color: .blue,   description: "Return to sport and overhead activities.")
        ],
        techniques: [
            Technique(name: "Wrist Flexor Stretch", icon: "hand.raised", description: "Extend arm, gently pull fingers back to stretch forearm."),
            Technique(name: "Elbow Flexion/Extension", icon: "arrow.up.and.down", description: "Slowly bend and straighten elbow through full range."),
            Technique(name: "Forearm Pronation/Supination", icon: "arrow.2.circlepath", description: "Rotate forearm palm-up to palm-down with elbow at 90°.")
        ],
        helperTip: "Support the elbow at 90° on a table during stretches — this isolates the forearm muscles and prevents shoulder compensation.",
        recommendedExercises: Exercise.elbowExercises
    )
]
```
🟡 Feature: General Pain & Wellness Section in Learn Tab
Add a new top-level "Wellness" or "Recovery Tips" category separate from body-area specific content:

```swift
static let generalWellnessContent = LearnWellnessSection(
    categories: [

        WellnessCategory(
            title: "Nutrition for Recovery",
            icon: "fork.knife",
            tint: .green,
            tips: [
                WellnessTip(
                    headline: "Protein rebuilds tissue",
                    body: "Aim for 1.6–2.2g of protein per kg of bodyweight daily during active rehab. Chicken, eggs, Greek yogurt, and legumes are ideal sources.",
                    source: "PMC Nutritional Rehabilitation, 2020"
                ),
                WellnessTip(
                    headline: "Omega-3s reduce inflammation",
                    body: "Fish oil (2–3g EPA/DHA daily) has been shown to reduce joint inflammation and support tendon healing. Salmon and walnuts are natural sources.",
                    source: "Journal of Sports Science, 2021"
                ),
                WellnessTip(
                    headline: "Vitamin C for collagen synthesis",
                    body: "500mg of Vitamin C taken 30–60 min before exercise enhances collagen production in tendons and ligaments. Citrus, bell peppers, and kiwi are great sources.",
                    source: "American Journal of Clinical Nutrition, 2019"
                ),
                WellnessTip(
                    headline: "Stay hydrated",
                    body: "Cartilage is 65–80% water. Even mild dehydration reduces joint lubrication and slows tissue repair. Aim for 2–3L per day during recovery.",
                    source: "Physiopedia Hydration Guidelines"
                )
            ]
        ),

        WellnessCategory(
            title: "Rest & Sleep",
            icon: "moon.zzz.fill",
            tint: .indigo,
            tips: [
                WellnessTip(
                    headline: "Deep sleep = tissue repair",
                    body: "Growth hormone — which drives muscle and tendon repair — is primarily released during deep sleep (stages 3–4). Aim for 7–9 hours per night.",
                    source: "Sleep Foundation, 2023"
                ),
                WellnessTip(
                    headline: "Rest days are prescribed",
                    body: "Soft tissue needs 48–72 hours between intense sessions for collagen remodeling. Your plan's schedule is built around this window intentionally.",
                    source: "British Journal of Sports Medicine"
                ),
                WellnessTip(
                    headline: "Elevate when swelling is present",
                    body: "For limb injuries, elevating above heart level for 20 min post-session reduces fluid accumulation and speeds next-day recovery.",
                    source: "OrthoInfo AAOS"
                )
            ]
        ),

        WellnessCategory(
            title: "Pain Management",
            icon: "waveform.path.ecg.rectangle",
            tint: .orange,
            tips: [
                WellnessTip(
                    headline: "Pain vs. discomfort — know the difference",
                    body: "Mild muscle fatigue (2–4/10) during exercise is normal and productive. Sharp, shooting pain above 6/10 means stop immediately and rest for 24–48 hours.",
                    source: "Physiopedia Pain Guidelines"
                ),
                WellnessTip(
                    headline: "Ice for acute injury (first 72 hours)",
                    body: "Apply for 15–20 min every 2–3 hours in the first 3 days post-injury. After 72 hours, switch to heat to promote circulation and healing.",
                    source: "American Physical Therapy Association"
                ),
                WellnessTip(
                    headline: "Heat before, ice after",
                    body: "Apply gentle heat for 10 min before your session to loosen the joint. Apply ice for 15 min after to reduce post-exercise inflammation.",
                    source: "OrthoInfo AAOS, 2022"
                )
            ]
        ),

        WellnessCategory(
            title: "Mental Recovery",
            icon: "brain.head.profile",
            tint: .purple,
            tips: [
                WellnessTip(
                    headline: "Consistency beats intensity",
                    body: "Studies show patients who do moderate daily exercise recover 40% faster than those who push hard then skip days. Your streak matters more than any single session.",
                    source: "JMIR Rehabilitation, 2022"
                ),
                WellnessTip(
                    headline: "Visualize the movement",
                    body: "Mental rehearsal of the exercise before performing it activates the same neural pathways as physical practice, reducing fear of movement during rehab.",
                    source: "Journal of Neurophysiology, 2018"
                )
            ]
        )
    ]
)
```
Full Prioritized Roadmap
Priority	Item	Type	Effort
🔴 P0	Exercise data missing in Schedule	Bug	30 min
🔴 P0	AR no body detected fallback UI	Bug	45 min
🔴 P0	Assistive mode back navigation	Bug	20 min
🔴 P0	ARSession not reinitializing on re-entry	Bug	30 min
🟠 P1	Add Elbow to Learn/Knowledge Hub	Feature	45 min
🟠 P1	General Pain / Wellness section in Learn	Feature	1 hr
🟡 P2	Debug raw joint name string showing in AR overlay	Polish	15 min
🟡 P2	AR overlay ultraThinMaterial header (from earlier)	Polish	30 min
The debug string right_arm_joint→right_forearm_joint→right_hand_joint angle:145.4° visible in should also be removed before filming — that's a raw debug label that shouldn't show in the final demo. Replace it with your styled AngleDisplay component.
​