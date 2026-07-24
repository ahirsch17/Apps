import SwiftUI

// MARK: - Brand & surfaces

enum BetweenTheme {
    /// VT Chicago Maroon — campus-native but readable on white
    static let accent = Color(red: 0.53, green: 0.12, blue: 0.26)
    static let accentSoft = Color(red: 0.53, green: 0.12, blue: 0.26).opacity(0.10)
    static let accentSecondary = Color(red: 0.81, green: 0.27, blue: 0.13)

    static let free = Color(red: 0.18, green: 0.72, blue: 0.48)
    static let busy = Color(red: 0.55, green: 0.55, blue: 0.58)
    static let studying = Color(red: 0.45, green: 0.38, blue: 0.85)
    static let onTheWay = Color(red: 0.22, green: 0.55, blue: 0.95)

    static let neonBlue = accent
    static let neonMint = free
    static let neonGreen = free
    static let neonViolet = studying
    static let neonAmber = accentSecondary

    static let cornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16

    static func screenBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.06, green: 0.06, blue: 0.08) : Color(red: 0.97, green: 0.97, blue: 0.98)
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : .white
    }

    static func surfaceMuted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.14, green: 0.14, blue: 0.16) : Color(red: 0.94, green: 0.94, blue: 0.96)
    }
}

// MARK: - Typography

enum BetweenFont {
    static func screenTitle() -> Font { .title2.weight(.bold) }
    static func greeting() -> Font { .title.weight(.bold) }
    static func sectionTitle() -> Font { .subheadline.weight(.semibold) }
    static func cardTitle() -> Font { .headline.weight(.semibold) }
    static func body() -> Font { .body }
    static func secondary() -> Font { .subheadline }
    static func caption() -> Font { .caption }
    static func captionMedium() -> Font { .caption.weight(.medium) }
}

// MARK: - Cards & buttons

struct SurfaceCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(BetweenTheme.cardPadding)
            .background(BetweenTheme.surface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: BetweenTheme.cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.25 : 0.06), radius: 8, y: 2)
    }
}

struct BetweenPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(BetweenTheme.accent.opacity(configuration.isPressed ? 0.85 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct BetweenSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(BetweenTheme.surfaceMuted(colorScheme))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

extension View {
    func surfaceCard() -> some View {
        modifier(SurfaceCard())
    }

    func glassCard() -> some View {
        surfaceCard()
    }
}

// MARK: - Shared components

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(BetweenFont.sectionTitle())
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(BetweenFont.caption())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct StatusPill: View {
    let status: PresenceStatus
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(status.themeColor)
                .frame(width: 7, height: 7)
            Text(compact ? status.shortLabel : status.label)
                .font(BetweenFont.captionMedium())
                .foregroundStyle(status.themeColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.themeColor.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct ToolbarIconButton: View {
    let systemName: String
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(width: 40, height: 40)
                    .background(BetweenTheme.accentSoft)
                    .clipShape(Circle())

                if badge > 0 {
                    Text("\(badge)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(BetweenTheme.accentSecondary)
                        .clipShape(Capsule())
                        .offset(x: 6, y: -4)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Presence & connections

extension PresenceStatus {
    var themeColor: Color {
        switch self {
        case .freeNow: return BetweenTheme.free
        case .onTheWay: return BetweenTheme.onTheWay
        case .studying: return BetweenTheme.studying
        case .busy: return BetweenTheme.busy
        }
    }

    var color: Color { themeColor }

    var shortLabel: String {
        switch self {
        case .freeNow: return "Free"
        case .onTheWay: return "En route"
        case .studying: return "Studying"
        case .busy: return "Busy"
        }
    }

    var studentFacingDetail: String {
        switch self {
        case .freeNow: return "Free now"
        case .onTheWay: return "On the way"
        case .studying: return "Studying"
        case .busy: return "In class"
        }
    }
}

extension ClassConnection.Kind {
    var color: Color {
        switch self {
        case .sameSection: return BetweenTheme.accent
        case .differentSection: return BetweenTheme.studying
        }
    }

    var shortLabel: String {
        switch self {
        case .sameSection: return "Same section"
        case .differentSection: return "Other section"
        }
    }
}

// MARK: - Avatars

enum FriendColorPalette {
    private static let palette: [Color] = [
        Color(red: 0.53, green: 0.12, blue: 0.26),
        Color(red: 0.22, green: 0.55, blue: 0.95),
        Color(red: 0.18, green: 0.72, blue: 0.48),
        Color(red: 0.81, green: 0.27, blue: 0.13),
        Color(red: 0.45, green: 0.38, blue: 0.85),
        Color(red: 0.20, green: 0.65, blue: 0.72),
    ]

    static func color(for friendId: String) -> Color {
        palette[abs(friendId.hashValue) % palette.count]
    }

    static func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }
        return letters.joined().uppercased()
    }

    static func firstName(_ name: String) -> String {
        name.components(separatedBy: " ").first ?? name
    }
}

struct FriendAvatarView: View {
    let name: String
    let friendId: String
    var size: CGFloat = 40
    var showsFreeRing: Bool = false

    var body: some View {
        Text(FriendColorPalette.initials(for: name))
            .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(FriendColorPalette.color(for: friendId))
            .clipShape(Circle())
            .overlay {
                if showsFreeRing {
                    Circle()
                        .strokeBorder(BetweenTheme.free, lineWidth: 2.5)
                        .padding(-2)
                }
            }
    }
}

// MARK: - Time formatting for course lookup

enum BetweenFormat {
    static func displayTime(_ hhmm: String) -> String {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return hhmm }
        return ScheduleEngine.formatTime12Hour(h * 60 + m)
    }

    static func displayDays(_ days: [String]) -> String {
        if days == ["Mon", "Wed", "Fri"] { return "MWF" }
        if days == ["Tue", "Thu"] { return "TTh" }
        if days == ["Mon", "Wed"] { return "MW" }
        return days.joined(separator: " · ")
    }
}
