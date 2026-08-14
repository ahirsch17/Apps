import SwiftUI

struct PrimaryButtonLabel: View {
  let title: String
  var isDisabled: Bool = false

  var body: some View {
    Text(title)
      .font(.headline)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .foregroundColor(.white)
      .background(
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .fill(isDisabled ? Color.white.opacity(0.18) : Color.blue.opacity(0.75))
      )
  }
}

struct PrimaryButton: View {
  let title: String
  var isDisabled: Bool = false
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      PrimaryButtonLabel(title: title, isDisabled: isDisabled)
    }
    .disabled(isDisabled)
  }
}

struct Card: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(Color.black.opacity(0.25))
          .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .stroke(Color.white.opacity(0.12), lineWidth: 1)
          )
      )
  }
}

extension View {
  func card() -> some View { modifier(Card()) }
}

