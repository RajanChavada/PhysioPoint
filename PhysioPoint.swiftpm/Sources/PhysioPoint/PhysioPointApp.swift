import SwiftUI

@main
struct PhysioPointApp: App {
    @StateObject private var appState = PhysioPointState()
    @StateObject private var storage = StorageService()
    @StateObject private var settings = PhysioPointSettings()
    @StateObject private var aiEngine = PhysioGuardEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(storage)
                .environmentObject(settings)
                .preferredColorScheme(.light)
                .environmentObject(aiEngine)
        }
    }
}