import SwiftUI

enum SF {
    /// Flat ink. Not a gradient, not cream.
    static let ink = Color(red: 0.08, green: 0.08, blue: 0.07)
    static let tealDeep = ink
    static let teal = Color(red: 0.93, green: 0.76, blue: 0.38)
    static let coral = Color(red: 0.90, green: 0.28, blue: 0.16)
    static let mint = Color(red: 0.93, green: 0.76, blue: 0.38)
    static let line = Color.white.opacity(0.18)

    static var bg: Color { ink }
    static var card: Color { Color.white.opacity(0.05) }

    static func display(_ size: CGFloat) -> Font { .custom("IowanOldStyle-Roman", size: size) }
    static func displayItalic(_ size: CGFloat) -> Font { .custom("IowanOldStyle-Italic", size: size) }
    static func ui(_ size: CGFloat) -> Font { .custom("AvenirNext-Regular", size: size) }
    static func uiBold(_ size: CGFloat) -> Font { .custom("AvenirNext-DemiBold", size: size) }
    static func label(_ size: CGFloat) -> Font { .custom("AvenirNextCondensed-DemiBold", size: size) }

    static let rounded = ui(16)
}

struct StampButton: ButtonStyle {
    var filled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SF.label(16))
            .textCase(.uppercase)
            .tracking(1.2)
            .foregroundStyle(filled ? SF.ink : Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(filled ? SF.coral : Color.clear)
            .overlay(Rectangle().stroke(Color.white.opacity(filled ? 0 : 0.45), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

/// A name, set in the display face. No emoji, no glow.
struct TutorMark: View {
    let name: String
    var active: Bool = false
    var size: CGFloat = 120

    var body: some View {
        let letter = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1))
        ZStack {
            Rectangle()
                .stroke(active ? SF.coral : SF.teal, lineWidth: active ? 2 : 1)
                .frame(width: size, height: size)
            Text(letter.isEmpty ? "?" : letter)
                .font(SF.display(size * 0.42))
                .foregroundStyle(.white)
        }
        .accessibilityLabel(name)
    }
}

/// Three clean answers, drawn as marks. Filled ones are done.
struct RepTicks: View {
    let filled: Int
    var total: Int = SpeakPath.repsToPass

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { index in
                Rectangle()
                    .fill(index < filled ? SF.teal : Color.white.opacity(0.22))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityLabel("\(min(filled, total)) of \(total)")
    }
}
