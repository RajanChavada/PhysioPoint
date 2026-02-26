import SwiftUI

// MARK: - Glass Style Tokens
enum PhysioGlassStyle {
    case card
    case sheet
    case pill
    case fab
    case inputBar
    case overlay
}

// MARK: - Version-safe View extension
extension View {
    /// Apply glass-like styling to views.
    ///
    /// Currently uses material/gradient fallbacks compatible with Swift Playgrounds.
    /// When building with Xcode + iOS 26 SDK, replace the body with:
    /// ```
    /// self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    /// ```
    @ViewBuilder
    func physioGlass(_ style: PhysioGlassStyle = .card) -> some View {
        switch style {
        case .card:
            self
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)

        case .sheet:
            self
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))

        case .pill:
            self
                .background(Color(.systemGray5))
                .clipShape(Capsule())

        case .fab:
            self
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0, green: 0.478, blue: 1.0),
                            Color(red: 0, green: 0.780, blue: 0.745)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(
                    color: Color(red: 0, green: 0.478, blue: 1.0).opacity(0.35),
                    radius: 12, y: 4
                )

        case .inputBar:
            self
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 14))

        case .overlay:
            self
                .background(Color.green.opacity(0.15))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.08), radius: 4)
        }
    }
}

// MARK: - iOS 26 Liquid Glass (Xcode only)
//
// When building with Xcode targeting iOS 26, uncomment this block
// and change physioGlass() to call applyLiquidGlass() when available:
//
// @available(iOS 26.0, *)
// private extension View {
//     @ViewBuilder
//     func applyLiquidGlass(_ style: PhysioGlassStyle) -> some View {
//         switch style {
//         case .card:
//             self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
//         case .sheet:
//             self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24))
//         case .pill:
//             self.glassEffect(.regular, in: Capsule())
//         case .fab:
//             self.glassEffect(
//                 .regular.tint(Color(red: 0, green: 0.478, blue: 1.0).opacity(0.25)).interactive(),
//                 in: Circle()
//             )
//         case .inputBar:
//             self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
//         case .overlay:
//             self.glassEffect(.regular.tint(Color.green.opacity(0.15)), in: Capsule())
//         }
//     }
// }
