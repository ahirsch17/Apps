import SwiftUI
import UIKit

/// Ensures wheel picker rows stay readable on light cream backgrounds.
enum PickerContrast {
    static func applyUIPickerLabels() {
        let ink = UIColor(red: 0.22, green: 0.18, blue: 0.16, alpha: 1)
        let label = UILabel.appearance(whenContainedInInstancesOf: [UIPickerView.self])
        label.textColor = ink
        label.font = UIFont.systemFont(ofSize: 22, weight: .medium)
    }
}

/// Solid backing so the system wheel picker does not blend into StokeTheme.cream.
struct ReadableWheelPickerBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(StokeTheme.ink.opacity(0.14), lineWidth: 1)
            )
            .shadow(color: StokeTheme.ink.opacity(0.08), radius: 8, y: 2)
    }
}

extension View {
    func readableWheelPickerChrome() -> some View {
        modifier(ReadableWheelPickerBackground())
    }
}
