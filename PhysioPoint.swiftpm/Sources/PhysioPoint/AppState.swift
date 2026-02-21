import SwiftUI

final class PhysioPointState: ObservableObject {
    @Published var selectedCondition: Condition?
    @Published var selectedExercise: Exercise?
    @Published var navigationPath = NavigationPath()
    @Published var latestMetrics: SessionMetrics?
}
