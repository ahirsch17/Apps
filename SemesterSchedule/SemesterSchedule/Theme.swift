import SwiftUI

/// Forest teal + cream paper + one warm amber block — like a marked-up week.
enum ScheduleTheme {
    static let ink = Color(red: 0.12, green: 0.16, blue: 0.16)
    static let inkMuted = Color(red: 0.38, green: 0.42, blue: 0.41)
    static let mist = Color(red: 0.94, green: 0.93, blue: 0.89)
    static let mistDeep = Color(red: 0.86, green: 0.88, blue: 0.84)
    static let teal = Color(red: 0.09, green: 0.38, blue: 0.39)
    static let tealBright = Color(red: 0.14, green: 0.50, blue: 0.51)
    static let amber = Color(red: 0.83, green: 0.54, blue: 0.23)
    static let cream = Color(red: 0.96, green: 0.94, blue: 0.89)
    static let surface = Color.white.opacity(0.72)
    static let surfaceSolid = Color(red: 0.99, green: 0.98, blue: 0.96)
    static let hairline = Color(red: 0.12, green: 0.16, blue: 0.16).opacity(0.10)

    static var brandFont: Font {
        .system(size: 36, weight: .heavy, design: .rounded)
    }

    static var sectionFont: Font {
        .system(size: 13, weight: .semibold, design: .rounded)
    }

    static var bodyFont: Font {
        .system(size: 16, weight: .regular, design: .rounded)
    }

    static var monoFont: Font {
        .system(size: 14, weight: .regular, design: .monospaced)
    }

    static func accent(for title: String) -> Color {
        let palette = [teal, amber, tealBright]
        var hash = 0
        for scalar in title.unicodeScalars {
            hash = hash &* 31 &+ Int(scalar.value)
        }
        return palette[abs(hash) % palette.count]
    }
}

/// Tiny Mon–Fri block strip used in the header — same idea as the app icon.
struct WeekStripMark: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            block(height: 10, color: ScheduleTheme.cream)
            block(height: 18, color: ScheduleTheme.amber)
            block(height: 14, color: ScheduleTheme.cream)
            block(height: 8, color: ScheduleTheme.tealBright)
            block(height: 12, color: ScheduleTheme.cream)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(ScheduleTheme.teal)
        )
        .accessibilityHidden(true)
    }

    private func block(height: CGFloat, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
            .fill(color)
            .frame(width: 5, height: height)
    }
}
