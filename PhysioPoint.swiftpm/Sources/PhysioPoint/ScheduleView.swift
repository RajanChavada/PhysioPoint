import SwiftUI

// MARK: - ScheduleView

struct ScheduleView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService

    // Setup mode state
    @State private var hours: [Int] = [8, 13, 18]
    @State private var slots: [PlanSlot] = []
    @State private var saved = false
    
    // UI Expand state
    @State private var expandedPlans: [UUID: Bool] = [:]

    private var isSettingUpNewPlan: Bool {
        if let cond = appState.selectedCondition {
            // Only considered setup if they don't have a plan for it yet
            return storage.plan(for: cond.id) == nil
        }
        return false
    }

    private var hasSavedPlans: Bool {
        !storage.dailyPlans.isEmpty
    }

    var body: some View {
        ZStack {
            PPGradient.pageBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                if hasSavedPlans && !isSettingUpNewPlan { consolidatedProgressBar.padding(.bottom, 12) }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if isSettingUpNewPlan { 
                            setupCards 
                        } else if hasSavedPlans { 
                            savedPlanCards 
                        } else {
                            noPlansView
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }

                if isSettingUpNewPlan { 
                    saveButton 
                } else if hasSavedPlans { 
                    allDoneBanner 
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear { 
            buildSlots() 
            initializeExpandedState()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // ONLY show back button if we arrived via NavigationStack from Home
            if !appState.navigationPath.isEmpty {
                Button {
                    appState.navigationPath.removeLast()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Home")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(PPColor.actionBlue)
                }
                .padding(.bottom, 8)
                .buttonStyle(.plain)
            }

            VStack(spacing: 6) {
            if isSettingUpNewPlan {
                if let cond = appState.selectedCondition {
                    let area = BodyArea(rawValue: cond.bodyArea.rawValue) ?? .knee
                    Text(cond.bodyArea.rawValue.capitalized)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(area.tintColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(area.tintColor.opacity(0.10))
                        .cornerRadius(8)
                }
                Text("Set Your Daily Schedule")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Choose times and review planned exercises.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("Today's Schedule")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Tap a time to adjust, or start a session.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                if storage.completedSlotCount == storage.totalSlotCount && storage.totalSlotCount > 0 {
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
        ForEach(storage.dailyPlans) { plan in
            let area = BodyArea(rawValue: plan.bodyArea) ?? .knee
            DisclosureGroup(
                isExpanded: Binding(
                    get: { expandedPlans[plan.id] ?? false },
                    set: { expandedPlans[plan.id] = $0 }
                )
            ) {
                VStack(spacing: 12) {
                    ForEach(plan.slots.indices, id: \.self) { i in
                        savedSlotCardContent(slot: plan.slots[i], index: i, plan: plan)
                    }
                }
                .padding(.top, 10)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(area.tintColor.opacity(0.12))
                            .frame(width: 40, height: 40)
                        Image(systemName: area.systemImage)
                            .foregroundColor(area.tintColor)
                            .font(.system(size: 20))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.conditionName)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.primary)
                        Text("\(plan.slots.filter(\.isCompleted).count) / \(plan.slots.count) Sessions Done")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                    Button {
                        withAnimation(.spring(duration: 0.35)) {
                            storage.deletePlan(plan)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture())
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(PPColor.actionBlue.opacity(0.1), lineWidth: 1)
            )
            .tint(area.tintColor)
            .contextMenu {
                Button(role: .destructive) {
                    storage.deletePlan(plan)
                } label: {
                    Label("Delete Plan", systemImage: "trash")
                }
            }
        }
    }

    private func savedSlotCardContent(slot: PlanSlot, index i: Int, plan: DailyPlan) -> some View {
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
                    // Editable time picker
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
                Button { startSlot(slot, plan: plan) } label: {
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
                Button { startSlot(slot, plan: plan) } label: {
                    Text("Start")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(PPGradient.action))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(slot.isCompleted ? PPColor.vitalityTeal.opacity(0.04) : PPColor.glassBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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

    private func startSlot(_ slot: PlanSlot, plan: DailyPlan) {
        if slot.isCompleted { storage.unmarkSlotComplete(slot.id) }
        appState.activeSlotID = slot.id
        
        // Find matching Condition by plan.conditionID or fallback to plan.conditionName
        if let cond = Condition.library.first(where: { $0.id == plan.conditionID || $0.name == plan.conditionName }) {
            appState.selectedCondition = cond
            if let ex = cond.recommendedExercises.first(where: { $0.id == slot.exerciseID || $0.name == slot.exerciseName }) {
                appState.selectedExercise = ex
            } else {
                appState.selectedExercise = cond.recommendedExercises.first
            }
        }
        
        appState.selectedTab = .home
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.navigationPath.append("SessionIntro")
        }
    }

    private func resolveExerciseFromSlot(_ slot: PlanSlot) -> Exercise? {
        let allExercises: [Exercise] = Exercise.kneeExercises
            + Exercise.shoulderExercises
            + Exercise.hipExercises
            + Exercise.elbowExercises
            + Exercise.ankleExercises

        // Try ID match first, then exact name, then fuzzy name fallback
        return allExercises.first(where: { $0.id == slot.exerciseID })
            ?? allExercises.first(where: { $0.name == slot.exerciseName })
            ?? allExercises.first(where: { slot.exerciseName.contains($0.name) || $0.name.contains(slot.exerciseName) })
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
    
    // MARK: - No Plans View
    
    private var noPlansView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(PPColor.actionBlue.opacity(0.5))
            Text("No active rehab plans")
                .font(.system(.title3, design: .rounded).bold())
            Text("Go to the Home tab and tap 'New Session' to complete Triage and create a daily schedule.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .padding(.top, 60)
        .transition(.opacity.animation(.easeInOut(duration: 0.3)))
    }

    // MARK: - Save & Status Bottom Banners

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
            if hasSavedPlans && storage.completedSlotCount == storage.totalSlotCount && storage.totalSlotCount > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill").foregroundColor(PPColor.vitalityTeal)
                    Text("All sessions done for today!").font(.system(size: 15, weight: .semibold)).foregroundColor(PPColor.vitalityTeal)
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
        // Setup only applies if they don't have a plan for THIS condition
        if storage.plan(for: condition.id) != nil { return }
        var plan = DailyPlan.make(for: condition)
        for i in plan.slots.indices { plan.slots[i].scheduledHour = hours[i] }
        slots = plan.slots
    }
    
    private func initializeExpandedState() {
        for plan in storage.dailyPlans {
            let hasIncomplete = plan.slots.contains(where: { !$0.isCompleted })
            expandedPlans[plan.id] = hasIncomplete
        }
    }

    private func saveSchedule() {
        guard let condition = appState.selectedCondition else { return }
        var plan = DailyPlan.make(for: condition)
        for i in plan.slots.indices { plan.slots[i].scheduledHour = hours[i] }
        storage.addPlan(plan)
        saved = true
        // Update expansion state for the newly added plan
        expandedPlans[plan.id] = true
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

