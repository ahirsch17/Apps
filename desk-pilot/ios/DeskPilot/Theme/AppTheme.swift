import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.05, green: 0.06, blue: 0.08)
    static let card = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let cardBorder = Color.white.opacity(0.08)
    static let accent = Color(red: 0.30, green: 0.64, blue: 1.0)
    static let accentMuted = Color(red: 0.30, green: 0.64, blue: 1.0).opacity(0.25)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let success = Color(red: 0.30, green: 0.85, blue: 0.55)
    static let warning = Color(red: 1.0, green: 0.75, blue: 0.30)
    static let danger = Color(red: 1.0, green: 0.35, blue: 0.35)

    static let cornerRadius: CGFloat = 16
    static let minTapTarget: CGFloat = 44
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isActive: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isActive ? AppTheme.background : AppTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: AppTheme.minTapTarget)
            .background(isActive ? AppTheme.accent : AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? AppTheme.accent : AppTheme.cardBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct TileButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(minHeight: 72)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
