
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

