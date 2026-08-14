import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        BackgroundView(imageName: "OtherBackground", overlayOpacity: 0.65) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How to Play")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .shadow(color: .black.opacity(0.9), radius: 3, x: 1, y: 1)
                        .padding(.top, 8)

                    helpSection {
                        Text(
                            "Encrypted is an advanced mobile take on the party word game Codenames (Vlaada Chvátil). Same core idea—two teams, secret identities on a word grid, and careful clues—but tuned for phone play. Not affiliated with Czech Games Edition or the Codenames trademark."
                        )
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: 0xE8E8E8))
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.gold.opacity(0.35), lineWidth: 1)
                    )

                    helpSection(title: "Objective") {
                        Text("Be the first team to find all your secret words on the 5×5 grid. But beware of the assassin card — it means instant defeat!")
                            .helpBody()
                    }

                    helpSection(title: "Teams & Roles") {
                        Text("Red Team vs Blue Team")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Color(hex: 0xE8E8E8))
                        Text("Each team has:")
                            .helpBody()
                        Text("• Encoders — Give clues (can see the secret cards)")
                            .helpBullet()
                        Text("• Decoders — Guess words (cannot see secrets)")
                            .helpBullet()
                    }

                    helpSection(title: "How to Play") {
                        Text("Encoders:")
                            .helpSubheading()
                        Text("1. Look at the board — you can see your team's cards")
                            .helpBullet()
                        Text("2. Give a ONE-WORD clue + a number")
                            .helpBullet()
                        Text("3. Example: \"SPACE 3\" (3 cards relate to space)")
                            .helpBullet()
                        Text("4. The number tells how many cards match")
                            .helpBullet()

                        Text("Decoders:")
                            .helpSubheading()
                        Text("1. Discuss which cards might match the clue")
                            .helpBullet()
                        Text("2. Tap cards to select them, then reveal")
                            .helpBullet()
                        Text("3. Keep guessing if you find your team's cards")
                            .helpBullet()
                        Text("4. Your turn ends if you hit neutral or enemy cards")
                            .helpBullet()
                    }

                    helpSection(title: "Card Types") {
                        labeledCardType("Red Cards (9)", color: Theme.redTeam, detail: " — Red team's words")
                        labeledCardType("Blue Cards (8)", color: Theme.blueTeam, detail: " — Blue team's words")
                        labeledCardType("Neutral Cards (7)", color: .white, detail: " — End your turn")
                        labeledCardType("Assassin Card (1)", color: Theme.assassinAccent, detail: " — INSTANT LOSS!")
                    }

                    helpSection(title: "Winning") {
                        Text("✓ Find all your team's cards before the other team")
                            .helpBullet()
                        Text("✗ Hit the assassin = you lose immediately")
                            .helpBullet()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pro Tips")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(Theme.gold)
                            .frame(maxWidth: .infinity)
                        Text("• Encoders: Connect multiple safe cards")
                            .helpBullet()
                        Text("• Decoders: Discuss before tapping!")
                            .helpBullet()
                        Text("• Sometimes fewer guesses is safer")
                            .helpBullet()
                        Text("• Watch out for words that could be assassin!")
                            .helpBullet()
                    }
                    .padding(16)
                    .background(Theme.primary.opacity(0.2))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.primary.opacity(0.4), lineWidth: 2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Got It!") {
                        dismiss()
                    }
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
                    .padding(.top, 4)
                    .padding(.bottom, 36)
                }
                .padding(.horizontal, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func helpSection(title: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Theme.gold)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.panelFill)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.panelBorder))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func labeledCardType(_ label: String, color: Color, detail: String) -> some View {
        (Text(label).fontWeight(.bold).foregroundStyle(color) + Text(detail).foregroundStyle(Color(hex: 0xE8E8E8)))
            .font(.system(size: 15))
    }
}

private extension Text {
    func helpBody() -> some View {
        self
            .font(.system(size: 15))
            .foregroundStyle(Color(hex: 0xE8E8E8))
            .fixedSize(horizontal: false, vertical: true)
    }

    func helpBullet() -> some View {
        self
            .font(.system(size: 14))
            .foregroundStyle(Color(hex: 0xE0E0E0))
            .fixedSize(horizontal: false, vertical: true)
    }

    func helpSubheading() -> some View {
        self
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(.white)
            .padding(.top, 6)
    }
}
