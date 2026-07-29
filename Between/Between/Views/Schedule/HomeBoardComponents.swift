import SwiftUI

// MARK: - Home board layout primitives

/// Full-width zone separator — visible gap between major areas.
struct BoardZone<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Hero panel — the one thing you read first.
struct BoardHeroPanel<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(BetweenTheme.surface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.35 : 0.06), radius: 12, y: 4)
    }
}

/// Compact tappable tile for secondary info (tap → sheet).
struct BoardTile: View {
    @Environment(\.colorScheme) private var colorScheme
    let icon: String
    let title: String
    let value: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer(minLength: 0)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
            .padding(14)
            .background(BetweenTheme.surface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(BetweenTheme.surfaceMuted(colorScheme), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Bottom dock — status controls, visually separate from the board.
struct BoardStatusDock<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(
                BetweenTheme.surface(colorScheme)
                    .shadow(color: .black.opacity(0.08), radius: 16, y: -4)
                    .ignoresSafeArea(edges: .bottom)
            )
    }
}
