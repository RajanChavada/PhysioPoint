import SwiftUI

// MARK: - App Tab

enum AppTab: String, CaseIterable, Hashable {
    case home     = "Home"
    case schedule = "Schedule"
    case learn    = "Learn"
    case profile  = "Profile"
}

// MARK: - App State
// Uses EnvironmentObject instead of @Binding to avoid prop-drilling
// across the 4-tab navigation hierarchy.

final class PhysioPointState: ObservableObject {
    @Published var selectedCondition: Condition?
    @Published var selectedExercise: Exercise?
    @Published var navigationPath = NavigationPath()
    @Published var latestMetrics: SessionMetrics?
    @Published var hasCompletedOnboarding: Bool = false
    @Published var onboardingPage: Int = 0
    @Published var activeSlotID: UUID?          // which schedule slot is currently being exercised
    @Published var selectedTab: AppTab = .home
}
