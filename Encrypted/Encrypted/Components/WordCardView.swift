import SwiftUI

struct WordCardView: View {
    let word: String
    let size: CGFloat
    let borderColor: Color
    let revealed: Bool
    let isSelected: Bool
    var voteCount: Int = 0
    let onPress: () -> Void

    private var backgroundColor: Color {
        if revealed {
            return borderColor
        }
        if isSelected {
            return Theme.gold
        }
        return Theme.cardBeige
    }

    private var textColor: Color {
        if revealed && borderColor != Theme.neutralCard && borderColor != Theme.opponentHidden {
            return .white
        }
        return Color(hex: 0x1A1A1A)
    }

    var body: some View {
        Button(action: onPress) {
            ZStack(alignment: .bottomTrailing) {
                Text(word)
                    .font(.system(size: max(9, size * 0.14), weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(textColor)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                    .padding(4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                if voteCount > 0 && !revealed {
                    Text("👍 \(voteCount)")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.85))
                        .clipShape(Capsule())
                        .padding(3)
                }
            }
            .frame(width: size, height: size)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Theme.gold : borderColor, lineWidth: isSelected ? 4 : 3)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }
}
