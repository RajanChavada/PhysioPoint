import SwiftUI

// MARK: - ScheduleView

struct ScheduleView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService

    // Setup mode state
    @State private var hours: [Int] = [8, 13, 18]
    @State private var slots: [PlanSlot] = []
    @State private var saved = false

    private var existingPlan: DailyPlan? {
        guard let cond = appState.selectedCondition else { return nil }
        return storage.plan(for: cond.id)
    }

    private var hasSavedPlan: Bool { existingPlan != nil }

    var body: some View {
        ZStack {
            PPGradient.pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                if hasSavedPlan { consolidatedProgressBar.padding(.bottom, 12) }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if hasSavedPlan { savedPlanCards } else { setupCards }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }

                if hasSavedPlan { allDoneBanner } else { saveButton }
            }
        }
        .navigationBarHidden(true)
        .onAppear { buildSlots() }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 6) {
            if let cond = appState.selectedCondition {
                Text(cond.bodyArea.rawValue.capitalized)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(PPColor.actionBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(PPColor.actionBlue.opacity(0.10))
                    .cornerRadius(8)
            }
            Text(hasSavedPlan ? "Today's Schedule" : "Set Your Daily Schedule")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(hasSavedPlan ? "Tap a time to adjust, or start a session." : "Choose times and review planned exercises.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
        .padding(.bottom, 20)
        .padding(.horizontal, 24)
    }

    // MARK: - Consolidated Progress (all plans)

    private var consolidatedProgressBar: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(PPColor.actionBlue.opacity(0.12), lineWidth: 6)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: storage.totalSlotCount > 0 ? CGFloat(storage.completedSlotCount) / CGFloat(storage.totalSlotCount) : 0)
                    .stroke(PPColor.vitalityTeal, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                Text("\(storage.completedSlotCount)/\(storage.totalSlotCount)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Overall Progress")
                    .font(.system(size: 14, weight: .semibold))
                if storage.dailyPlans.count > 1 {
                    Text("\(storage.dailyPlans.count) active plans")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                if storage.completedSlotCount == storage.totalSlotCount {
                    Text("All sessions complete! 🎉")
                        .font(.system(size: 12))
                        .foregroundColor(PPColor.vitalityTeal)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Saved Plan Slots (with editable times)

    private var savedPlanCards: some View {
        Group {
            if let plan = existingPlan {
                ForEach(plan.slots.indices, id: \.self) { i in
                    savedSlotCardContent(slot: plan.slots[i], index: i)
                }
            }
        }
    }

    private func savedSlotCardContent(slot: PlanSlot, index i: Int) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(slotColor(i).opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: slotIcon(i))
                    .font(.system(size: 18))
                    .foregroundColor(slotColor(i))
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(slot.label)
                        .font(.system(size: 16, weight: .semibold))
                    // Editable time picker (even in saved mode)
                    savedTimePicker(slot: slot)
                }
                HStack(spacing: 6) {
                    Text(slot.exerciseName)
                        .font(.system(size: 13))
                        .foregroundColor(PPColor.recoveryIndigo)
                    // Tracking mode badge
                    if let ex = resolveExerciseFromSlot(slot) {
                        if ex.trackingConfig != nil {
                            Text("AR")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.12))
                                .cornerRadius(4)
                        } else {
                            Text("TIMER")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.12))
                                .cornerRadius(4)
                        }
                    }
                }
                if slot.isCompleted {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(PPColor.vitalityTeal)
                        Text("Completed")
                            .font(.system(size: 11))
                            .foregroundColor(PPColor.vitalityTeal)
                    }
                }
            }

            Spacer()

            if slot.isCompleted {
                Button { startSlot(slot) } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Redo")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(PPColor.actionBlue)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(PPColor.actionBlue.opacity(0.10)))
                }
            } else {
                Button { startSlot(slot) } label: {
                    Text("Start")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(PPGradient.action))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(slot.isCompleted ? PPColor.vitalityTeal.opacity(0.06) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(slot.isCompleted ? PPColor.vitalityTeal.opacity(0.25) : Color.clear, lineWidth: 1)
        )
    }

    private func savedTimePicker(slot: PlanSlot) -> some View {
        Menu {
            ForEach(Array(stride(from: 6, through: 22, by: 1)), id: \.self) { h in
                Button(formattedHour(h)) {
                    storage.updateSlotHour(slot.id, hour: h)
                }
            }
        } label: {
            Text(formattedHour(slot.scheduledHour))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(PPColor.actionBlue)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(PPColor.actionBlue.opacity(0.10)))
        }
    }

    private func startSlot(_ slot: PlanSlot) {
        if slot.isCompleted { storage.unmarkSlotComplete(slot.id) }
        appState.activeSlotID = slot.id
        if let condition = appState.selectedCondition {
            if let ex = condition.recommendedExercises.first(where: { $0.id == slot.exerciseID }) {
                appState.selectedExercise = ex
            } else {
                appState.selectedExercise = condition.recommendedExercises.first
            }
        }
        // Switch to Home tab and navigate there (avoid nav stack conflicts between tabs)
        appState.selectedTab = .home
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.navigationPath.append("SessionIntro")
        }
    }

    private func resolveExerciseFromSlot(_ slot: PlanSlot) -> Exercise? {
        let allExercises: [Exercise] = Exercise.kneeExercises
            + Exercise.elbowExercises + Exercise.shoulderExercises
            + Exercise.hipExercises
        return allExercises.first(where: { $0.id == slot.exerciseID })
            ?? allExercises.first(where: { $0.name == slot.exerciseName })
    }
    
    private func slotTrackingBadge(for slot: PlanSlot) -> some View {
        // All exercises are now AR-tracked
        Text("AR")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.green)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.15))
            .cornerRadius(4)
    }

    // MARK: - Setup Cards (initial creation)

    private var setupCards: some View {
        ForEach(slots.indices, id: \.self) { i in
            slotCard(index: i)
        }
    }

    private func slotCard(index i: Int) -> some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(slotColor(i).opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: slotIcon(i))
                            .font(.system(size: 16))
                            .foregroundColor(slotColor(i))
                    }
                    Text(slotLabel(i))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
                Spacer()
                timePicker(index: i)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            Divider().padding(.horizontal, 16)
            if i < slots.count { exerciseRow(slot: slots[i]) }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        )
    }

    private func timePicker(index i: Int) -> some View {
        Menu {
            ForEach(Array(stride(from: 6, through: 22, by: 1)), id: \.self) { h in
                Button(formattedHour(h)) { hours[i] = h }
            }
        } label: {
            Text(formattedHour(hours[i]))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(PPColor.actionBlue)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(PPColor.actionBlue.opacity(0.10)))
        }
    }

    private func exerciseRow(slot: PlanSlot) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(PPColor.recoveryIndigo.opacity(0.10))
                    .frame(width: 40, height: 40)
                Image(systemName: "figure.flexibility")
                    .font(.system(size: 18))
                    .foregroundColor(PPColor.recoveryIndigo)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(slot.exerciseName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(PPColor.recoveryIndigo)
                Text("Target: \(slot.exerciseSets) Sets • \(slot.exerciseReps) Reps")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button { saveSchedule() } label: {
            HStack(spacing: 8) {
                Image(systemName: saved ? "checkmark" : "calendar.badge.plus")
                Text(saved ? "Schedule Saved!" : "Save Schedule")
                    .fontWeight(.semibold)
            }
            .font(.title3)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Group { if saved { PPColor.vitalityTeal } else { PPGradient.action } })
            .cornerRadius(18)
            .shadow(color: PPColor.vitalityTeal.opacity(0.3), radius: 10, y: 4)
            .animation(.spring(response: 0.3), value: saved)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .padding(.top, 8)
        .background(Color.white.opacity(0.9).ignoresSafeArea(edges: .bottom))
    }

    private var allDoneBanner: some View {
        Group {
            if let plan = existingPlan, plan.slots.allSatisfy(\.isCompleted) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill").foregroundColor(PPColor.vitalityTeal)
                    Text("All sessions done for this plan!").font(.system(size: 15, weight: .semibold)).foregroundColor(PPColor.vitalityTeal)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(PPColor.vitalityTeal.opacity(0.10).ignoresSafeArea(edges: .bottom))
            }
        }
    }

    // MARK: - Logic

    private func buildSlots() {
        guard let condition = appState.selectedCondition else { return }
        if hasSavedPlan { return }
        var plan = DailyPlan.make(for: condition)
        for i in plan.slots.indices { plan.slots[i].scheduledHour = hours[i] }
        slots = plan.slots
    }

    private func saveSchedule() {
        guard let condition = appState.selectedCondition else { return }
        var plan = DailyPlan.make(for: condition)
        for i in plan.slots.indices { plan.slots[i].scheduledHour = hours[i] }
        storage.addPlan(plan)
        saved = true
    }

    // MARK: - Helpers

    private func slotLabel(_ i: Int) -> String { ["Morning", "Afternoon", "Evening"][i % 3] }
    private func slotIcon(_ i: Int) -> String { ["sunrise.fill", "sun.max.fill", "sunset.fill"][i % 3] }
    private func slotColor(_ i: Int) -> Color { [PPColor.vitalityTeal, PPColor.actionBlue, PPColor.recoveryIndigo][i % 3] }
    private func formattedHour(_ h: Int) -> String {
        let suffix = h < 12 ? "AM" : "PM"
        let display = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return "\(display):00 \(suffix)"
    }
}
