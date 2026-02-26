import SwiftUI

// MARK: - Chat FAB Overlay

/// Floating action button that appears on Home and Learn screens.
/// Always visible — opens the AI chat sheet.
struct ChatFABOverlay: View {
    @State private var showChat = false
    @EnvironmentObject var appState: PhysioPointState
    @EnvironmentObject var engine: PhysioGuardEngine

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear  // pass-through

            Button { showChat.toggle() } label: {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 58, height: 58)
            }
            .physioGlass(.fab)
            .padding(.trailing, 20)
            .padding(.bottom, 90)  // sits above tab bar
        }
        .sheet(isPresented: $showChat) {
            PhysioChatSheet()
                .environmentObject(engine)
                .environmentObject(appState)
                .presentationDetents([.medium, .large], selection: .constant(.large))
                .presentationDragIndicator(.visible)
        }
    }
}
