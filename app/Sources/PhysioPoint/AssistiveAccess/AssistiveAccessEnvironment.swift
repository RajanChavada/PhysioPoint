import SwiftUI

// Custom environment key — works on iOS 16+
private struct AssistiveAccessActiveKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isAssistiveAccessActive: Bool {
        get { self[AssistiveAccessActiveKey.self] }
        set { self[AssistiveAccessActiveKey.self] = newValue }
    }
}

// Notification to pop Assistive mode back to root
extension Notification.Name {
    static let assistiveReturnHome = Notification.Name("assistiveReturnHome")
}
