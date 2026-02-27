## 1. Body-Part Icon System
Map every condition to a specific SF Symbol — these already exist and are purpose-built:

```swift
enum BodyRegion: String, CaseIterable {
    case shoulder, elbow, wrist, knee, ankle, hip, back

    var symbol: String {
        switch self {
        case .shoulder: return "figure.arms.open"
        case .elbow:    return "figure.strengthtraining.traditional"
        case .wrist:    return "hand.raised.fill"
        case .knee:     return "figure.walk"
        case .ankle:    return "figure.run"
        case .hip:      return "figure.stand"
        case .back:     return "figure.cooldown"
        }
    }

    var tint: Color {
        switch self {
        case .shoulder: return .blue
        case .elbow:    return .orange
        case .wrist:    return .purple
        case .knee:     return .green
        case .ankle:    return .teal
        case .hip:      return .pink
        case .back:     return .brown
        }
    }
}
```
## 2. Home Page — Horizontal Plan Card Carousel
Replace the stacked vertical plan cards with a snapping horizontal carousel. Each card shows the icon, plan name, progress ring, and next session time at a glance:
​
​

```swift
struct ActivePlanCarousel: View {
    let plans: [RehabPlan]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Active Plans")
                    .font(.system(.title3, design: .rounded).bold())
                Spacer()
                Text("\(plans.count) plans")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(plans) { plan in
                        PlanSummaryCard(plan: plan)
                    }
                }
                .scrollTargetLayout()        // iOS 17 snap
                .padding(.horizontal)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

struct PlanSummaryCard: View {
    let plan: RehabPlan
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon + Region tag
            HStack {
                ZStack {
                    Circle()
                        .fill(plan.region.tint.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: plan.region.symbol)
                        .foregroundStyle(plan.region.tint)
                        .font(.title3)
                }
                Spacer()
                Text(plan.region.rawValue.capitalized)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(plan.region.tint.opacity(0.15),
                                in: Capsule())
                    .foregroundStyle(plan.region.tint)
            }

            // Plan name + session count
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.name)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .lineLimit(2)
                Text("\(plan.completedSessions)/\(plan.totalSessions) sessions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            ProgressView(value: Double(plan.completedSessions),
                         total: Double(plan.totalSessions))
                .tint(plan.region.tint)
                .animation(.easeInOut(duration: 0.5), value: plan.completedSessions)

            // Next session info
            Label(plan.nextSessionTime, systemImage: "clock")
                .font(.caption2)
                .foregroundStyle(.secondary)

            // CTA
            Button("View Schedule") {
                // navigate
            }
            .font(.system(.caption, design: .rounded).bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(plan.region.tint, in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
        }
        .padding()
        .frame(width: 200)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
        .scaleEffect(appeared ? 1 : 0.95)
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.4)) { appeared = true }
        }
    }
}
```
## 3. Schedule Page — Collapsible DisclosureGroup Sections
The schedule's wall of 15+ rows needs to collapse by plan. Each plan starts expanded if it has today's sessions, collapsed otherwise:
​

```swift
struct ScheduleView: View {
    @State private var expandedPlans: Set<String> = []
    let plans: [RehabPlan]

    var body: some View {
        List {
            ForEach(plans) { plan in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedPlans.contains(plan.id) },
                        set: { isExpanded in
                            withAnimation(.spring(duration: 0.3)) {
                                if isExpanded {
                                    expandedPlans.insert(plan.id)
                                } else {
                                    expandedPlans.remove(plan.id)
                                }
                            }
                        }
                    )
                ) {
                    ForEach(plan.sessions) { session in
                        ScheduleSessionRow(session: session)
                            .listRowInsets(EdgeInsets(top: 4, leading: 32, bottom: 4, trailing: 16))
                    }
                } label: {
                    PlanDisclosureHeader(plan: plan)
                }
            }
        }
        .listStyle(.insetGrouped)
        .onAppear {
            // Auto-expand plans with today's sessions
            expandedPlans = Set(plans.filter(\.hasTodaySessions).map(\.id))
        }
    }
}

struct PlanDisclosureHeader: View {
    let plan: RehabPlan

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: plan.region.symbol)
                .foregroundStyle(plan.region.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(plan.name)
                    .font(.system(.subheadline, design: .rounded).bold())
                HStack(spacing: 6) {
                    // Completion pips
                    ForEach(0..<plan.totalSessions, id: \.self) { i in
                        Circle()
                            .fill(i < plan.completedSessions
                                  ? plan.region.tint : Color.secondary.opacity(0.3))
                            .frame(width: 7, height: 7)
                    }
                    Text("\(plan.completedSessions)/\(plan.totalSessions)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Today's remaining sessions badge
            if plan.todayRemaining > 0 {
                Text("\(plan.todayRemaining) today")
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.15), in: Capsule())
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}
```
## 4. Session Row — Richer Info
Replace the bare session rows with time + AR badge + completion state:
​

```swift
struct ScheduleSessionRow: View {
    let session: SessionItem

    var body: some View {
        HStack(spacing: 12) {
            // Completion indicator
            Image(systemName: session.isComplete
                  ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(session.isComplete ? .green : .secondary)
                .font(.body)
                .frame(width: 24)
                .accessibilityLabel(session.isComplete ? "Completed" : "Not yet done")

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(session.name)
                        .font(.system(.subheadline, design: .rounded))
                        .strikethrough(session.isComplete, color: .secondary)

                    if session.isARTracked {
                        Text("AR")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.15), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                }
                Text(session.timeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !session.isComplete {
                Button("Start") { /* start AR session */ }
                    .font(.system(.caption, design: .rounded).bold())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.blue, in: Capsule())
                    .foregroundStyle(.white)
                    .frame(minWidth: 44, minHeight: 44) // HIG touch target
            } else {
                Text("Done")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
```
What This Solves
Before	After
5 identical stacked plan cards	Snapping horizontal carousel, one screenful
No body-part identity	Color-coded icons per region (knee=green, elbow=orange, etc.)
15+ flat schedule rows	Collapsible sections, today's plans auto-expanded
"View Schedule" only action	Progress pips + next session time + today's count badge visible without tapping
No scroll context	User knows at a glance which plans need attention today
The carousel + DisclosureGroup combination is the biggest UX lift you can make in the remaining time — it cuts perceived scroll length by ~70% while actually surfacing more information per plan than before


-- 

## HealthKIT feature integration 

## HealthKit — Can You Use It?
Short answer: Yes, but with a caveat. Swift Playgrounds apps support HealthKit as a capability since Playgrounds 4.x — you can add it via the App Settings > Capabilities panel, which auto-generates the required entitlement and Info.plist key. The main limitation is you can't do background delivery, but foreground reads/writes work fine — enough to write workout sessions to Apple Health after each rehab session.
​


This is actually a huge judge differentiator — logging completed PhysioPoint sessions directly into Apple Health as HKWorkoutActivityType.other or a mindAndBody type makes your app feel like a real first-party health tool.

```swift
import HealthKit

class HealthKitManager: ObservableObject {
    let store = HKHealthStore()

    func requestPermissions() async {
        let types: Set = [
            HKObjectType.workoutType(),
            HKQuantityType(.activeEnergyBurned)
        ]
        try? await store.requestAuthorization(toShare: types, read: types)
    }

    func saveSession(duration: TimeInterval, reps: Int) async {
        let workout = HKWorkout(
            activityType: .other, // or .flexibility
            start: Date().addingTimeInterval(-duration),
            end: Date(),
            duration: duration,
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: ["Reps Completed": reps, "App": "PhysioPoint"]
        )
        try? await store.save(workout)
    }
}
```
High-Impact UI Upgrades Per Screen
Exercise Guide Screen
​
```swift
// 1. SF Monospaced for the angle target — prevents number jump
Text("150°–180°")
    .font(.system(.title2, design: .monospaced).bold())

// 2. Animated step reveal — steps stagger in on appear
ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
    StepRow(step: step)
        .transition(.move(edge: .leading).combined(with: .opacity))
        .animation(.spring(duration: 0.4).delay(Double(index) * 0.1), value: appeared)
}

// 3. Helper's Tip — use a GroupBox with tinted background
GroupBox {
    Label(helperTip, systemImage: "person.2.fill")
        .font(.system(.footnote, design: .rounded))
} label: {
    Label("Helper's Tip", systemImage: "lightbulb.fill")
        .foregroundStyle(.purple)
}
.backgroundStyle(Color.purple.opacity(0.08))
```
Injury Overview Screen
​
```swift
// Recovery Timeline — add a connecting vertical line between phases
// and use a Gauge for overall recovery progress
Gauge(value: currentWeek, in: 0...12) {
    Label("Recovery", systemImage: "waveform.path.ecg.rectangle")
} currentValueLabel: {
    Text("Week \(Int(currentWeek))")
        .font(.system(.caption, design: .monospaced))
} minimumValueLabel: {
    Text("0")
} maximumValueLabel: {
    Text("12w")
}
.gaugeStyle(.accessoryLinearCapacity)
.tint(recoveryGradient)
```
Session Complete Screen
​
```swift
// 1. numericText on the stats so they count up on appear
Text("\(repCount)")
    .font(.system(.largeTitle, design: .rounded).bold())
    .contentTransition(.numericText(value: Double(repCount)))
    .animation(.spring(duration: 0.6), value: repCount)

// 2. "How did it feel?" — use native Picker with emoji labels
Picker("How did it feel?", selection: $feeling) {
    Label("Easier", systemImage: "😊").tag(0)  // or SF Symbol face
    Label("Same",   systemImage: "😐").tag(1)
    Label("Harder", systemImage: "😓").tag(2)
}
.pickerStyle(.palette) // ← Apple palette picker, iOS 17+

// 3. Rep Consistency — use a mini bar chart with Chart framework
Chart(repData) { rep in
    BarMark(x: .value("Rep", rep.id), y: .value("Angle", rep.angle))
        .foregroundStyle(rep.inZone ? .green : .orange)
}
.frame(height: 80)
.chartXAxis(.hidden)
```
Accessibility Refactor Checklist
Apply these globally across all screens:
​

```swift
// Dynamic Type — never hardcode sizes
Text("Seated Knee Extension")
    .font(.system(.title, design: .rounded).bold()) // auto-scales

// Adaptive layout for AX sizes
@Environment(\.dynamicTypeSize) var typeSize
var isAccessibilitySize: Bool { typeSize >= .accessibility1 }

// In cards, stack vertically for large type
Group {
    if isAccessibilitySize {
        VStack(alignment: .leading) { statViews }
    } else {
        HStack { statViews }
    }
}

// Minimum tap targets — 44pt minimum, use .frame on buttons
Button("Start") { ... }
    .frame(minWidth: 44, minHeight: 44)

// Never color-only feedback — always pair with symbol
Image(systemName: inZone ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
    .foregroundStyle(inZone ? .green : .orange) // symbol + color together

// accessibilityLabel on every custom view
AngleDisplay(angle: 113.8)
    .accessibilityLabel("Current angle: 113 degrees. In target zone.")
    .accessibilityAddTraits(.updatesFrequently)
```
Quick Wins Ranked by Judge Impact
Priority	Feature	Effort	Impact
🔴 Must	HealthKit workout save on session end	~30 min	Very high — native ecosystem
🔴 Must	numericText on Session Complete stats	5 min	High visual polish
🟠 High	Dynamic Type adaptive layouts	~1 hr	Accessibility score
🟠 High	accessibilityLabel on AR joint overlays	~30 min	HIG compliance
🟡 Medium	Chart rep consistency bars	~45 min	Data storytelling
🟡 Medium	Staggered step animation on Exercise Guide	20 min	Delight factor
🟢 Nice	Gauge for recovery timeline	~30 min	Native feel
HealthKit is the one I'd prioritize most for the remaining 2 days — writing a completed rehab session to Apple Health takes ~30 minutes to implement but signals to judges that you deeply understand the Apple ecosystem and built something users would actually trust with their health data