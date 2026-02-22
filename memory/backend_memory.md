# Backend Memory

## Status
- Core StorageService handles all scheduling + metrics persistence.
- ScheduleService is now a thin delegate to StorageService (legacy compatibility only).
- Uses `UserDefaults` caching in `StorageService` for `[DailyPlan]` array and `SessionMetrics`.
- **Multi-plan architecture**: supports multiple active plans (e.g. shoulder + elbow = 6 total slots).
- Maintained offline local-storage boundaries without extra persistence dependencies.
- `SessionMetrics` was made `Codable` to integrate cleanly into `StorageService`.

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
4. `ScheduleService.swift` — thin delegate to StorageService (legacy, not used by any view).
5. Core RehabEngine math and AR view tracking in `ExerciseARView`.
6. `ConditionModel.swift` — 6 conditions across 5 body areas with `conditions(for:)` filter.

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
