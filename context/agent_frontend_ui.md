
# Agent: Frontend UI & Navigation (PhysioPoint)

## Purpose

You own the **SwiftUI screens and navigation flow** that produce a clear 3-minute demo for judges.  
You do **not** implement AR math, storage internals, or business logic beyond simple wiring.

## Files You May Edit

- `app/Sources/PhysioPoint/ContentView.swift`
- `app/Sources/PhysioPoint/TriageView.swift`
- `app/Sources/PhysioPoint/ScheduleView.swift`
- `app/Sources/PhysioPoint/SessionIntroView.swift`
- `app/Sources/PhysioPoint/ExerciseARView.swift` (UI layer only; AR logic is in backend agent)
- `app/Sources/PhysioPoint/SummaryView.swift`
- Any additional `Views/` files dedicated to UI only.

You MAY read from:

- `models/*`
- `services/*`

But you MUST NOT put complex math, ARKit session management, or persistence logic inside views.

## Target 3-Minute Flow

Design and maintain a single "happy path" that a judge can complete in ≤ 3 minutes:

1. **ContentView**
   - Welcome screen.
   - Short 1–2 line explanation of PhysioPoint.
   - Button: “Start” → goes to TriageView.

2. **TriageView**
   - Ask: “Where is your main issue today?”
   - For demo: highlight **Knee** and one issue, e.g., “Hard to bend past 90°.”
   - Once selected, set `PhysioPointState.selectedCondition` and go to ScheduleView or SessionIntroView.

3. **ScheduleView** (optional but nice)
   - Show "Today's Plan": e.g., 3 × Heel Slides.
   - Provide a “Start Now” button that jumps straight to SessionIntroView for the chosen exercise.

4. **SessionIntroView**
   - Show the selected exercise name + a short description.
   - Simple diagram or text instructions.
   - Button: “Begin practice” → navigates to ExerciseARView.

5. **ExerciseARView**
   - Host the live session view:
     - Area showing camera/AR overlay.
     - Simple HUD: current angle, rep count, color zone indicator.
   - When reps are complete, present a button to finish and go to SummaryView.

6. **SummaryView**
   - Show metrics from `SessionMetrics`:
     - Reps completed.
     - Best angle achieved.
   - Include clear medical disclaimer text.

## Constraints

- All views must be **SwiftUI** and run in Swift Playgrounds on Mac.[CHALLENGE_REQUIREMENTS.md]
- No networking, no sign-in flows, no analytics.
- Copy must be in English only.
- UI should be understandable without reading long blocks of text — judges have ~3 minutes total.

## Style

- Use `PhysioPointState` (ObservableObject) as the app-wide state, injected via `.environmentObject` in `ContentView`.
- Keep views relatively small:
  - Avoid functions longer than ~100 lines.
  - Extract subviews for repeated UI components (e.g., cards, HUDs).
- Favor `NavigationStack` or simple view switching logic for navigation.

## Hand-offs

For AR angle/rep info, assume a backend interface like:

```swift
@ObservedObject var rehabSession: RehabSessionViewModel
// Provides: currentAngle, angleZone, repsCompleted, isGoalReached
```

```swift
@ObservedObject var rehabSession: RehabSessionViewModel
// Provides: currentAngle, angleZone, repsCompleted, isGoalReached
You display these values; you do not compute them.
```

***


-- 

## Feature roadmap -> front facing body select 
Interactive Body Map in Swift Playgrounds (SwiftUI)
This guide explains how to build a clickable body map using a front-facing body PNG and invisible touch regions (head, shoulders, knees, etc.). It is designed for Swift Playgrounds but is fully compatible with normal SwiftUI apps.

## 1. Project Setup
### 1.1 Requirements
Swift Playgrounds (iPad or macOS) or an Xcode Swift Playground.

A front-facing human body PNG with a transparent background, roughly portrait aspect ratio.

## 1.2 Add the Body Image
Open your Playground.

Locate the Resources (or “Resources” folder in Xcode’s navigator).

Drag your image into Resources and name it, for example: body_front.png.

You will refer to it as Image("body_front") in code (without the .png extension).
​
​

## 2. Rendering SwiftUI in a Playground
Use PlaygroundSupport to show a SwiftUI view as the live view.

```swift
import SwiftUI
import PlaygroundSupport

struct BodyMapView: View {
    var body: some View {
        Text("Body map goes here")
    }
}
```   
// Show SwiftUI in the live view
PlaygroundPage.current.setLiveView(BodyMapView())
PlaygroundPage.current.setLiveView(...) is the simplest way to show a SwiftUI view in a Playground.

You will replace BodyMapView’s body with the actual body map UI.

## 3. Core Concept: Transparent, Tappable Overlays
We need “hit targets” over the body image that are:

Invisible (so the user only sees the body image).

Tappable (so each region triggers logic).

In SwiftUI, transparent shapes do not receive gestures by default unless we define a contentShape to make them hit-testable.
​
​

## 3.1 Why contentShape Is Required
A rectangle with .fill(.clear) is visually invisible and often ignored by hit-testing.

contentShape(Rectangle()) tells SwiftUI: “Treat this rectangular frame as the tappable area, even if it’s clear.”
​

Example pattern:

```swift
Rectangle()
    .fill(Color.clear)
    .contentShape(Rectangle()) // crucial so taps register on a clear shape
    .onTapGesture {
        // handle tap
    }
```
## 4. Basic Body Map Layout
This section builds a minimal interactive body map with a few regions: head, shoulders, knees, feet.

## 4.1 High-Level Structure
We use:

ZStack to layer the body image and tappable regions.

A fixed frame (e.g., width 250, height 500) to make positioning predictable.

.position(x:y:) to place each region over the correct body part.
​

## 4.2 Full Example
```swift
import SwiftUI
import PlaygroundSupport

struct BodyMapView: View {
    @State private var selectedPart: String? = nil

    var body: some View {
        ZStack {
            // 1. Base body image
            Image("body_front")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 500)

            // 2. Head region
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: 80, height: 80)
                .position(x: 125, y: 60)
                .onTapGesture {
                    selectedPart = "Head"
                }

            // 3. Shoulder region (one combined area)
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: 200, height: 60)
                .position(x: 125, y: 130)
                .onTapGesture {
                    selectedPart = "Shoulders"
                }

            // 4. Knees region
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: 120, height: 60)
                .position(x: 125, y: 350)
                .onTapGesture {
                    selectedPart = "Knees"
                }

            // 5. Feet region
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: 120, height: 80)
                .position(x: 125, y: 440)
                .onTapGesture {
                    selectedPart = "Feet"
                }
        }
        .frame(width: 250, height: 500)
        .overlay(alignment: .bottom) {
            Text(selectedPart ?? "Tap a body part")
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
        }
    }
}

// Show in playground live view
PlaygroundPage.current.setLiveView(BodyMapView())
Key behaviors:

Tapping a region updates selectedPart, and the overlay text shows which region was selected.

The transparent rectangles are only interaction layers; the user only sees the body image.

## 5. Positioning Strategy
### 5.1 Coordinate System
The ZStack is given a fixed frame of 250 x 500.

.position(x:y:) coordinates are relative to the top-left corner of this frame.

x increases to the right.

y increases downward.

Example: position(x: 125, y: 60) places the region horizontally centered (half of 250) and near the top.
​

## 5.2 Tuning Overlays to Your PNG
Because every body image is slightly different, you must:

Start with approximate frames and positions.

Run the playground.

Tap around and adjust x, y, width, and height for each region until coverage matches your PNG.

Recommended workflow:

Temporarily give regions a visible background(Color.red.opacity(0.3)) to see their bounds.

Once aligned, remove the background and keep .fill(Color.clear).

Example debug version:

```swift
Rectangle()
    .fill(Color.clear)
    .background(Color.red.opacity(0.3)) // DEBUG ONLY
    .contentShape(Rectangle())
    .frame(width: 80, height: 80)
    .position(x: 125, y: 60)
```
## 6. Abstracting Regions into a Model
For more maintainable code, define all regions in a data structure and generate overlays in a loop.

## 6.1 Region Model
```swift
struct BodyRegion: Identifiable {
    enum Kind: String {
        case head
        case shoulders
        case knees
        case feet
        // add more as needed
    }

    let id = UUID()
    let kind: Kind
    let center: CGPoint
    let size: CGSize
}
```
## 6.2 Region Definitions
Coordinates assume a 250x500 canvas; adjust to your PNG.

```swift
let bodyRegions: [BodyRegion] = [
    BodyRegion(
        kind: .head,
        center: CGPoint(x: 125, y: 60),
        size: CGSize(width: 80, height: 80)
    ),
    BodyRegion(
        kind: .shoulders,
        center: CGPoint(x: 125, y: 130),
        size: CGSize(width: 200, height: 60)
    ),
    BodyRegion(
        kind: .knees,
        center: CGPoint(x: 125, y: 350),
        size: CGSize(width: 120, height: 60)
    ),
    BodyRegion(
        kind: .feet,
        center: CGPoint(x: 125, y: 440),
        size: CGSize(width: 120, height: 80)
    )
]
```
## 6.3 Generated Overlays
```swift
struct BodyMapView: View {
    @State private var selectedPart: BodyRegion.Kind? = nil

    var body: some View {
        ZStack {
            Image("body_front")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 500)

            ForEach(bodyRegions) { region in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(width: region.size.width,
                           height: region.size.height)
                    .position(region.center)
                    .onTapGesture {
                        selectedPart = region.kind
                    }
            }
        }
        .frame(width: 250, height: 500)
        .overlay(alignment: .bottom) {
            Text(selectedPart?.rawValue.capitalized ?? "Tap a body part")
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
        }
    }
}
```
**Benefits:**

Adding a new region is just adding another BodyRegion entry.

All layout is consolidated in bodyRegions.

##  7. Making Regions Adaptive to Layout
If you want the body map to scale with screen size (rather than a fixed 250x500), use GeometryReader and specify regions in normalized coordinates (0.0–1.0).
​

## 7.1 Normalized Model
```swift
struct NormalizedBodyRegion: Identifiable {
    enum Kind: String {
        case head, shoulders, knees, feet
    }

    let id = UUID()
    let kind: Kind
    let center: CGPoint  // x, y in 0.0...1.0
    let size: CGSize     // width, height in 0.0...1.0
}

let normalizedRegions: [NormalizedBodyRegion] = [
    NormalizedBodyRegion(
        kind: .head,
        center: CGPoint(x: 0.5, y: 0.12),
        size: CGSize(width: 0.32, height: 0.16)
    ),
    NormalizedBodyRegion(
        kind: .shoulders,
        center: CGPoint(x: 0.5, y: 0.26),
        size: CGSize(width: 0.8, height: 0.12)
    ),
    NormalizedBodyRegion(
        kind: .knees,
        center: CGPoint(x: 0.5, y: 0.70),
        size: CGSize(width: 0.48, height: 0.12)
    ),
    NormalizedBodyRegion(
        kind: .feet,
        center: CGPoint(x: 0.5, y: 0.88),
        size: CGSize(width: 0.48, height: 0.16)
    )
]
```
## 7.2 Geometry-Based Layout
```swift
struct AdaptiveBodyMapView: View {
    @State private var selectedPart: NormalizedBodyRegion.Kind? = nil

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("body_front")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width,
                           height: geo.size.height)

                ForEach(normalizedRegions) { region in
                    let width = geo.size.width * region.size.width
                    let height = geo.size.height * region.size.height
                    let x = geo.size.width * region.center.x
                    let y = geo.size.height * region.center.y

                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .frame(width: width, height: height)
                        .position(x: x, y: y)
                        .onTapGesture {
                            selectedPart = region.kind
                        }
                }
            }
            .overlay(alignment: .bottom) {
                Text(selectedPart?.rawValue.capitalized ?? "Tap a body part")
                    .padding(10)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
            }
        }
    }
}
```
This keeps hit areas aligned even if the view scales to different screen sizes or orientations.
​

## 8. Hooking into App Logic
Once a region is tapped, you often want to drive behavior in the rest of the app.

## Ideas:

Emit a callback via a closure.

Use a view model with @ObservedObject / @StateObject.

Navigate to another view or show a sheet with details.

## 8.1 Callback-Based API
```swift
struct BodyMapView: View {
    let onSelect: (BodyRegion.Kind) -> Void

    var body: some View {
        ZStack {
            Image("body_front")
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 500)

            ForEach(bodyRegions) { region in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .frame(width: region.size.width,
                           height: region.size.height)
                    .position(region.center)
                    .onTapGesture {
                        onSelect(region.kind)
                    }
            }
        }
        .frame(width: 250, height: 500)
    }
}
```
Usage:

```swift
struct RootView: View {
    @State private var lastSelected: BodyRegion.Kind?

    var body: some View {
        VStack {
            BodyMapView { part in
                lastSelected = part
                // trigger your logic here
            }

            Text("Last selected: \(lastSelected?.rawValue ?? "None")")
                .padding()
        }
    }
}
```
PlaygroundPage.current.setLiveView(RootView())
## 9. Debugging and Common Pitfalls
Tap doesn’t register:

Ensure contentShape(Rectangle()) is applied to each region.
​
​

Confirm the region’s frame actually overlaps the body image.

Verify the live view is the correct view (setLiveView with the right root).

Whole image is tappable instead of one region:

Check for an invisible view on top of the stack (e.g., a full-screen Rectangle with a gesture).

Ensure only the intended regions have gestures.

Regions misaligned on different devices:

Prefer the GeometryReader + normalized coordinate version for adaptive layouts.
​

## 10. Extending the System
Potential upgrades:

Separate left/right body parts (e.g., left shoulder vs right shoulder) by splitting regions.

Swap front/back body PNGs with a toggle and different region sets.

Animate region highlight on tap (e.g., overlay a semi-transparent colored shape).

Use more complex shapes (paths) instead of rectangles if you need precise contours, by building a Path and using contentShape(Path) for hit testing.


-- 

## Frontend UI kits 

UIKit animations like this are cool, but for Swift Student Challenge and Swift Playgrounds app playgrounds, you should stick to SwiftUI‑first and only drop to UIKit when absolutely necessary. For PhysioPoint, you don’t need UIKit at all to get “Apple‑style” motion.

Here’s how to translate that idea into something aligned with your project:

Use SwiftUI animations for feedback:

Angle badge that smoothly changes color/scale when you hit target.

A glowing ring around the knee icon when a rep completes.

If you really want a capsule‑loading/dots effect (like your UIKit snippet), implement it as a small SwiftUI component:

```swift
struct LoadingDotsView: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(scale(for: index))
                    .opacity(Double(scale(for: index)))
                    .animation(.easeInOut(duration: 0.6).repeatForever().delay(0.1 * Double(index)), value: phase)
            }
        }
        .onAppear { phase = 1 }
    }

    private func scale(for index: Int) -> CGFloat {
        // simple phase-based scaling
        return phase == 0 ? 0.3 : 1.0
    }
}
```
## You can show this:

While calibrating AR (finding the joints).

Between exercises as a transition.

Key reasons to avoid UIKit for PhysioPoint:

Swift Playgrounds app templates are SwiftUI‑centric; mixing UIKit is possible but adds complexity with no scoring benefit.
​
​

You’re on a tight timeline and need:

Stable AR + math

Clear triage → plan → session → summary flow

Solid story and polish

So: treat that UIKit playground info as inspiration for motion, but implement the equivalent using SwiftUI animations inside your existing views. That keeps the project simple, small, and exactly in line with what Apple expects for a 2026 Swift Student Challenge app playground.



-- 

## UI Changes and navigation flow 

## Landing Page view
- Welcome message: “Welcome to PhysioPoint!”
- Create more modular block like layout, with cards, start a new session, or start a session,
- 2 main sections where we have the current session and then start session button which takes you to the triage view 
- If there is an active session, show the current session card with the exercise name, progress, and a button to continue. If there is no active session, show a card prompting the user to start a new session.

## Core landing page one shot 
The Design Concept
Hero Section: A friendly, welcoming header with a relevant 3D-style illustration to set a modern tone.

## Value Proposition (The "Why"): 
- Three clear, scannable points explaining what the app does, using standard Apple UI patterns (colorful icon inside a rounded rect).

## The "Glass Door":
- The background uses a subtle gradient and elements use .ultraThinMaterial to create that depth and frosted glass look.

## Prominent Call to Action (CTA): 
- A large, inviting button anchored to the bottom that clearly indicates the next step ("Begin Assessment").

## The SwiftUI Code
```Swift
import SwiftUI

// MARK: - Main View
struct LandingPageView: View {
    // Using EnvironmentObject to handle navigation in a real app
    // @EnvironmentObject var navigationController: NavigationController
    
    var body: some View {
        ZStack {
            // 1. Background Layer
            // A subtle, modern gradient background
            LinearGradient(
                colors: [Color.teal.opacity(0.15), Color.blue.opacity(0.05), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 2. Main Content ScrollView
            // Using a ScrollView ensures it fits on smaller SE screens too
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // MARK: Hero Section
                    VStack(spacing: 16) {
                        // Placeholder for a nice 3D illustration.
                        // In a real app, replace this Image with a dedicated asset.
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.blue.opacity(0.2), .teal.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 180, height: 180)
                                .blur(radius: 20)
                            
                            Image(systemName: "figure.flexibility")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .foregroundStyle(LinearGradient(colors: [.blue, .teal], startPoint: .top, endPoint: .bottom))
                        }
                        .padding(.top, 40)
                        
                        VStack(spacing: 8) {
                            Text("Welcome to PhysioPoint")
                                .font(.system(.largeTitle, design: .rounded))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                            
                            Text("Your intelligent companion for a faster, smarter recovery journey.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 30)
                        }
                    }
                    
                    // MARK: Value Proposition Section
                    // Glass-morphic container for features
                    VStack(alignment: .leading, spacing: 24) {
                        Text("How it Works")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, -8)
                        
                        FeatureRow(
                            iconColor: .blue,
                            iconName: "camera.viewfinder",
                            title: "AI-Powered Analysis",
                            description: "Clinical-grade motion tracking using just your device's camera."
                        )
                        
                        FeatureRow(
                            iconColor: .teal,
                            iconName: "chart.bar.doc.horizontal.fill",
                            title: "Personalized Plans",
                            description: "Exercises adapted tailored specifically to your condition and goals."
                        )
                        
                        FeatureRow(
                            iconColor: .indigo,
                            iconName: "waveform.path.ecg",
                            title: "Real-time Guidance",
                            description: "Instant visual feedback to ensure you maintain perfect form."
                        )
                    }
                    .padding(24)
                    .background(.ultraThinMaterial) // The "Glass" effect
                    .cornerRadius(24)
                    .shadow(color: Color.black.opacity(0.05), radius: 15, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40) // Push button to bottom area
                }
            }
            
            // 3. Bottom CTA Button (Anchored)
            VStack {
                Spacer()
                Button(action: {
                    // Action to navigate to the triage/onboarding view
                    print("Navigate to Triage")
                    // navigationController.push(.triageView)
                }) {
                    HStack {
                        Text("Begin Assessment")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.teal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(20)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                // Adding a subtle background blur behind the button area for better contrast
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                        .frame(height: 100) // Adjust based on tab bar needs
                        .offset(y: 40)
                        .blur(radius: 10)
                )
            }
        }
    }
}

// MARK: - Helper Component for Features
struct FeatureRow: View {
    let iconColor: Color
    let iconName: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Colorful Icon Container
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: iconName)
                    .font(.system(size: 22))
                    .foregroundColor(iconColor)
            }
            
            // Text Stack
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true) // Ensures text wraps nicely
            }
        }
    }
}

// MARK: - Preview
struct LandingPageView_Previews: PreviewProvider {
    static var previews: some View {
        LandingPageView()
        
        // Preview in Dark Mode to ensure glass effect works
        LandingPageView()
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}
```

## Summary view after the session
- Show the user that they completed the session
- pie chart for the reps completed 
- angle for the best bend they achieved, and the time they held the good for 
- Also tracking the rep consistency, so maybe a small line graph showing how consistent they were across reps (e.g., angle variance or time in target zone).
- and then todays plan checkers, 1/3 like a pie progress bar for the session, and then a how did the session go question with 3 options (good, ok, bad) that they can tap to provide feedback on how they felt the session went. This could be useful for future iterations of the app to correlate subjective feedback with the objective metrics we track. and a done button


## Color scheme we are using with design theme we are going for 

- Action Blue: #007AFF (primary interactive elements)
- Vitality Teal: #30D5C8 (secondary accents, highlights)
- Recovery Indigo: #5856D6 (additional accents, less frequent)
- Glass Background: #F2F7F7 (ultra-thin material background)

Core UI Components 
- PPColor: Centralized color definitions for consistency.
- PPGradient: Predefined gradients for buttons and backgrounds.
- OnboardingPageContent: Reusable view for onboarding screens.
- FeatureRow: Reusable component for the "How It Works" section on the landing page


-- 

## Feature upgrade to the home page view with the new schedule 

- after the user creates their schedule after staring a new session we need to allow the user to update and revisit their scehdule or exercise. add two buttons to view the schedule or revisit an exercise THAT THEY COMPLETED marked as complete in the storage we have 

Maybe something like this: 

┌─────────────────────────────────┐
│  PhysioPoint header              │
├─────────────────────────────────┤
│  Active Plan card               │
│  "Hard to bend past 90°"        │
│  Progress: ●●○ (2/3 today)      │
│  [ Continue Session ]           │
├─────────────────────────────────┤
│  TODAY'S SCHEDULE               │  ← NEW SECTION
│  ┌─────────────────────────┐   │
│  │ ☀️ Morning  8:00 AM     │   │
│  │ Heel Slides             │   │
│  │ ✅ Done  [ Redo ↺ ]    │   │  ← completed state
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ ☀️ Afternoon  1:00 PM   │   │
│  │ Heel Slides             │   │
│  │ [ Start → ]             │   │  ← upcoming state
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 🌙 Evening  6:00 PM    │   │
│  │ Heel Slides             │   │
│  │ [ Start → ]             │   │
│  └─────────────────────────┘   │
├─────────────────────────────────┤
│  + New Session card             │
├─────────────────────────────────┤
│  How It Works                   │
└─────────────────────────────────┘


-- 

## Feature log - navbar on the bottom + knowledge center 
- we are going to now create a navbar at the bottom of the screen and then also create a knowledge center icon where the user can go and learn about common rehab things and other things related to their injury or condition. 

## App Navigation (Tab Bar)
The bottom bar should have 4 tabs that stay consistent across the whole app:

```swift
enum AppTab: String, CaseIterable {
    case home     = "Home"
    case schedule = "Schedule"
    case learn    = "Learn"
    case profile  = "Profile"
}

// SF Symbols
// home     → "house.fill"
// schedule → "calendar"
// learn    → "book.fill"         ← active in your mockup
// profile  → "person.fill"
The TabView wraps your four root views and persists state so navigating back to Learn returns the user to where they were (use .tabItem + NavigationStack per tab, not a single shared nav stack).
```
## Learn Tab: 3-Level Navigation
```text
LearnHomeView
  └── BodyAreaLearnView  (e.g. "Knee")
        └── ConditionDetailView  (e.g. "ACL Tear")
              ├── OverviewSection
              ├── RecoveryPhaseSection  (timeline)
              ├── TechniqueCardsSection
              ├── AtHomeRehabSection    ← links back to Exercise session
              └── WhenToSeeDoctorSection
```
## Level 1: LearnHomeView (matches your mockup)
This is exactly what you've built in the image. The structure in SwiftUI:

```swift
struct LearnHomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Hero header
                    LearnHeaderView()          // title + subtitle

                    // Search bar
                    SearchBar(placeholder: "Search conditions, body parts...")

                    // 2x2 body area grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(LearnBodyArea.allCases) { area in
                            NavigationLink(destination: BodyAreaLearnView(area: area)) {
                                BodyAreaCard(area: area)
                            }
                        }
                    }

                    // Recovery Essentials horizontal scroll
                    SectionHeader(title: "Recovery Essentials")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            EssentialCard(title: "Sleep & Recovery", icon: "bed.double.fill")
                            EssentialCard(title: "Hydration & Nutrition", icon: "drop.fill")
                            EssentialCard(title: "Pain Management", icon: "waveform.path.ecg")
                            EssentialCard(title: "Stretching Basics", icon: "figure.flexibility")
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
}
```
## BodyAreaCard component:

```swift
struct BodyAreaCard: View {
    let area: LearnBodyArea
    var body: some View {
        VStack(spacing: 8) {
            Image(area.imageName)           // use the anatomical illustration
                .resizable().scaledToFit()
                .frame(height: 70)
            Text(area.displayName)
                .font(.headline).foregroundColor(.blue)
            Text(area.subtitle)             // "ACL, Dislocation, Rehab tips."
                .font(.caption).foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6)
    }
}
```
## LearnBodyArea enum (mirrors your BodyArea but learn-specific):

```swift
enum LearnBodyArea: String, CaseIterable, Identifiable {
    case knee        = "Knee"
    case shoulder    = "Shoulder"
    case backAndCore = "Back & Core"
    case ankleAndFoot = "Ankle & Foot"
    case elbow       = "Elbow"
    case hip         = "Hip"

    var subtitle: String {
        switch self {
        case .knee:         return "ACL, Dislocation, Rehab tips."
        case .shoulder:     return "Rotator Cuff, Impingement."
        case .backAndCore:  return "Lower Pain, Posture, Strength."
        case .ankleAndFoot: return "Sprains, Stability, Mobility."
        case .elbow:        return "Tennis Elbow, Stiffness."
        case .hip:          return "Hip Flexor, Bursitis."
        }
    }
}
```
## Level 2: BodyAreaLearnView (tapped into "Knee")
This shows all the conditions for that body area as a scrollable list of cards:

```swift
struct BodyAreaLearnView: View {
    let area: LearnBodyArea

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Area hero banner
                AreaHeroBanner(area: area)
                // Large illustration + area name + 1-line summary

                // Conditions list
                SectionHeader(title: "Common Conditions")
                ForEach(area.conditions) { condition in
                    NavigationLink(destination: ConditionDetailView(condition: condition)) {
                        ConditionRowCard(condition: condition)
                    }
                }

                // Quick stats strip (e.g. "Avg recovery: 6–12 weeks")
                RecoveryStatsStrip(area: area)
            }
            .padding()
        }
        .navigationTitle(area.displayName)
        .navigationBarTitleDisplayMode(.large)
    }
}
```
## ConditionRowCard:

```swift
struct ConditionRowCard: View {
    let condition: LearnCondition
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: condition.systemIcon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(condition.name).font(.headline)
                Text(condition.shortDescription).font(.caption).foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}
```
##Level 3: ConditionDetailView (the actual knowledge page)
This is the richest screen — structured into collapsible sections so it doesn't overwhelm:

```swift
struct ConditionDetailView: View {
    let condition: LearnCondition
    @State private var expandedSection: DetailSection? = .overview

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // 1. Overview card
                DetailSectionCard(
                    section: .overview,
                    expanded: $expandedSection,
                    content: OverviewSectionView(condition: condition)
                )

                // 2. Recovery Timeline (visual phase strip)
                DetailSectionCard(
                    section: .timeline,
                    expanded: $expandedSection,
                    content: RecoveryTimelineView(phases: condition.recoveryPhases)
                )

                // 3. Therapy Techniques (horizontal card scroll)
                DetailSectionCard(
                    section: .techniques,
                    expanded: $expandedSection,
                    content: TechniqueCardsView(techniques: condition.techniques)
                )

                // 4. At-Home Rehab (links to AR exercise session)
                DetailSectionCard(
                    section: .atHomeRehab,
                    expanded: $expandedSection,
                    content: AtHomeRehabView(condition: condition)
                )

                // 5. When to See a Doctor
                DetailSectionCard(
                    section: .whenToSeeDoctor,
                    expanded: $expandedSection,
                    content: DoctorWarningsView(warnings: condition.redFlags)
                )
            }
            .padding()
        }
        .navigationTitle(condition.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
```
## Recovery Timeline Component
Visual horizontal strip showing phases — this is the most impactful UI piece:

```swift
struct RecoveryTimelineView: View {
    let phases: [RecoveryPhase]
    // Phase example for knee dislocation:
    // Phase 1: "Acute (0-2 wks)" — Rest, ice, compression
    // Phase 2: "Early Rehab (2-6 wks)" — ROM exercises, quad sets
    // Phase 3: "Strengthening (6-12 wks)" — Hip, glute work
    // Phase 4: "Return to Activity (3-6 mo)" — Balance, sport prep

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                    VStack(spacing: 6) {
                        Circle()
                            .fill(phase.isComplete ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                        Text(phase.title)
                            .font(.caption).bold()
                            .multilineTextAlignment(.center)
                            .frame(width: 80)
                        Text(phase.duration)
                            .font(.caption2).foregroundColor(.secondary)
                            .frame(width: 80)
                    }
                    if index < phases.count - 1 {
                        Rectangle()
                            .frame(width: 30, height: 2)
                            .foregroundColor(.blue.opacity(0.3))
                            .padding(.bottom, 30)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}
```
## At-Home Rehab Section (Bridge to AR)
This directly links the learn content to your existing exercise session:

```swift
struct AtHomeRehabView: View {
    let condition: LearnCondition

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("These exercises are available in your AR session tracker.")
                .font(.caption).foregroundColor(.secondary)

            ForEach(condition.recommendedExerciseNames, id: \.self) { exerciseName in
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.blue)
                    Text(exerciseName).font(.subheadline)
                    Spacer()
                    NavigationLink("Start →") {
                        // Route to your existing ARSessionView
                        // passing the matched Exercise object
                        ARExerciseLaunchView(exerciseName: exerciseName)
                    }
                    .font(.subheadline).foregroundColor(.blue)
                }
                .padding(.vertical, 4)
                Divider()
            }
        }
    }
}
```
## Data Model for Learn Content
```swift
struct LearnCondition: Identifiable {
    let id: UUID
    let name: String
    let shortDescription: String
    let systemIcon: String
    let overview: String                        // 2-3 paragraph text
    let recoveryPhases: [RecoveryPhase]
    let techniques: [TherapyTechnique]
    let recommendedExerciseNames: [String]      // matches Exercise.name exactly
    let redFlags: [String]                      // "See a doctor if..."
}

struct RecoveryPhase: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
    let description: String
    var isComplete: Bool = false
}

struct TherapyTechnique: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    // e.g. "RICE Method", "Cold Therapy", "TENS", "Compression Taping"
}
```
Complete Tab Bar Implementation
```swift
@main
struct RehabApp: App {
    @State private var selectedTab: AppTab = .home

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { Label("Home", systemImage: "house.fill") }
                    .tag(AppTab.home)

                ScheduleView()
                    .tabItem { Label("Schedule", systemImage: "calendar") }
                    .tag(AppTab.schedule)

                LearnHomeView()
                    .tabItem { Label("Learn", systemImage: "book.fill") }
                    .tag(AppTab.learn)

                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.fill") }
                    .tag(AppTab.profile)
            }
            .accentColor(.blue)
        }
    }
}
```
Full Screen Flow Summary
```text
TabBar
├── Home          → BodyArea picker → Condition picker → AR Session
├── Schedule      → Upcoming sessions, history
├── Learn ←       → LearnHomeView
│     ├── Knee    → BodyAreaLearnView
│     │     ├── ACL Tear         → ConditionDetailView
│     │     ├── Knee Dislocation → ConditionDetailView
│     │     │     ├── Overview
│     │     │     ├── Recovery Timeline (4 phases)
│     │     │     ├── Techniques (RICE, TENS, etc.)
│     │     │     ├── At-Home Rehab ──→ AR Session (deep link)
│     │     │     └── When to See Doctor
│     │     └── General Knee Pain → ...
│     ├── Shoulder → ...
│     └── Recovery Essentials → Sleep, Hydration, Pain Mgmt
└── Profile       → Progress, streaks, settings
```
The key architectural win is recommendedExerciseNames: [String] on LearnCondition — it directly matches Exercise.name strings so the "Start →" button in the Learn tab deep-links straight into your existing AR session flow with zero duplication.