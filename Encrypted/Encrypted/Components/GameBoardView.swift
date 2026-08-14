import SwiftUI

struct GameBoardView: View {
    let cards: [GameCard]
    let playerRole: PlayerRole
    let playerTeam: TeamColor
    var votes: [String: [String]] = [:]
    var currentGuesses: [String] = []
    var onCardPress: (String) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 5)

    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let totalSpacing = spacing * 4
            let side = floor((min(geo.size.width, geo.size.height) - totalSpacing) / 5)

            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(cards) { card in
                    WordCardView(
                        word: card.word,
                        size: side,
                        borderColor: borderColor(for: card),
                        revealed: card.revealed,
                        isSelected: currentGuesses.contains(card.id),
                        voteCount: voteCount(for: card.id),
                        onPress: { onCardPress(card.id) }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .aspectRatio(1, contentMode: .fit)
        .padding(.horizontal, 4)
    }

    private func borderColor(for card: GameCard) -> Color {
        if card.revealed {
            switch card.type {
            case .assassin: return Theme.assassin
            case .red: return Theme.redTeam
            case .blue: return Theme.blueTeam
            case .neutral: return Theme.neutralCard
            }
        }

        if playerRole == .decoder {
            return Theme.neutralCard
        }

        switch card.type {
        case .assassin: return Theme.assassin
        case .neutral: return Theme.neutralCard
        case .red:
            return playerTeam == .red ? Theme.redTeam : Theme.opponentHidden
        case .blue:
            return playerTeam == .blue ? Theme.blueTeam : Theme.opponentHidden
        }
    }

    private func voteCount(for cardId: String) -> Int {
        votes.values.filter { $0.contains(cardId) }.count
    }
}
