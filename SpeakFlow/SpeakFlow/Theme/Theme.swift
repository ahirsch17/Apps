import SwiftUI

enum SF {
    // Teal / coral / deep ink — youthful, not purple or cream-textbook
    static let teal = Color(red: 0.05, green: 0.58, blue: 0.53)
    static let tealDeep = Color(red: 0.06, green: 0.09, blue: 0.16)
    static let coral = Color(red: 1.0, green: 0.42, blue: 0.29)
    static let mint = Color(red: 0.20, green: 0.90, blue: 0.72)
    static let cream = Color(red: 0.96, green: 0.97, blue: 0.98)

    static var bg: Color { Color(.systemBackground) }
    static var card: Color { Color(.secondarySystemBackground) }

    static let rounded = Font.system(.body, design: .rounded)
}

struct PulseAvatar: View {
    let emoji: String
    let color: Color
    var isActive: Bool
    var size: CGFloat = 140

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .stroke(color.opacity(0.35), lineWidth: 3)
                    .frame(width: size + 28, height: size + 28)
                    .scaleEffect(isActive ? 1.08 : 1)
                    .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: isActive)
            }
            Circle()
                .fill(
                    LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.35), radius: 18, y: 8)
            Text(emoji)
                .font(.system(size: size * 0.42))
        }
    }
}
