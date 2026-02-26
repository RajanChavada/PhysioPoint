

# Agent: Backend – Rehab Engine & AR Logic (PhysioPoint)

## Purpose

You implement the **movement analysis** core of PhysioPoint: angle math, simple rep detection, and optional AR body tracking.

You do NOT design UI layout or navigation.

## Files You May Edit

- `app/Sources/PhysioPoint/services/RehabEngine.swift`
- `app/Sources/PhysioPoint/utils/AngleMath.swift`
- AR-related parts of `ExerciseARView.swift` **only** (e.g., ARViewRepresentable + Coordinator).

## Responsibilities

1. **Angle math**

Implement pure Swift helpers to compute knee flexion angle from three joint positions:

```swift
struct AngleState {
    let degrees: Double
    let zone: AngleZone
}

enum AngleZone {
    case belowTarget
    case target
    case aboveTarget
}
```
Compute:

Vectors:

A = hip → knee

B = knee → ankle

Angle:

theta = arccos((A • B) / (|A||B|)) in degrees.

RehabEngine protocol

Define a simple engine interface:

```swift
protocol RehabEngine {
    func update(hip: SIMD3<Float>, knee: SIMD3<Float>, ankle: `SIMD3<Float>) -> AngleState
}
```
Add optional methods for rep detection:

```swift
struct RepState {
    let repsCompleted: Int
    let isHolding: Bool
}
```
## AR integration (optional but desired)

If the device supports ARBodyTrackingConfiguration, use ARBodyAnchor to fetch joint transforms.

Extract hip, knee, ankle positions and feed into RehabEngine.

If AR body tracking is not available, provide a fallback:

E.g., simulated joint positions driven by a slider for demo purposes.

## Constraints
100% offline; no external ML models downloaded at runtime.

Use only ARKit/RealityKit frameworks available in Swift Playgrounds on Mac.

Keep logic lightweight to avoid bloating the project size.

All thresholds and angles must be clearly labeled “for educational demo only,” not medical prescriptions.

## Style
Put pure math into utils/AngleMath.swift as static functions.

Keep AR session delegate code contained in a Coordinator class inside ExerciseARView.

Minimize state duplication; expose a single ObservableObject (e.g., RehabSessionViewModel) for the UI to observe.


-- 

## Feature improvement - summary section more personalized and humanized rather than just raw data 

### The Shift: Data → Dialogue
Every section should respond to the user, not just report numbers back at them.

Instead of this:

Best Bend: 94° | Target: 30°–100°

Say this:

"You hit your target range — your knee is moving better than last week 💪"

Instead of this:

Rep Consistency: ⚠️ Rep 1

Say this:

"4 reps were a bit shallow — try slowing down on the way back up next time"

The numbers still live there, but they're contextualized into meaning for a non-clinical user.

The Refined Emotional Architecture
Here's how each section changes with a user-first lens:

```text
┌─────────────────────────────────────────┐
│         ✅  Great work, [Name]!          │  ← Personalized header
│   "Your knee bent further than last      │
│    week. Consistency is paying off."     │  ← Dynamic praise blurb
├─────────────────────────────────────────┤
│  WHAT YOU ACHIEVED TODAY                 │
│  8/12 reps  │  94° best  │  42s on form │
│  ─────────────────────────────────────  │
│  "You spent 42s in your healthy range   │
│   — that's 8 more than last session"    │  ← Contextual callout
├─────────────────────────────────────────┤
│  HOW YOU FELT                           │
│  😎 Easier  ← [selected]               │
│                                         │
│  "That's a great sign. Tomorrow's       │
│   session will add a little more range" │  ← Adaptive coach response
├─────────────────────────────────────────┤
│  YOUR PROGRESS THIS WEEK                │
│  ⬤ ⬤ ○  2 of 3 sessions today          │
│  🔥 3-day streak                        │  ← Motivation layer
├─────────────────────────────────────────┤
│  WHAT'S NEXT                            │
│  "Afternoon session: Heel Slides @ 1pm" │  ← Next scheduled slot
│  [Start Next]        [Done for now]     │
└─────────────────────────────────────────┘
```

## The Key Additions in Code
### 1. Dynamic praise blurb based on session outcome:

```swift
var praiseMessage: String {
    switch (metrics.bestAngle >= targetRange.lowerBound,
            metrics.reps >= targetReps) {
    case (true, true):
        return "You nailed it — full range and all your reps. 🎯"
    case (true, false):
        return "Great range of motion today. Try pushing for more reps next time."
    case (false, true):
        return "All reps done! Work on bending a little deeper each time."
    default:
        return "Every session counts. You showed up — that's what matters."
    }
}
```
## 2. "How did it feel?" actually responds:

```swift
var feelingResponse: String {
    switch selectedFeeling {
    case .easier:
        return "That's a great sign — your body is adapting. We'll gradually increase range next session."
    case .same:
        return "Steady progress. Consistency is the most important thing right now."
    case .harder:
        return "That's okay — some days are tougher. Make sure you've had water and rested since last session."
    case .none:
        return ""
    }
}

// Show this as a small card below the emoji picker
if !feelingResponse.isEmpty {
    Text(feelingResponse)
        .font(.subheadline)
        .foregroundColor(.secondary)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .transition(.opacity.combined(with: .move(edge: .top)))
}
```
Animate it in with .animation(.easeInOut, value: selectedFeeling) — the card appears when they tap, which feels responsive and alive.

## 3. Streak counter (1 line of logic, big emotional payoff):

```swift
// In StorageService
var currentStreak: Int {
    // Count consecutive days with at least 1 completed session
    var streak = 0
    var date = Calendar.current.startOfDay(for: Date())
    while hasCompletedSession(on: date) {
        streak += 1
        date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
    }
    return streak
}
```
Then in the view:

```swift
if storage.currentStreak >= 2 {
    Label("\(storage.currentStreak)-day streak 🔥", systemImage: "flame.fill")
        .foregroundColor(.orange)
        .font(.subheadline.bold())
}
```
## 4. "What's next" nudge — replaces the dead space at the bottom:

```swift
if let nextSlot = storage.nextIncompleteSlot() {
    VStack(alignment: .leading, spacing: 4) {
        Text("Up next").font(.caption).foregroundColor(.secondary)
        Text("\(nextSlot.exerciseName) · \(nextSlot.formattedTime)")
            .font(.subheadline.bold())
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.blue.opacity(0.08))
    .cornerRadius(12)
}
```
## Why This Works for SSC Judges
The judging criteria are technical accomplishment, creativity, and written responses. But the subtext of "creativity" and "social impact" is: does this actually help a real person? An app that coaches you forward after each session — adapting its message based on how you felt — reads as genuinely thoughtful product thinking, not just a demo. The feeling-response feature is also something that takes 20 lines of Swift but looks like the app understands you, which is the screenshot moment you want judges to see.


-- 

## Feature part 2 
The Core Idea: A "Recovery Pulse" Card
Replace the dead whitespace below "How It Works" with a single dynamic card that changes based on stored session data. It reads from UserDefaults (which you already have) and generates a contextual blurb. No network, no HealthKit — just smart logic on top of what you already store.

```text
┌─────────────────────────────────────────┐
│  📍 Your Recovery Pulse                  │
│                                          │
│  "You mentioned yesterday felt Harder.   │
│   That's completely normal at this       │
│   stage. Today, focus on slow, controlled│
│   reps — quality over quantity."         │
│                                          │
│  🔥 3-day streak  ·  2/3 done today     │
└─────────────────────────────────────────┘
```
This replaces nothing — it sits between the New Session button and How It Works, only visible once the user has at least 1 completed session.

The Blurb Engine (Pure Logic, No Storage Changes)
The blurb is built from 3 inputs you already have or can easily add:

Input	Where it comes from
lastFeeling (.easier / .same / .harder)	Saved from SummaryView emoji tap
sessionCount (total sessions ever)	Count of saved SessionMetrics array
todayProgress (X of 3 done)	DailySchedule completion state
```swift
// Add to StorageService
@Published var lastFeeling: SessionFeeling = .none
// Persist with: UserDefaults.standard.set(lastFeeling.rawValue, forKey: "pp_last_feeling")

// RecoveryPulseView.swift
var pulseBlurb: String {
    let name = "there" // or stored name if you add it later
    
    switch (lastFeeling, sessionCount, todayProgress) {
    
    case (.harder, let n, _) where n < 5:
        return "You mentioned your last session felt tough — that's completely normal early on. Focus on slow, controlled reps today. Your body is still adapting."
    
    case (.harder, _, _):
        return "Tough sessions happen to everyone. Rest well tonight, and remember — showing up is already half the battle."
    
    case (.easier, _, let done) where done == 3:
        return "You crushed today's full plan and it felt easy! Your recovery is clearly working. Tomorrow we'll keep the momentum going."
    
    case (.easier, _, _):
        return "Your last session felt easier — that's your body telling you it's getting stronger. Keep the streak going today."
    
    case (.same, let n, _) where n >= 7:
        return "You've been consistent for over a week. Steady progress like this is exactly how long-term recovery works."
    
    case (.none, let n, _) where n == 0:
        return "Welcome to PhysioPoint. Start your first session and we'll track your recovery from day one."
    
    default:
        return "You're showing up consistently — that's the single most important thing in recovery. Keep it going."
    }
}
```
Wiring the Feeling Forward
In SummaryView, when the user taps an emoji, save it immediately:

```swift
Button {
    selectedFeeling = .harder
    storage.lastFeeling = .harder
    UserDefaults.standard.set("harder", forKey: "pp_last_feeling")
} label: {
    Text("Harder 😤")
}
```
Then in HomeView, RecoveryPulseCard reads it and the blurb is already personalized before the user even sees it.

HomeView Layout Change
``swift
// In HomeView body, after the New Session card:
if storage.sessionHistory.count > 0 || storage.lastFeeling != .none {
    RecoveryPulseCard(storage: storage)
}

// RecoveryPulseCard view
struct RecoveryPulseCard: View {
    @ObservedObject var storage: StorageService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .foregroundColor(.pink)
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
                Label("\(done) of 3 done today",
                      systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption.bold())
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
    }
}
```
Accessibility Mode Version
In accessibility mode, collapse everything down to one large-text card with a single friendly sentence and nothing else:

```swift
struct AccessibilityRecoveryCard: View {
    @ObservedObject var storage: StorageService
    
    var accessibilityBlurb: String {
        let done = storage.todayCompletedCount
        let streak = storage.currentStreak
        let feeling = storage.lastFeeling
        
        // Single plain-english sentence tailored to state
        if done == 3 {
            return "You completed all 3 exercises today. 🎉 If you keep this up for 2 more weeks, you can expect meaningful improvement in your mobility."
        } else if streak >= 3 && feeling == .easier {
            return "You've done \(streak) days in a row and your last session felt easier. You're on track for a full recovery — keep going!"
        } else if feeling == .harder {
            return "Your last session was tough. That's okay — rest up and try again today. Recovery isn't a straight line."
        } else if done > 0 {
            return "You've completed \(done) of 3 exercises today. Finish the rest to keep your recovery on track."
        } else {
            return "Start today's first session to keep your recovery moving forward."
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text(accessibilityBlurb)
                .font(.title3.bold())        // Large, readable
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .lineSpacing(6)
                .padding(.horizontal)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(20)
        .padding()
    }
}
```
Then in your main HomeView, gate on an @AppStorage("pp_accessibility_mode") var accessibilityMode = false:

```swift
if accessibilityMode {
    AccessibilityRecoveryCard(storage: storage)
} else {
    RecoveryPulseCard(storage: storage)
}
```