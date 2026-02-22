import SwiftUI

@main
struct PhysioPointApp: App {
    @StateObject private var appState = PhysioPointState()
    @StateObject private var storage = StorageService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(storage)
                .preferredColorScheme(.light)
        }
    }
}