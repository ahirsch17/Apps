import SwiftUI

enum BetweenTheme {
    static let baseBackground = Color(red: 0.04, green: 0.05, blue: 0.11)
    static let surface = Color.white.opacity(0.09)
    static let surfaceStrong = Color.white.opacity(0.15)
    static let neonBlue = Color(red: 0.22, green: 0.53, blue: 1.00)
    static let neonMint = Color(red: 0.30, green: 0.95, blue: 0.83)
    static let neonGreen = Color(red: 0.45, green: 0.99, blue: 0.54)
    static let neonViolet = Color(red: 0.65, green: 0.41, blue: 0.98)
    static let neonAmber = Color(red: 1.00, green: 0.72, blue: 0.28)
}

struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(.ultraThinMaterial.opacity(0.45))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}

extension PresenceStatus {
    var color: Color {
        switch self {
        case .freeNow: return BetweenTheme.neonMint
        case .onTheWay: return BetweenTheme.neonGreen
        case .studying: return BetweenTheme.neonViolet
        case .busy: return BetweenTheme.neonAmber
        }
    }
}

extension ClassConnection.Kind {
    var color: Color {
        switch self {
        case .sameSection: return BetweenTheme.neonBlue
        case .differentSection: return BetweenTheme.neonViolet
        }
    }
}
