import SwiftUI
import UIKit

enum Theme {
    static let accent = Color(red: 1.0, green: 0.62, blue: 0.38)
    static let panel = Color(white: 0.09)
    static let card = Color(white: 0.14)
}

extension Color {
    init(rgb: RGB) {
        self.init(.sRGB, red: Double(rgb.x), green: Double(rgb.y), blue: Double(rgb.z), opacity: 1)
    }

    var rgb: RGB? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return ColorMath.clamp01(RGB(Float(r), Float(g), Float(b)))
    }
}

struct LabeledSlider: View {
    let title: String
    @Binding var value: Float
    var range: ClosedRange<Float> = -1...1
    var neutral: Float = 0
    var format: (Float) -> String = { String(format: "%+.0f", $0 * 100) }

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(format(value))
                    .monospacedDigit()
                    .foregroundStyle(value == neutral ? Color.secondary : Theme.accent)
            }
            .font(.caption)
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { value = neutral }
            Slider(value: $value, in: range)
        }
    }
}

struct HueSlider: View {
    let title: String
    @Binding var hue: Float

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Circle()
                    .fill(Color(hue: Double(hue) / 360, saturation: 0.8, brightness: 0.95))
                    .frame(width: 12, height: 12)
            }
            .font(.caption)
            Slider(value: $hue, in: 0...360)
                .background(
                    LinearGradient(
                        colors: stride(from: 0.0, through: 1.0, by: 1.0 / 6).map { Color(hue: $0, saturation: 0.7, brightness: 0.9) },
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 4)
                    .clipShape(Capsule())
                    .opacity(0.6)
                )
        }
    }
}

struct LookTile: View {
    let name: String
    let image: UIImage?
    let selected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Group {
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Theme.card.overlay(ProgressView().controlSize(.small))
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? Theme.accent : .clear, lineWidth: 2.5)
            )
            Text(name)
                .font(.caption2.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? Theme.accent : .primary)
                .lineLimit(1)
                .frame(width: 76)
        }
    }
}

struct Swatch: View {
    let color: RGB
    var size: CGFloat = 28

    var body: some View {
        Circle()
            .fill(Color(rgb: color))
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(.white.opacity(0.35), lineWidth: 1))
    }
}

struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.top, 8)
            .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct BusyOverlay: View {
    let label: String
    var progress: Double?

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 12) {
                if let progress, progress > 0 {
                    ProgressView(value: progress).frame(width: 160)
                } else {
                    ProgressView()
                }
                Text(label).font(.footnote)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct SharedFile: Identifiable {
    let url: URL
    var id: URL { url }
}

extension View {
    /// Shows a toast for a couple of seconds whenever `text` is set.
    func toast(_ text: Binding<String?>) -> some View {
        overlay(alignment: .top) {
            if let message = text.wrappedValue {
                ToastView(text: message)
                    .task(id: message) {
                        try? await Task.sleep(for: .seconds(2.2))
                        withAnimation { text.wrappedValue = nil }
                    }
            }
        }
        .animation(.easeOut(duration: 0.2), value: text.wrappedValue)
    }
}
