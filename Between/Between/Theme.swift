import SwiftUI

// MARK: - Brand & surfaces
//
// Student-facing UI uses warm product colors (approachable daily use).
// VT maroon/orange on SSO/pilot co-brand only, not every button
// See docs/BRAND_GUIDE.md for psychology rationale.

enum BetweenTheme {
    // Product maroon: warmer than Chicago Maroon, for identity/wordmark/headers
    static let accent = Color(red: 0.545, green: 0.165, blue: 0.290) // #8B2A4A
    static let accentSoft = accent.opacity(0.10)

    // Action coral: primary CTAs, energetic without "admin portal" feel
    static let accentAction = Color(red: 0.910, green: 0.365, blue: 0.278) // #E85D47
    static let accentActionSoft = accentAction.opacity(0.12)

    /// Legacy alias + wordmark second syllable
    static let accentSecondary = accentAction

    // VT official tones: SSO screen & pilot co-brand only
    static let vtMaroon = Color(red: 0.525, green: 0.122, blue: 0.255) // #861F41
    static let vtOrange = Color(red: 0.812, green: 0.267, blue: 0.125) // #CF4420

    static let free = Color(red: 0.18, green: 0.72, blue: 0.48)
    static let busy = Color(red: 0.55, green: 0.55, blue: 0.58)
    static let studying = Color(red: 0.45, green: 0.38, blue: 0.85)
    static let onTheWay = Color(red: 0.22, green: 0.55, blue: 0.95)

    static let neonBlue = accent
    static let neonMint = free
    static let neonGreen = free
    static let neonViolet = studying
    static let neonAmber = accentAction

    static let cornerRadius: CGFloat = 14
    static let cardPadding: CGFloat = 16

    static func screenBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.06, green: 0.06, blue: 0.08) : Color(red: 0.98, green: 0.975, blue: 0.97)
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : .white
    }

    static func surfaceMuted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.14, green: 0.14, blue: 0.16) : Color(red: 0.945, green: 0.945, blue: 0.955)
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
    static func wordmark(_ size: BetweenWordmark.Size) -> Font {
        switch size {
        case .large: return .system(size: 34, weight: .bold, design: .rounded)
        case .compact: return .system(size: 20, weight: .bold, design: .rounded)
        }
    }
}

// MARK: - Wordmark & mark

// Two bars with gap representing time between classes
struct BetweenMark: View {
    enum Size { case hero, compact, toolbar }
    var size: Size = .hero

    private var barWidth: CGFloat {
        switch size {
        case .hero: return 14
        case .compact: return 8
        case .toolbar: return 6
        }
    }

    private var barHeight: CGFloat {
        switch size {
        case .hero: return 52
        case .compact: return 32
        case .toolbar: return 22
        }
    }

    private var gap: CGFloat {
        switch size {
        case .hero: return 10
        case .compact: return 6
        case .toolbar: return 5
        }
    }

    var body: some View {
        HStack(spacing: gap) {
            RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
                .fill(BetweenTheme.accent)
                .frame(width: barWidth, height: barHeight)
            RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
                .fill(BetweenTheme.accentAction)
                .frame(width: barWidth, height: barHeight)
        }
        .accessibilityHidden(true)
    }
}

struct BetweenWordmark: View {
    enum Size { case large, compact }
    var size: Size = .large

    var body: some View {
        HStack(spacing: 0) {
            Text("Be")
                .foregroundStyle(BetweenTheme.accent)
            Text("tween")
                .foregroundStyle(BetweenTheme.accentAction)
        }
        .font(BetweenFont.wordmark(size))
        .accessibilityLabel("Between")
    }
}

struct BetweenBrandLockup: View {
    enum Style { case welcome, toolbar }
    var style: Style = .welcome

    var body: some View {
        VStack(spacing: style == .welcome ? 14 : 6) {
            BetweenMark(size: style == .welcome ? .hero : .compact)
            if style == .welcome {
                BetweenWordmark(size: .large)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Between")
    }
}

struct VTPilotBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(BetweenTheme.vtOrange)
                .frame(width: 8, height: 8)
            Text("Virginia Tech pilot")
                .font(BetweenFont.captionMedium())
                .foregroundStyle(BetweenTheme.vtMaroon)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(BetweenTheme.vtMaroon.opacity(0.08))
        .clipShape(Capsule())
    }
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
            .background(BetweenTheme.accentAction.opacity(configuration.isPressed ? 0.85 : 1))
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
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
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
                        .background(BetweenTheme.accentAction)
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
