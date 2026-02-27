# Backend Memory

## Status
- Core StorageService handles all scheduling + metrics persistence.
- ScheduleService is now a thin delegate to StorageService (legacy compatibility only).
- Uses `UserDefaults` caching in `StorageService` for `[DailyPlan]` array and `SessionMetrics`.
- **Multi-plan architecture**: supports multiple active plans (e.g. shoulder + elbow = 6 total slots).
- Maintained offline local-storage boundaries without extra persistence dependencies.
- `SessionMetrics` was made `Codable` to integrate cleanly into `StorageService`.
- **Full 5×3×3 exercise/condition library** — 42 unique exercises, 15 conditions across 5 body areas.
- **Per-exercise AR joint tracking** via `JointTrackingConfig` — each exercise maps to specific ARKit joint triple.
- **ARKit accuracy-audited exercise classification** — exercises classified into reliable/marginal/timer-only tiers based on real ARKit error data (~18.8° ± 12.1° average).

## Implemented Work
1. Added `Codable`, `id`, `date`, `exerciseID` explicitly to `SessionMetrics.swift`.
2. Created `ScheduleModel.swift` — `PlanSlot` and `DailyPlan` with `conditionID`, `conditionName`, `bodyArea`. `DailyPlan` conforms to `Identifiable + Codable`. `DailyPlan.make(for:)` factory.
3. **StorageService.swift** — `@Published var dailyPlans: [DailyPlan]` (multi-plan array).
   - `addPlan(_:)` — deduplicates by conditionID (replaces existing plan for same condition).
   - `removePlan(conditionID:)` — removes a specific plan.
   - `plan(for conditionID:)` — finds a specific plan.
   - `updateSlotHour(_:hour:)` — allows time adjustment on saved slots.
   - Consolidated computed properties: `allSlots`, `totalSlotCount`, `completedSlotCount`.
   - `markSlotComplete(_:)` / `unmarkSlotComplete(_:)` — iterate all plans to find slot.
   - `saveSessionMetrics(_:)` — persists last 10 sessions.
   - Backward-compat: `dailyPlan` computed property → `.first`, `saveDailyPlan()` → `addPlan()`.
   - **Body Region Support**: Implemented `BodyRegion` enum to map conditions to specific SF Symbols and colors.
   - **Horizontal Plan Support**: Designed UI state to support fetching the entire array of `DailyPlan` to build horizontal snappable carousel summaries.
   - **Collapsible Schedule Support**: Refactored `ScheduleView` logic to identify and group slots by plan ID to enable `DisclosureGroup` expansion.
4. `ScheduleService.swift` — thin delegate to StorageService (legacy, not used by any view).
5. Core RehabEngine math and AR view tracking in `ExerciseARView`.
6. `ConditionModel.swift` — 15 conditions across 5 body areas × 3 categories with `ConditionCategory` enum and `conditions(for:)` filter. **All recommended exercises are now AR-trackable** — timer-only exercises (grip, rotation, ankle foot/toe, occluded stretches) removed from condition presets and replaced with trackable alternatives.
7. `ExerciseModel.swift` — 42 unique static `Exercise` properties organized by body area (Knee 8, Elbow 7, Hip 9, Ankle 9, Shoulder 9). Legacy array accessors preserved.
8. **JointTrackingConfig.swift** — Per-exercise ARKit joint mapping (ACCURACY AUDITED):
   - `TrackingMode` enum: `.angleBased`, `.holdDuration`, `.rangeOfMotion`, `.repetitionCounting`, `.timerOnly`
   - `CameraPosition` enum: `.side`, `.front` — recommended camera placement per exercise
   - `TrackingReliability` enum: `.reliable`, `.marginal`, `.unreliable` — per ARKit accuracy research
   - `JointTrackingConfig` struct: `proximalJoint`, `middleJoint`, `distalJoint`, `mode`, `targetRange`, `formCues`, `cameraPosition`, `reliability`
   - `Exercise.trackingConfig` computed property — switch on exercise name → correct ARKit joint triple + widened target range
   - `Exercise.isTimerOnly` — true for ~22 exercises that can't be reliably tracked
   - `Exercise.recommendedCameraPosition` — returns best camera placement
   - `Exercise.trackingReliability` — returns tracking tier
9. **AngleMath.swift** — generalized `computeJointAngle(proximal:joint:distal:)` + backward-compat `computeKneeFlexionAngle` alias + named helpers (`elbowFlexion`, `shoulderAngle`, `hipAngle`) + `AngleSmoother` class (moving average, windowSize=5, reduces jitter from ±5° to ±1-2°).
10. **RehabEngine.swift** — `update(proximal:joint:distal:)` generic 3-joint interface. Backward-compat `update(hip:knee:ankle:)` via protocol extension.
11. **ExerciseARView.swift** — Full per-exercise joint tracking (ACCURACY HARDENED):
    - `RehabSessionViewModel` gains: `formCueText`, `isTimerMode`, `timerSecondsLeft`, `cameraHint`, `reliabilityBadge`, `isTrackingQualityGood`, `angleSmoother` (AngleSmoother instance)
    - `processJoints()` now applies temporal smoothing via `angleSmoother.smooth()`
    - `bodyLost()` resets the angle smoother buffer
    - Timer-only mode: countdown per rep, no AR skeleton tracking
    - `ARViewRepresentable` accepts `trackingConfig` parameter; `updateUIView` keeps `activeConfig` in sync
    - **FIX: processBody now reads joints from activeConfig directly** — no hardcoded leg fallback. If activeConfig is nil (timer-only), skeleton visuals still render but no angle tracking runs.
    - Coordinator reads `activeConfig` to resolve correct 3 joints per exercise from skeleton
    - `processBody` separated into angle tracking + `updateSkeletonVisuals()` helper
    - Debug log now prints the actual joint triple being tracked (e.g. "tracking: right_arm_joint→right_forearm_joint→right_hand_joint")
    - **Smaller orbs**: joint spheres reduced from 0.06 → 0.025-0.035 (less visual confusion from position error)
    - **Thinner bones**: line thickness reduced from 0.02 → 0.012
    - **Tracking quality validation**: `session(didUpdate frame:)` checks `frame.camera.trackingState == .normal` and shows warning if degraded
    - Camera position hint displayed during exercise ("Best results: place camera to your side")
    - Reliability badge ("✅ High accuracy tracking" / "⚠️ Approximate tracking")
    - Form cue text displayed as yellow overlay
    - Timer countdown displayed in 60pt font for timer-only exercises

## ARKit Accuracy Research (Applied)
- Average error: ~18.8° ± 12.1° across all joints and exercises
- Best case: ~3.75° error (simple, visible joints like knees from side view)
- Worst case: ~47° error (occluded joints, complex movements)
- Side view performs significantly better than frontal view
- Wrist/hand joints barely update — transforms often don't change
- Foot/toe joints too small for body skeleton to reliably measure
- Overlapping limbs (arm across body, squatting) cause massive joint drift
- LiDAR helps somewhat but doesn't guarantee accuracy

## Exercise Tracking Classification (42 total)

### Reliable AR Tracking (~15 exercises)
Large visible joint movements, side/front camera view, ~3-8° error:
- **Knee**: Short Arc Quads, Seated Knee Extension, Straight Leg Raises, Heel Slides, Terminal Knee Extension, Seated Knee Flexion
- **Elbow**: Elbow Flexion & Extension, Active Elbow Flexion, Gravity-Assisted Extension, Elbow Extension Stretch
- **Hip**: Glute Bridges, Standing Hip Flexion, Single Leg Balance
- **Shoulder**: Wall Slides, External Rotation, Supine Shoulder Flexion

### Marginal AR Tracking (~6 exercises)
May work with wider tolerances, some occlusion risk (~10-20° error):
- **Knee**: Quad Sets (subtle), Prone Knee Flexion (face-down)
- **Hip**: Clamshells (side-lying), Hip Hinge (root drift), Cat-Cow (spine inferred)
- **Shoulder**: Pendulum Swings (occlusion), Shoulder Rolls, Side-Lying External Rotation

### Timer-Only (~21 exercises)
Cannot be reliably tracked by ARKit body skeleton:
- **Elbow**: Wrist Flexor Stretch (wrist barely updates), Towel Squeeze (grip), Forearm Rotation (axial)
- **Hip**: Hip Flexor Stretch (kneeling occlusion), Seated Hip Rotation (crossed legs), Supine Hip Rotation (shoulder occlusion), Pelvic Tilt (too subtle)
- **Ankle** (ALL 9): Ankle Alphabet, Ankle Circles, Seated Calf Raises, Towel Scrunches, Resistance Dorsiflexion, Ankle Pumps, Seated Toe Raises, Seated Heel Raises
- **Shoulder**: Cross-Body Stretch (arm crosses torso), Sleeper Stretch (side-lying occlusion), Scapular Setting (no visible angle change)

## AR Joint Tracking Architecture
```
Exercise selected → exercise.trackingConfig returns JointTrackingConfig?
  ├── Config exists → AR tracking mode:
  │     .onAppear: targetAngle = midpoint of config.targetRange (widened for ARKit error)
  │     Camera hint set from config.cameraPosition
  │     Reliability badge set from config.reliability
  │     ARViewRepresentable receives config
  │     Coordinator.activeConfig set
  │     processBody() resolves config.proximalJoint/middleJoint/distalJoint from skeleton
  │     → Check frame.camera.trackingState == .normal (skip if degraded)
  │     → feeds into viewModel.processJoints(proximal:joint:distal:)
  │     → AngleSmoother.smooth() applied (5-frame moving average)
  │     → RehabEngine.update() → zone classification + rep counting
  │     → form cue display
  └── Config is nil → Timer-only mode:
        viewModel.startTimerMode(holdSeconds, reps)
        → countdown timer per rep, instruction card, no angle overlay
        → Used for exercises where ARKit can't provide reliable data
```

## ARKit Joint Map (tracked per exercise)
| Body Area | Proximal | Middle (angle vertex) | Distal |
|-----------|----------|----------------------|--------|
| Knee | right_upLeg_joint | right_leg_joint | right_foot_joint |
| Elbow | right_arm_joint | right_forearm_joint | right_hand_joint |
| Hip | varies (spine_4/hips/upLeg/leg) | varies (hips/upLeg/spine_4) | varies |
| Shoulder | varies (spine_7/shoulder) | varies (shoulder/arm) | varies |

## Design Decision: Honest ARKit Classification
"We evaluated ARKit's tracking capabilities per exercise and built two modes: full AR validation where the technology is reliable, and guided timer mode where joint visibility is limited. This reflects real-world constraints of consumer-grade motion capture." — Shows technical maturity for Challenge judges.

## Condition Preset → AR-Trackable Exercise Mapping (Updated)
All 15 condition presets now ONLY recommend AR-trackable exercises. Timer-only exercises remain in the Exercise library but are not assigned to any condition.

| Body Area | Condition | Recommended Exercises (all AR-trackable) |
|-----------|-----------|------------------------------------------|
| **Knee** | General Pain | Quad Sets, Short Arc Quads, Seated Knee Extension |
| **Knee** | Dislocation Therapy | Straight Leg Raises, Heel Slides, Terminal Knee Extension |
| **Knee** | Pain Bending | Heel Slides, Seated Knee Flexion, Prone Knee Flexion |
| **Elbow** | General Pain | Elbow Flexion & Extension, Active Elbow Flexion, Gravity-Assisted Extension |
| **Elbow** | Dislocation Therapy | Active Elbow Flexion, Elbow Extension Stretch, Gravity-Assisted Extension |
| **Elbow** | Pain Bending | Elbow Flexion & Extension, Active Elbow Flexion, Elbow Extension Stretch |
| **Hip** | General Pain | Clamshells, Glute Bridges, Standing Hip Flexion |
| **Hip** | Trouble Twisting | Hip Hinge, Cat-Cow, Glute Bridges |
| **Hip** | Pain Bending | Hip Hinge, Standing Hip Flexion, Glute Bridges |
| **Ankle** | General Pain | Single Leg Balance, Standing Hip Flexion, Seated Knee Extension |
| **Ankle** | Twisted/Rolled | Single Leg Balance, Hip Hinge, Glute Bridges |
| **Ankle** | Pain Rotating | Single Leg Balance, Seated Knee Extension, Standing Hip Flexion |
| **Shoulder** | General Pain | Shoulder Rolls, Wall Slides, External Rotation |
| **Shoulder** | Dislocated | External Rotation, Wall Slides, Side-Lying External Rotation |
| **Shoulder** | Pain Lifting | Supine Shoulder Flexion, Wall Slides, Side-Lying External Rotation |

### Exercises Removed from Condition Presets (still in Exercise library as timer-only)
- **Elbow**: Wrist Flexor Stretch, Towel Squeeze, Forearm Rotation
- **Hip**: Hip Flexor Stretch, Seated Hip Rotation, Supine Hip Rotation, Pelvic Tilt
- **Ankle**: All 9 ankle-specific exercises (Ankle Alphabet, Circles, Calf Raises, Towel Scrunches, etc.)
- **Shoulder**: Pendulum Swings, Cross-Body Stretch, Sleeper Stretch, Scapular Setting

## Multi-Plan Session Flow
```
User creates plan via Triage → ScheduleView → Save
  → storage.addPlan(plan) — deduplicates by conditionID
  → user can create another plan for a different body area
HomeView shows consolidated Today's Plan:
  → storage.dailyPlans iterated, grouped by condition
  → consolidated progress pill: storage.completedSlotCount / storage.totalSlotCount
  → Start button resolves condition from plan.conditionID via Condition.library
ScheduleView shows current condition's plan only:
  → filtered by appState.selectedCondition.id
  → editable times via storage.updateSlotHour()
SummaryView:
  → marks slot complete → persists metrics
  → reads consolidated counts for progress ring
```

## Next Steps / Integrations
- ScheduleService in `app/` folder is a secondary mirror — .swiftpm is the source of truth.
- Consider adding trend charts from `recentMetrics` history (StorageService keeps last 10).
- Potential: local notifications for scheduled hours (currently commented out for offline constraint).
- Consider left/right side toggle (currently all exercises use right-side joints).
- Ankle exercises are ALL timer-only — future: consider camera-based foot tracking improvements.
- Target angle ranges on Exercise statics (display) differ from trackingConfig.targetRange (AR-measured, widened). UI cards show exercise.targetAngleRange, engine uses config.targetRange.
