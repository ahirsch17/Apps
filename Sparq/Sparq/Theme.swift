import SwiftUI

// MARK: - Brand & surfaces
//
// Student-facing UI uses warm product colors (approachable daily use).
// VT maroon/orange on SSO/pilot co-brand only, not every button
// See docs/BRAND_GUIDE.md for psychology rationale.

enum SparqTheme {
    // Product purple - matches design mockups (#6366F1)
    static let accent = Color(red: 0.388, green: 0.404, blue: 0.945)
    static let accentSoft = Color(red: 0.925, green: 0.925, blue: 0.996)

    // Secondary lavender / coral accent for CTAs
    static let accentAction = Color(red: 0.545, green: 0.361, blue: 0.965) // #8B5CF6
    static let accentActionSoft = accentAction.opacity(0.12)

    static let accentSecondary = Color(red: 0.655, green: 0.545, blue: 0.980) // #A78BFA

    // VT official tones: SSO screen & pilot co-brand only
    static let vtMaroon = Color(red: 0.525, green: 0.122, blue: 0.255)
    static let vtOrange = Color(red: 0.812, green: 0.267, blue: 0.125)

    static let free = Color(red: 0.063, green: 0.725, blue: 0.506) // #10B981
    static let freeSoft = Color(red: 0.820, green: 0.980, blue: 0.898)
    static let busy = Color(red: 0.55, green: 0.55, blue: 0.58)
    static let studying = Color(red: 0.388, green: 0.400, blue: 0.945) // indigo
    static let onTheWay = Color(red: 0.231, green: 0.510, blue: 0.965)

    static let classBlock = accent
    static let classBlockSoft = Color(red: 0.91, green: 0.91, blue: 0.99)
    static let scheduleOrange = Color(red: 0.976, green: 0.451, blue: 0.086)
    static let scheduleOrangeSoft = Color(red: 1.0, green: 0.96, blue: 0.92)

    static let cornerRadius: CGFloat = 16
    static let cardRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let chipRadius: CGFloat = 20
    static let buttonRadius: CGFloat = 24

    static func scheduleClassColors(for courseCode: String) -> (fill: Color, accent: Color) {
        let bucket = abs(courseCode.hashValue) % 3
        switch bucket {
        case 0: return (classBlockSoft, classBlock)
        case 1: return (scheduleOrangeSoft, scheduleOrange)
        default: return (Color(red: 0.91, green: 0.93, blue: 1.0), studying)
        }
    }

    static func screenBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.06, green: 0.06, blue: 0.08) : Color(red: 0.98, green: 0.98, blue: 0.99)
    }

    static func surface(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.11, green: 0.11, blue: 0.13) : .white
    }

    static func surfaceMuted(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.14, green: 0.14, blue: 0.16) : Color(red: 0.945, green: 0.945, blue: 0.955)
    }

    static func divider(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }
}

// MARK: - Typography

enum SparqFont {
    static func screenTitle() -> Font { .title2.weight(.semibold) }
    static func greeting() -> Font { .title2.weight(.semibold) }
    static func sectionTitle() -> Font { .subheadline.weight(.semibold) }
    static func cardTitle() -> Font { .subheadline.weight(.semibold) }
    static func body() -> Font { .subheadline }
    static func secondary() -> Font { .footnote }
    static func caption() -> Font { .caption }
    static func captionMedium() -> Font { .caption.weight(.medium) }
    static func wordmark(_ size: SparqWordmark.Size) -> Font {
        switch size {
        case .large: return .system(size: 28, weight: .semibold, design: .default)
        case .compact: return .system(size: 17, weight: .semibold, design: .default)
        }
    }
}

// MARK: - Wordmark & mark

/// Spark mark - matches app icon (8-point spark, not pause bars / plus).
struct SparqMark: View {
    enum Size { case hero, compact, toolbar }
    var size: Size = .hero

    private var extent: CGFloat {
        switch size {
        case .hero: return 56
        case .compact: return 34
        case .toolbar: return 22
        }
    }

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: extent * 0.72, weight: .bold))
            .foregroundStyle(
                LinearGradient(
                    colors: [SparqTheme.accent, SparqTheme.accentAction],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: extent, height: extent)
            .accessibilityHidden(true)
    }
}

struct SparqWordmark: View {
    enum Size { case large, compact }
    var size: Size = .large

    var body: some View {
        Text("Sparq")
            .font(SparqFont.wordmark(size))
            .foregroundStyle(SparqTheme.accent)
            .accessibilityLabel("Sparq")
    }
}

/// Compact header lockup: mark + wordmark on one line.
struct SparqHeaderLockup: View {
    var body: some View {
        HStack(spacing: 8) {
            SparqMark(size: .toolbar)
            SparqWordmark(size: .compact)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sparq")
    }
}

struct SparqBrandLockup: View {
    enum Style { case welcome, toolbar }
    var style: Style = .welcome

    var body: some View {
        VStack(spacing: style == .welcome ? 10 : 6) {
            SparqMark(size: style == .welcome ? .hero : .compact)
            if style == .welcome {
                SparqWordmark(size: .large)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Sparq")
    }
}

struct VTPilotBadge: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(SparqTheme.vtOrange)
                .frame(width: 8, height: 8)
            Text("Virginia Tech pilot")
                .font(SparqFont.captionMedium())
                .foregroundStyle(SparqTheme.vtMaroon)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(SparqTheme.vtMaroon.opacity(0.08))
        .clipShape(Capsule())
    }
}

// MARK: - Cards & buttons

struct SurfaceCard: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(SparqTheme.cardPadding)
            .background(SparqTheme.surface(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: SparqTheme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SparqTheme.cornerRadius, style: .continuous)
                    .strokeBorder(SparqTheme.divider(colorScheme), lineWidth: 0.5)
            )
    }
}

struct SparqPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(SparqTheme.accent.opacity(configuration.isPressed ? 0.85 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: SparqTheme.buttonRadius, style: .continuous))
    }
}

struct SparqSecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(SparqTheme.surfaceMuted(colorScheme))
            .foregroundStyle(.primary)
            .clipShape(RoundedRectangle(cornerRadius: SparqTheme.buttonRadius, style: .continuous))
    }
}

struct SparqChipModifier: ViewModifier {
    let selected: Bool
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selected ? SparqTheme.accent : SparqTheme.surfaceMuted(colorScheme))
            .foregroundStyle(selected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: SparqTheme.chipRadius, style: .continuous))
    }
}

extension View {
    func sparqChip(selected: Bool) -> some View {
        modifier(SparqChipModifier(selected: selected))
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
                .font(SparqFont.sectionTitle())
                .foregroundStyle(.primary)
            if let subtitle {
                Text(subtitle)
                    .font(SparqFont.caption())
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
                .font(SparqFont.captionMedium())
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
                    .background(SparqTheme.accentSoft)
                    .clipShape(Circle())

                if badge > 0 {
                    Text("\(badge)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(SparqTheme.accentAction)
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
        case .freeNow: return SparqTheme.free
        case .onTheWay: return SparqTheme.onTheWay
        case .studying: return SparqTheme.studying
        case .busy: return SparqTheme.busy
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
        case .sameSection: return SparqTheme.accent
        case .differentSection: return SparqTheme.studying
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
                        .strokeBorder(SparqTheme.free, lineWidth: 2.5)
                        .padding(-2)
                }
            }
    }
}

// MARK: - Time formatting for course lookup

enum SparqFormat {
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
