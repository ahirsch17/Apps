import SwiftUI

enum BetweenTheme {
    static let neonBlue = Color(red: 0.22, green: 0.53, blue: 1.00)
    static let neonMint = Color(red: 0.30, green: 0.95, blue: 0.83)
    static let neonGreen = Color(red: 0.45, green: 0.99, blue: 0.54)
    static let neonViolet = Color(red: 0.65, green: 0.41, blue: 0.98)
    static let neonAmber = Color(red: 1.00, green: 0.72, blue: 0.28)

    static func screenBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.07, green: 0.08, blue: 0.10) : Color(red: 0.96, green: 0.97, blue: 0.98)
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.12, green: 0.13, blue: 0.16) : Color.white
    }

    static func surfaceMuted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.10, green: 0.11, blue: 0.13) : Color(red: 0.93, green: 0.94, blue: 0.96)
    }
}

struct SurfaceCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(BetweenTheme.surface(colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

extension View {
    func surfaceCard() -> some View {
        modifier(SurfaceCard())
    }

    /// Legacy alias — prefer `surfaceCard()` for readable sections.
    func glassCard() -> some View {
        surfaceCard()
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

    var shortLabel: String {
        switch self {
        case .sameSection: return "Same section"
        case .differentSection: return "Other section"
        }
    }
}

enum FriendColorPalette {
    private static let palette: [Color] = [
        Color(red: 0.65, green: 0.41, blue: 0.98),
        Color(red: 0.30, green: 0.85, blue: 0.55),
        Color(red: 1.00, green: 0.55, blue: 0.35),
        Color(red: 0.98, green: 0.45, blue: 0.65),
        Color(red: 0.30, green: 0.75, blue: 0.95),
        Color(red: 1.00, green: 0.72, blue: 0.28),
        Color(red: 0.45, green: 0.99, blue: 0.54),
        Color(red: 0.22, green: 0.53, blue: 1.00)
    ]

    static func color(for friendId: String) -> Color {
        palette[abs(friendId.hashValue) % palette.count]
    }
}
