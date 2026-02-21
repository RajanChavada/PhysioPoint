import SwiftUI

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 122, 255)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - PhysioPoint Brand Palette

enum PPColor {
    /// #007AFF — Primary interactions
    static let actionBlue = Color(hex: "007AFF")
    /// #30D5C8 — Health-focused accents
    static let vitalityTeal = Color(hex: "30D5C8")
    /// #5856D6 — Deep accents and progress
    static let recoveryIndigo = Color(hex: "5856D6")
    /// #F2F7F7 — Light off-white surface
    static let glassBackground = Color(hex: "F2F7F7")
    /// White
    static let pureWhite = Color.white
}

// MARK: - Brand Gradients

enum PPGradient {
    /// Teal → Blue action gradient for buttons
    static let action = LinearGradient(
        colors: [PPColor.vitalityTeal, PPColor.actionBlue],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Soft page background — almost white with a hint of teal
    static let pageBackground = LinearGradient(
        colors: [
            PPColor.vitalityTeal.opacity(0.10),
            PPColor.actionBlue.opacity(0.05),
            PPColor.glassBackground
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Radial glow behind hero elements
    static func heroGlow(center: UnitPoint = .center) -> RadialGradient {
        RadialGradient(
            colors: [PPColor.actionBlue.opacity(0.18), Color.clear],
            center: center,
            startRadius: 0,
            endRadius: 150
        )
    }
}
