import SwiftUI

enum Theme {
    static let primary = Color(hex: 0x4A90E2)
    static let secondary = Color(hex: 0x7B68EE)
    static let success = Color(hex: 0x28A745)
    static let danger = Color(hex: 0xDC3545)
    static let redTeam = Color(hex: 0xFF6B6B)
    static let blueTeam = Color(hex: 0x4DABF7)
    static let gold = Color(hex: 0xFFD700)
    static let assassin = Color(hex: 0x2C2C2C)
    static let assassinAccent = Color(hex: 0xFF4444)
    static let neutralCard = Color(hex: 0xD4B896)
    static let cardBeige = Color(hex: 0xF5F1E8)
    static let opponentHidden = Color(hex: 0x888888)
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xE0E0E0)
    static let textMuted = Color(hex: 0xC0C0C0)
    static let panelFill = Color.white.opacity(0.15)
    static let panelBorder = Color.white.opacity(0.25)
    static let overlayDark = Color.black.opacity(0.55)
    static let overlayDarker = Color.black.opacity(0.65)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: opacity)
    }
}
