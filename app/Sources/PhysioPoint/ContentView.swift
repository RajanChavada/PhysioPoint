import SwiftUI

// MARK: - Root Router

struct ContentView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService
    @AppStorage("simulateAssistiveAccess") private var simulateAssistiveAccess = false

    var body: some View {
        Group {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(appState)
                    .environmentObject(storage)
            } else if simulateAssistiveAccess {
                AssistiveAccessRootView()
                    .environmentObject(appState)
                    .environmentObject(storage)
            } else {
                MainTabView()
                    .environmentObject(appState)
                    .environmentObject(storage)
            }
        }
        .environment(\.isAssistiveAccessActive, simulateAssistiveAccess)
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environmentObject(appState)
                .environmentObject(storage)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)

            ScheduleTabView()
                .environmentObject(appState)
                .environmentObject(storage)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Schedule")
                }
                .tag(1)

            LearnHomeView()
                .environmentObject(appState)
                .environmentObject(storage)
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Learn")
                }
                .tag(2)

            ProfileView()
                .environmentObject(appState)
                .environmentObject(storage)
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .tint(PPColor.actionBlue)
        .onChange(of: appState.selectedTab) { _, newTab in
            switch newTab {
            case .home:     selectedTab = 0
            case .schedule: selectedTab = 1
            case .learn:    selectedTab = 2
            case .profile:  selectedTab = 3
            }
        }
    }
}

// MARK: - Schedule Tab Wrapper

struct ScheduleTabView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            ScheduleView()
                .environmentObject(appState)
                .environmentObject(storage)
                .navigationDestination(for: String.self) { destination in
                    switch destination {
                    case "Triage":
                        TriageView()
                    case "Schedule":
                        ScheduleView()
                    case "SessionIntro":
                        SessionIntroView()
                    case "ExerciseAR":
                        ExerciseARView()
                    case "Summary":
                        SummaryView()
                    default:
                        EmptyView()
                    }
                }
        }
    }
}

// MARK: - Onboarding (3-page paginated Get Started)

struct OnboardingView: View {
    @EnvironmentObject var appState: PhysioPointState
    @State private var currentPage = 0

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        (
            "figure.run.circle.fill",
            "Welcome to\nPhysioPoint",
            "Simple, guided exercises to help you recover — step by step."
        ),
        (
            "arkit",
            "AR-Powered\nMotion Tracking",
            "Clinical-grade joint angle measurement using AR body tracking on your device — no expensive physio visits needed."
        ),
        (
            "heart.text.clipboard.fill",
            "Personalized\nRehab Plans",
            "Exercises tailored to your condition with real-time AR guidance and step-by-step instructions."
        ),
    ]

    var body: some View {
        ZStack {
            // Light white-blue background
            PPColor.glassBackground
                .ignoresSafeArea()

            // Soft radial glow at top
            PPGradient.heroGlow(center: .top)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageContent(
                            icon: pages[index].icon,
                            title: pages[index].title,
                            subtitle: pages[index].subtitle
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                Spacer()

                // Bottom section: dots + button
                VStack(spacing: 24) {
                    // Page dots
                    HStack(spacing: 10) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? PPColor.actionBlue : PPColor.actionBlue.opacity(0.2))
                                .frame(width: index == currentPage ? 28 : 8, height: 8)
                                .animation(.spring(response: 0.35), value: currentPage)
                        }
                    }

                    // CTA Button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            withAnimation(.spring(response: 0.4)) {
                                appState.hasCompletedOnboarding = true
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                        }
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(PPGradient.action)
                        .cornerRadius(20)
                        .shadow(color: PPColor.vitalityTeal.opacity(0.3), radius: 12, y: 6)
                    }
                    .padding(.horizontal, 32)

                    // Skip on first 2 pages
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation(.spring(response: 0.4)) {
                                appState.hasCompletedOnboarding = true
                            }
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    } else {
                        Color.clear.frame(height: 20)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Onboarding Page Content

private struct OnboardingPageContent: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 28) {
            // Icon with glass circle + subtle glow
            ZStack {
                Circle()
                    .fill(PPColor.vitalityTeal.opacity(0.10))
                    .frame(width: 160, height: 160)
                    .blur(radius: 30)

                Circle()
                    .fill(Color.white)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [PPColor.vitalityTeal, PPColor.actionBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                    )
                    .shadow(color: PPColor.actionBlue.opacity(0.15), radius: 20, y: 8)
            }

            VStack(spacing: 14) {
                Text(title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Home View (Post-Onboarding)

struct HomeView: View {
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var storage: StorageService
    @AppStorage("simulateAssistiveAccess") private var simulateAssistiveAccess = false

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            ZStack {
                // Light white-blue background
                PPGradient.pageBackground
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                BundledImage("PP_GRAD", maxHeight: 200)
                                    .frame(width: 200, height: 200)
                                
                                Text("Your recovery companion")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 8)
                            }
                            Spacer()
                        }
                        .padding(.top, 10)
                        
                        // Accessibility Quick Toggle Card
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $simulateAssistiveAccess.animation(.spring())) {
                                HStack(spacing: 12) {
                                    Image(systemName: "accessibility")
                                        .font(.title2)
                                        .foregroundColor(PPColor.actionBlue)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Accessibility Mode")
                                            .font(.headline)
                                        Text("Simplify the layout and enlarge buttons")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .tint(PPColor.actionBlue)
                        }
                        .padding(16)
                        .physioGlass(.card)

                        // Today's Plan slots (consolidated across all plans)
                        if !storage.dailyPlans.isEmpty {
                            todaysPlanSection
                        }

                        // Active plan cards
                        if !storage.dailyPlans.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Active Plans")
                                    .font(.headline)
                                    .padding(.leading, 4)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(storage.dailyPlans) { plan in
                                            activePlanCard(plan: plan)
                                                .frame(width: 280)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                    .padding(.bottom, 8)
                                }
                            }
                        }

                        // Start new session
                        startSessionCard
                        
                        // Helpful positive advice
                        InsightCarousel()

                        // Recovery pulse (shown after first completed session)
                        if storage.sessionCount > 0 || storage.lastFeeling != nil {
                            RecoveryPulseCard()
                                .environmentObject(storage)
                        }

                        // How it works
                        howItWorksSection

                        // Disclaimer
                        disclaimerBanner

                        Spacer(minLength: 30)
                    }
                    .padding(.horizontal, 20)
                }

                // AI Chat floating button
                ChatFABOverlay()
            }
            .navigationBarHidden(true)
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "Triage":
                    TriageView()
                case "Schedule":
                    ScheduleView()
                case "SessionIntro":
                    SessionIntroView()
                case "ExerciseAR":
                    ExerciseARView()
                case "Summary":
                    SummaryView()
                default:
                    EmptyView()
                }
            }
        }
    }

    // MARK: - Today's Plan Section (Consolidated Multi-Plan)

    private var todaysPlanSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with consolidated progress
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Plan")
                        .font(.headline)
                    Text(Date(), style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                todayProgressPill
            }

            // Scrollable list of slots grouped by plan
            ScrollView(showsIndicators: true) {
                VStack(spacing: 12) {
                    ForEach(storage.dailyPlans) { plan in
                        todayPlanGroup(plan: plan)
                    }

                    // All done banner
                    if storage.completedSlotCount == storage.totalSlotCount && storage.totalSlotCount > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundColor(PPColor.vitalityTeal)
                            Text("All sessions complete today!")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(PPColor.vitalityTeal)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(PPColor.vitalityTeal.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
                .padding(.trailing, 4) // Make room for scroll indicator
            }
            .frame(maxHeight: 280) // Constrain scroll height
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(PPColor.actionBlue.opacity(0.1), lineWidth: 1)
        )
    }

    private var todayProgressPill: some View {
        HStack(spacing: 6) {
            Text("\(storage.completedSlotCount)/\(storage.totalSlotCount)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(PPColor.vitalityTeal)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(PPColor.vitalityTeal)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(PPColor.vitalityTeal.opacity(0.10))
        .cornerRadius(12)
    }

    private func todayPlanGroup(plan: DailyPlan) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Condition header badge
            HStack(spacing: 6) {
                Text(plan.bodyArea.capitalized)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(PPColor.actionBlue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(PPColor.actionBlue.opacity(0.10))
                    .cornerRadius(6)
                Text(plan.conditionName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)

            ForEach(plan.slots.indices, id: \.self) { i in
                homeSlotRow(slot: plan.slots[i], index: i, plan: plan)
            }
        }
    }

    private func homeSlotRow(slot: PlanSlot, index i: Int, plan: DailyPlan) -> some View {
        HStack(spacing: 12) {
            // Status icon
            ZStack {
                Circle()
                    .fill(slot.isCompleted ? PPColor.vitalityTeal.opacity(0.15) : PPColor.actionBlue.opacity(0.10))
                    .frame(width: 36, height: 36)
                Image(systemName: slot.isCompleted ? "checkmark.circle.fill" : homeSlotIcon(i))
                    .font(.system(size: 16))
                    .foregroundColor(slot.isCompleted ? PPColor.vitalityTeal : PPColor.actionBlue)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(slot.label)
                        .font(.system(size: 14, weight: .semibold))
                    Text(homeFormattedHour(slot.scheduledHour))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    Text(slot.exerciseName)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    // Tracking badge
                    if let ex = resolveExercise(for: slot, in: plan) {
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
            }

            Spacer()

            if slot.isCompleted {
                Text("Done")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(PPColor.vitalityTeal)
            } else {
                Button {
                    appState.activeSlotID = slot.id
                    setConditionFromPlan(plan, slot: slot)
                    appState.navigationPath.append("SessionIntro")
                } label: {
                    Text("Start")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(PPGradient.action))
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func setConditionFromPlan(_ plan: DailyPlan, slot: PlanSlot? = nil) {
        // Find the matching condition and set it + exercise
        for cond in Condition.library {
            if cond.id == plan.conditionID || cond.name == plan.conditionName {
                appState.selectedCondition = cond
                if let slot = slot {
                    appState.selectedExercise = cond.recommendedExercises.first(where: { $0.id == slot.exerciseID || $0.name == slot.exerciseName }) ?? cond.recommendedExercises.first
                } else {
                    appState.selectedExercise = cond.recommendedExercises.first
                }
                return
            }
        }
    }

    private func resolveExercise(for slot: PlanSlot, in plan: DailyPlan) -> Exercise? {
        let allExercises: [Exercise] = Exercise.kneeExercises
            + Exercise.elbowExercises + Exercise.shoulderExercises
            + Exercise.hipExercises
        return allExercises.first(where: { $0.id == slot.exerciseID })
            ?? allExercises.first(where: { $0.name == slot.exerciseName })
    }
    
    private func trackingBadge(for slot: PlanSlot) -> some View {
        // All exercises are AR-tracked
        Text("AR")
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(.green)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Color.green.opacity(0.15))
            .cornerRadius(4)
    }

    private func homeSlotIcon(_ i: Int) -> String {
        ["sunrise.fill", "sun.max.fill", "sunset.fill"][i % 3]
    }

    private func homeFormattedHour(_ h: Int) -> String {
        let suffix = h < 12 ? "AM" : "PM"
        let display = h == 0 ? 12 : (h > 12 ? h - 12 : h)
        return "\(display):00 \(suffix)"
    }

    // MARK: - Active Plan Card (per saved plan)

    private func activePlanCard(plan: DailyPlan) -> some View {
        let area = BodyArea(rawValue: plan.bodyArea) ?? .knee
        let completed = plan.slots.filter(\.isCompleted).count
        let total = plan.slots.count
        let nextSlot = plan.slots.first(where: { !$0.isCompleted })
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                // Icon + Progress Ring
                ZStack {
                    Circle()
                        .stroke(area.tintColor.opacity(0.15), lineWidth: 4)
                        .frame(width: 48, height: 48)
                    Circle()
                        .trim(from: 0, to: total > 0 ? CGFloat(completed) / CGFloat(total) : 0)
                        .stroke(area.tintColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))
                    
                    Image(systemName: area.systemImage)
                        .font(.system(size: 20))
                        .foregroundColor(area.tintColor)
                }
                
                Spacer()
                
                Button {
                    setConditionFromPlan(plan)
                    appState.navigationPath.append("Schedule")
                } label: {
                    Image(systemName: "list.clipboard.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(area.tintColor)
                        .clipShape(Circle())
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plan.bodyArea.capitalized)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                
                Text(plan.conditionName)
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }
            
            Divider()

            HStack {
                if let next = nextSlot {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("Next: \(homeFormattedHour(next.scheduledHour))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(PPColor.vitalityTeal)
                        Text("All done today!")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(PPColor.vitalityTeal)
                    }
                }
                
                Spacer()
                
                Text("\(completed)/\(total) Done")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    // MARK: - Helpful Blurb
    
    // (Removed static helpfulBlurbCard to use InsightCarousel)

    // MARK: - Start Session Card

    private var startSessionCard: some View {
        Button {
            appState.navigationPath.append("Triage")
        } label: {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(PPGradient.action)
                        .frame(width: 64, height: 64)
                        .shadow(color: PPColor.actionBlue.opacity(0.4), radius: 12, y: 4)

                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }

                VStack(spacing: 4) {
                    Text("New Session")
                        .font(.title3.bold())
                        .foregroundColor(PPColor.actionBlue)
                    Text("Select the area that needs rehab and get a tailored plan")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(PPColor.actionBlue.opacity(0.05))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(PPColor.actionBlue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - How It Works

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How It Works")
                .font(.headline)
                .padding(.leading, 4)

            FeatureRow(
                iconColor: PPColor.vitalityTeal,
                iconName: "arkit",
                title: "AR Body Tracking",
                description: "Uses your device's camera and AR to measure joint angles in real time — clinical-grade rehab without the cost."
            )

            FeatureRow(
                iconColor: PPColor.actionBlue,
                iconName: "list.clipboard.fill",
                title: "Personalized Plans",
                description: "Exercises tailored specifically to your condition, with step-by-step guidance."
            )

            FeatureRow(
                iconColor: PPColor.recoveryIndigo,
                iconName: "waveform.path.ecg",
                title: "Real-time Feedback",
                description: "Live angle readouts and color zones keep you in the correct range throughout every rep."
            )
        }
        .padding(18)
        .background(Color.white)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(PPColor.actionBlue.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Disclaimer

    private var disclaimerBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.secondary)
            Text("For educational demo only. Not medical advice. Consult a healthcare professional.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PPColor.glassBackground)
        .cornerRadius(14)
    }
}

// MARK: - Feature Row Component

struct FeatureRow: View {
    let iconColor: Color
    let iconName: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
        }
    }
}
