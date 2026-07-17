import SwiftUI

enum StokeTheme {
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.93)
    static let parchment = Color(red: 0.94, green: 0.90, blue: 0.84)
    static let terracotta = Color(red: 0.78, green: 0.42, blue: 0.28)
    static let terracottaDeep = Color(red: 0.62, green: 0.32, blue: 0.22)
    static let sage = Color(red: 0.55, green: 0.62, blue: 0.52)
    static let ink = Color(red: 0.22, green: 0.18, blue: 0.16)
    static let inkMuted = Color(red: 0.45, green: 0.40, blue: 0.36)
    static let paceTrack = Color(red: 0.88, green: 0.82, blue: 0.74)
    static let progressFill = terracotta
    static let paceFill = sage.opacity(0.85)
}

struct StokeCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color.white.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: StokeTheme.ink.opacity(0.06), radius: 12, y: 4)
    }
}

extension View {
    func stokeCard() -> some View {
        modifier(StokeCard())
    }
}
