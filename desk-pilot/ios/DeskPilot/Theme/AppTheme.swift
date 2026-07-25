import SwiftUI
import UIKit

enum AppTheme {
    static let background = Color(red: 0.04, green: 0.05, blue: 0.08)
    static let backgroundElevated = Color(red: 0.07, green: 0.08, blue: 0.12)
    static let card = Color(red: 0.11, green: 0.12, blue: 0.17)
    static let cardHighlight = Color(red: 0.14, green: 0.16, blue: 0.22)
    static let cardBorder = Color.white.opacity(0.08)
    static let accent = Color(red: 0.35, green: 0.68, blue: 1.0)
    static let accentMuted = Color(red: 0.35, green: 0.68, blue: 1.0).opacity(0.22)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)
    static let success = Color(red: 0.28, green: 0.88, blue: 0.58)
    static let warning = Color(red: 1.0, green: 0.76, blue: 0.32)
    static let danger = Color(red: 1.0, green: 0.38, blue: 0.38)
    static let netflix = Color(red: 0.90, green: 0.04, blue: 0.14)
    static let primeVideo = Color(red: 0.0, green: 0.66, blue: 0.88)

    static let cornerRadius: CGFloat = 18
    static let compactRadius: CGFloat = 12
    static let minTapTarget: CGFloat = 44

    static var screenGradient: LinearGradient {
        LinearGradient(
            colors: [background, backgroundElevated, background],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
    }
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppTheme.screenGradient.ignoresSafeArea())
    }
}

struct SectionHeader: View {
    let title: String
    var icon: String?

    var body: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
        }
    }
}

struct StatusMessage: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
    }
}

enum Haptics {
    static func light(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func medium(enabled: Bool) {
        guard enabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }

    func screenBackground() -> some View {
        modifier(ScreenBackground())
    }

    func deskPilotNavigation(_ title: String) -> some View {
        navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.backgroundElevated.opacity(0.95), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
            .background(isActive ? AppTheme.accent : AppTheme.cardHighlight)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.compactRadius, style: .continuous)
                    .stroke(isActive ? AppTheme.accent : AppTheme.cardBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(width: 36, height: 44)
            .background(AppTheme.cardHighlight)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(AppTheme.cardBorder, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct TileButtonStyle: ButtonStyle {
    var tint: Color = AppTheme.accent

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(minHeight: 72)
            .background(AppTheme.cardHighlight)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .stroke(tint.opacity(0.18), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct StreamingAppButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(minHeight: 104)
            .background(
                LinearGradient(
                    colors: [accent.opacity(0.28), AppTheme.cardHighlight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .stroke(accent.opacity(0.45), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct AccentHeroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [AppTheme.accent.opacity(0.22), AppTheme.cardHighlight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .stroke(AppTheme.accent.opacity(0.35), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
