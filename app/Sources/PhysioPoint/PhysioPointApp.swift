import SwiftUI

@main
struct PhysioPointApp: App {
    @StateObject private var appState = PhysioPointState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}