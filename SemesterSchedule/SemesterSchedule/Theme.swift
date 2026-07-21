import SwiftUI

/// Cool mist + forest teal — readable on phone, distinct from default iOS blue and cream/serif kits.
enum ScheduleTheme {
    static let ink = Color(red: 0.10, green: 0.14, blue: 0.18)
    static let inkMuted = Color(red: 0.35, green: 0.40, blue: 0.45)
    static let mist = Color(red: 0.93, green: 0.95, blue: 0.97)
    static let mistDeep = Color(red: 0.84, green: 0.89, blue: 0.92)
    static let teal = Color(red: 0.08, green: 0.45, blue: 0.48)
    static let tealBright = Color(red: 0.12, green: 0.55, blue: 0.58)
    static let amber = Color(red: 0.82, green: 0.52, blue: 0.18)
    static let surface = Color.white.opacity(0.72)
    static let surfaceSolid = Color(red: 0.98, green: 0.99, blue: 1.0)
    static let hairline = Color(red: 0.10, green: 0.14, blue: 0.18).opacity(0.10)

    static var brandFont: Font {
        .system(size: 34, weight: .bold, design: .rounded)
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
}
