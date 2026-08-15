import SwiftUI

enum SFTheme {
    static let accent = Color(red: 0.91, green: 0.37, blue: 0.27)
    static let accentDeep = Color(red: 0.72, green: 0.22, blue: 0.18)
    static let cream = Color(red: 0.99, green: 0.96, blue: 0.92)
    static let ink = Color(red: 0.18, green: 0.14, blue: 0.13)

    static var background: Color {
        Color(.systemBackground)
    }
}

struct SoftCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

extension View {
    func softCard() -> some View {
        modifier(SoftCard())
    }
}
