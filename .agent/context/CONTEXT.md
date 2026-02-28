# PhysioPoint – Project Context

Last updated: 2026‑02‑20  
Owner: Rajan (CS student, Toronto, Western University)

---

## 1. Swift Student Challenge Constraints

This project must comply with Apple’s **Swift Student Challenge 2026** rules.[web:13][web:14][web:159]

Hard constraints:

- Deliverable is an **“app playground”** (`.swiftpm`), zipped under **25 MB** total.[web:13]
- Must run **offline**:  
  - No network calls, no remote APIs, no cloud models.  
  - All logic, data, and assets must be local in the app bundle.[web:14]
- Must be built with **Swift** and **SwiftUI** as an **App Playground** template that runs in:
  - **Swift Playgrounds** (on Mac and/or iPad), or  
  - **Xcode** (not used here, but we follow its expectations).[web:14]
- Experience should be fully understandable in **~3 minutes** of interaction for a judge.
- Single‑developer work: all code + assets must be created or properly licensed by me.
- Content must be appropriate for all audiences (no gore, no explicit medical imagery, etc.).

Platform assumptions:

- Primary dev environment: **Swift Playgrounds on MacBook** (no full Xcode).  
- App must compile and run in **Swift Playgrounds 4+** with SwiftUI.

---

## 2. Timeline

- Today: **2026‑02‑20**.  
- Swift Student Challenge 2026 submissions are **currently open**, deadline is in a few days (late February).[web:159]
- This means:
  - Architecture must be **simple and shippable in ~7–9 days**.
  - Prefer **one polished path** through the app (knee rehab) vs. many half‑finished branches.

Agents must prioritize:

1. A clean, working 3‑minute demo path.
2. Minimal but clear code.
3. Avoid over‑engineering or adding new features not in this context.

---

## 3. Product Story and Background

### 3.1 Real‑world story

- My **brother‑in‑law** dislocated his knee.
  - He had to attend rehab sessions at ~$100 each.
  - He received exercises to repeat several times a day at home.
  - He needed **reminders and feedback** to know if he was doing them correctly.
- My **mother‑in‑law** has chronic “bad legs” from age.
  - Insurance coverage for physio is limited.
  - She relies on **YouTube videos** for home exercises.
  - She is **not very tech‑savvy**, sometimes can’t follow the videos, and often **forgets** to do exercises 2–3 times a day.

PhysioPoint is inspired by them: a tool that makes home rehab **simpler, more consistent, and more visual**, without pretending to be a doctor.

### 3.2 Problem statement

There is a gap between:

- **Clinic instructions** (which are correct but expensive and time‑limited), and
- **Home reality** (people with limited money, tech familiarity, and memory relying on generic videos).

We want to:

- Help users **understand** their rehab exercises.
- Encourage them to **do them consistently**.
- Give them simple **visual feedback** on whether their movements are roughly correct.

We do **not**:

- Diagnose conditions.
- Replace professional medical advice.
- Guarantee clinical outcomes.

Always include or preserve the disclaimer:

> “This app is for informational and educational purposes only.  
> For medical advice, diagnosis, or treatment, consult a healthcare professional.”

---

## 4. Core Features (Scope for Swift Student Challenge)

Focus is on **one body part and a small set of exercises** for the 3‑minute demo: **knee rehab** (e.g., post‑dislocation or general weakness).

### 4.1 Triage: Pick area and issue

- Simple, offline triage to configure the session:
  - User selects **body area** (for demo: focus on **Knee**).
  - Then selects the **type of difficulty**:
    - “Hard to straighten fully” (extension lag).
    - “Hard to bend past 90°” (limited flexion).
    - “General weakness / pain when standing.”
- Based on the selection, we map to **predefined exercise protocols**.

Implementation notes:

- Use a small, hard‑coded **Condition Library** model (`ConditionModel.swift`).
- No real diagnosis – just mapping “what you feel” → “which exercise library to show”.

### 4.2 Exercise Library (offline database)

For each **condition**, we have a small set of **clinically common** home exercises, e.g.:

- **For knee flexion (limited bend)**:
  - Heel Slides – goal: gradually reach ~90° flexion.
- **For extension lag (can’t straighten)**:
  - Quad Sets
  - Straight Leg Raises

Each exercise record might include:

- `id`, `name`
- `phase` (early / loading / functional)
- `targetAngleRange` (e.g., 80–95°)
- `holdSeconds` (e.g., 10s)
- `reps` and `sets` (e.g., 3 reps for demo)
- `visualDescription` (e.g., short text + ASCII diagram)

All of this is **local**, either:

- A small Swift array literal, or
- A tiny bundled JSON in `Resources/` (under 1–2 KB).

### 4.3 Schedule and reminders (conceptual for playground)

Real goal:

- Let users plan **“3× a day every X hours”** routines.
- Offer gentle reminders so they don’t forget.

Swift Student Challenge demo:

- Show a **“Today’s Plan”** card:
  - Morning – 3× Heel Slides  
  - Afternoon – 3× Heel Slides  
  - Evening – 3× Heel Slides
- Allow the user to **tap “Start Now”** to jump into a live session.
- Optionally, show text describing how real reminders would work (local notifications / AlarmKit), but do **not** require them during the 3‑minute demo.

We want the concept of “daily adherence” without implementing full scheduling, which may not be necessary (and may not be fully supported) in a Playgrounds app.

### 4.4 AR‑Guided Session

This is the **hero feature**:

1. User chooses the exercise (e.g., Heel Slide).
2. User sees a simple **instruction screen**:  
   - Short description.  
   - Minimal diagram (or SF Symbol + text).
3. User taps **“Start Session”** and enters an AR camera view.
4. App uses **markerless motion capture** to:
   - Track hip, knee, ankle joints (if device supports `ARBodyTrackingConfiguration`).
   - Compute current knee flexion angle.
5. Visual feedback only (no vibration, no sound):
   - Show a small **angle arc** label (e.g., “76°”).
   - Color code the indicator:
     - Orange – below target range.
     - Green – within target range.
     - Red – beyond demonstration “safe” window.
   - When the angle hits target and hold time is met, show a **Liquid‑Glass‑style glow** around the joint/arc, or a tastefully animated “Hold complete” badge.

**Important:** We must gracefully degrade if AR body tracking is not available in a given environment (e.g., fallback to a simple slider demo for the Challenge).

### 4.5 Session Summary and Progress

After a short session (e.g., 3 successful reps):

- Show summary metrics:
  - Best angle achieved this session.
  - Reps completed.
  - A simple “progress ring” toward a **daily goal**.
- Remind user of the disclaimer and that only their clinician can change their plan.

For the Challenge, we don’t need long‑term persistence; storing a single session’s metrics in memory is enough to show the idea.

---

## 5. Technical Constraints and Preferences

### 5.1 Environment

- Dev: **VS Code** + **Swift Playgrounds on Mac**.
- Runtime: **Swift Playgrounds app** on macOS (and ideally iPadOS too).
- We will mirror `app/Sources/PhysioPoint/` into the `.swiftpm` package for submission.

### 5.2 Frameworks allowed and preferred

Core frameworks (must be supported in Swift Playgrounds):

- **SwiftUI** – all UI, navigation, overlays, animations.
- **Combine / ObservableObject** – simple state management.
- **UserDefaults** (or **SwiftData** only if clearly supported in Playgrounds) – optional for local state.
- **ARKit** + **RealityKit** – for body tracking and 3D overlays (if supported on target device).[web:148][web:150]
- **CoreGraphics / simd** – for vector math to compute joint angles.

We **avoid**:

- Network frameworks (`URLSession`, `WebSocket`, etc.).
- Heavy ML frameworks that require large models (`Core ML` with big `.mlmodel` files).
- Large media assets (videos, big images, 3D models > a few MB).

### 5.3 Architecture preferences

- **Layered SwiftUI**:
  - `Views/` – SwiftUI views only (no business logic except trivial state).
  - `models/` – plain Swift structs for Conditions, Exercises, Metrics.
  - `services/` – classes/structs handling rehab math, scheduling logic, basic persistence.
  - `utils/` – stateless helper functions (e.g., angle calculations).

- **State management**:
  - Use `ObservableObject` + `@StateObject` / `@ObservedObject` for app‑wide state (current condition, selected exercise, live angle).
  - Use `@State` for local UI toggles.

- **Formatting & style**:
  - 4‑space indentation.
  - `lowerCamelCase` for variables and functions, `UpperCamelCase` for types.
  - Each type in its own file where sensible.
  - No extremely long functions (> 80–100 lines); break into private helpers.

---

## 6. Safety, Ethics, and Non‑Goals

- This is **not** a medical device.
- This app:
  - Does not provide diagnosis or treatment plans.
  - Does not adapt the rehab program based on performance.
  - Only visualizes **approximate movement quality** for **educational purposes**.

Agents must:

- Preserve or improve the prominent **medical disclaimer** in the UI.
- Avoid adding any language that suggests guaranteed recovery or medical outcomes.
- Keep all numeric thresholds (angles, reps, times) clearly framed as **examples**, not prescriptions.

---

## 7. Agent Instructions

When editing or generating code:

1. **Stay within scope.**
   - Don’t add unrelated features (chat, social feed, etc.).
   - Focus on one main exercise flow for the knee.

2. **Obey constraints.**
   - No network calls.
   - No large assets.
   - Keep code compatible with Swift Playgrounds & SwiftUI.

3. **Maintain structure.**
   - Place new models in `models/`.
   - Place reusable logic in `services/` or `utils/`.
   - Keep UI logic in the `Views` files.

4. **Be explicit about AR dependencies.**
   - Check for support before starting body tracking.
   - If not available, fall back to a non‑AR demo mode.

5. **Comment clearly where behavior is “for demo only.”**
   - Especially any hard‑coded angles, thresholds, or sample plans.

This context is the single source of truth for PhysioPoint. Any agent modifications must remain consistent with these requirements and story.


## Core Tree structure - TO BE CHANGED AND MODIFIED 
PhysioPoint/
├─ README.md
├─ LICENSE
├─ .gitignore
├─ .vscode/
│  ├─ settings.json          # Swift formatting, tab size, etc.
│  └─ extensions.json        # Swift, CodeLLDB, etc.
│
├─ context/
│  ├─ CONTEXT.md   # MAIN: full project context for agents
│  ├─ swift_challenge_requirements.md  # Parsed constraints from Apple
│  ├─ apple_apis.md          # Notes on SwiftUI, ARKit, RealityKit, notifications
│  ├─ user_story.md          # Your family story + narrative beats
│  └─ agent_guidelines.md    # How agents should edit Swift, structure, style
│
├─ app/                      # This mirrors what goes into .swiftpm Sources
│  ├─ Package.stub           # (optional) notes on SwiftPM, not built
│  └─ Sources/
│     └─ PhysioPoint/   
│        ├─ PhysioPointApp.swift      # @main App
│        ├─ ContentView.swift       # mode selection / entry
│        ├─ TriageView.swift        # pick body area + issue
│        ├─ ScheduleView.swift      # simple “3x a day” planner
│        ├─ SessionIntroView.swift  # explains the chosen exercise
│        ├─ ExerciseARView.swift    # AR tracking UI (or stub if AR not available)
│        ├─ SummaryView.swift       # metrics + progress + disclaimer
│        ├─ models/
│        │   ├─ ConditionModel.swift   # dislocated knee, etc.
│        │   ├─ ExerciseModel.swift    # name, hold time, reps
│        │   └─ SessionMetrics.swift   # best angle, reps done
│        ├─ services/
│        │   ├─ ScheduleService.swift  # in‑memory schedule; comments about real reminders
│        │   ├─ RehabEngine.swift      # pure Swift angle calculation, rep detection
│        │   └─ StorageService.swift   # UserDefaults or light SwiftData (if used)
│        └─ utils/
│            └─ AngleMath.swift        # vector math helpers, unit‑tested
│
├─ research/
│  ├─ notes_medical_disclaimer.md  # “informational only” language
│  ├─ rehab_protocols.md           # VERY high‑level milestones (non‑prescriptive)
│  └─ references.md                # links to AR physio papers / apps[web:150][web:153]
│
└─ tests/                          # Optional: logic tests for pure Swift bits
   └─ RehabEngineTests.swift       # Fuzz tests for angle thresholds, rep logic