import SwiftUI

private struct PlayerSetup: Identifiable {
    let id = UUID()
    var name: String
    var team: TeamColor
    var role: PlayerRole
}

struct GameSetupView: View {
    @EnvironmentObject private var store: GameStore
    @Binding var path: NavigationPath

    @State private var players: [PlayerSetup] = [
        PlayerSetup(name: "", team: .red, role: .encoder),
        PlayerSetup(name: "", team: .red, role: .decoder),
        PlayerSetup(name: "", team: .blue, role: .encoder),
        PlayerSetup(name: "", team: .blue, role: .decoder),
    ]
    @State private var useTimer = false
    @State private var timerMinutes = 3
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var showAlert = false
    @State private var pendingUnbalancedContinue = false

    var body: some View {
        BackgroundView(imageName: "OtherBackground", overlayOpacity: 0.6) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Game Setup")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .shadow(color: .black.opacity(0.9), radius: 3, x: 1, y: 1)
                        .padding(.top, 8)

                    Text("Players")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)

                    HStack(spacing: 10) {
                        Button("Random Teams") { randomizeTeams() }
                            .buttonStyle(SetupSecondaryButtonStyle())
                        Button("Random Roles") { randomizeRoles() }
                            .buttonStyle(SetupSecondaryButtonStyle())
                    }

                    ForEach(players.indices, id: \.self) { index in
                        playerCard(index: index)
                    }

                    if players.count < 8 {
                        Button("+ Add Player") {
                            players.append(PlayerSetup(name: "", team: .red, role: .decoder))
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Theme.success.opacity(0.85))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Text("Game Options")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Use Timer")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(Theme.textSecondary)
                            Spacer()
                            Button(useTimer ? "ON" : "OFF") {
                                useTimer.toggle()
                            }
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(useTimer ? Theme.success.opacity(0.85) : Color.gray.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        if useTimer {
                            Picker("Timer Duration", selection: $timerMinutes) {
                                ForEach([1, 2, 3, 4, 5, 7, 10, 15], id: \.self) { min in
                                    Text("\(min) minute\(min == 1 ? "" : "s")").tag(min)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                        }
                    }
                    .padding(14)
                    .background(Theme.panelFill)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.panelBorder))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Start Game") { startGame() }
                        .font(.system(size: 22, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.5), radius: 6, y: 3)
                        .padding(.top, 12)

                    Button("Back") {
                        path.removeLast()
                    }
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textSecondary)
                    .underline()
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert(alertTitle, isPresented: $showAlert) {
            if pendingUnbalancedContinue {
                Button("Cancel", role: .cancel) { pendingUnbalancedContinue = false }
                Button("Continue") {
                    pendingUnbalancedContinue = false
                    proceedToGame()
                }
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: {
            Text(alertMessage)
        }
    }

    @ViewBuilder
    private func playerCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Player \(index + 1)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if players.count > 4 {
                    Button("Remove") {
                        players.remove(at: index)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.danger.opacity(0.85))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            TextField("Player Name", text: $players[index].name)
                .textInputAutocapitalization(.words)
                .padding(12)
                .background(Color.white.opacity(0.2))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3)))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Team")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Picker("Team", selection: $players[index].team) {
                        Text("Red").tag(TeamColor.red)
                        Text("Blue").tag(TeamColor.blue)
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Role")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                    Picker("Role", selection: $players[index].role) {
                        Text("Encoder").tag(PlayerRole.encoder)
                        Text("Decoder").tag(PlayerRole.decoder)
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding(14)
        .background(Theme.panelFill)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.panelBorder))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func presentAlert(_ title: String, _ message: String) {
        alertTitle = title
        alertMessage = message
        pendingUnbalancedContinue = false
        showAlert = true
    }

    private func randomizeTeams() {
        guard players.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            presentAlert("Enter Names First", "Please enter all player names before randomizing teams.")
            return
        }
        var shuffled = players.shuffled()
        let mid = Int(ceil(Double(shuffled.count) / 2.0))
        for i in shuffled.indices {
            shuffled[i].team = i < mid ? .red : .blue
        }
        players = shuffled
        presentAlert("Teams Randomized!", "Players have been randomly assigned to Red and Blue teams.")
    }

    private func randomizeRoles() {
        guard players.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            presentAlert("Enter Names First", "Please enter all player names before randomizing roles.")
            return
        }
        let red = players.filter { $0.team == .red }
        let blue = players.filter { $0.team == .blue }
        guard !red.isEmpty, !blue.isEmpty else {
            presentAlert("Balance Teams", "Both teams need at least one player before randomizing roles.")
            return
        }
        let redEncoderID = red.shuffled().first!.id
        let blueEncoderID = blue.shuffled().first!.id
        for i in players.indices {
            if players[i].team == .red {
                players[i].role = players[i].id == redEncoderID ? .encoder : .decoder
            } else {
                players[i].role = players[i].id == blueEncoderID ? .encoder : .decoder
            }
        }
        presentAlert("Roles Randomized!", "One Encoder has been selected for each team.")
    }

    private func startGame() {
        guard players.count >= 4 else {
            presentAlert("Not Enough Players", "You need at least 4 players to start (2 per team).")
            return
        }
        guard players.count <= 8 else {
            presentAlert("Too Many Players", "Maximum 8 players allowed.")
            return
        }
        guard players.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            presentAlert("Missing Names", "Please enter names for all players.")
            return
        }

        let red = players.filter { $0.team == .red }
        let blue = players.filter { $0.team == .blue }
        guard !red.isEmpty, !blue.isEmpty else {
            presentAlert("Team Setup", "Both teams need at least one player. Use \"Random Teams\" to auto-balance.")
            return
        }
        guard red.contains(where: { $0.role == .encoder }), red.contains(where: { $0.role == .decoder }) else {
            presentAlert("Team Setup", "Red team needs at least one Encoder and one Decoder.")
            return
        }
        guard blue.contains(where: { $0.role == .encoder }), blue.contains(where: { $0.role == .decoder }) else {
            presentAlert("Team Setup", "Blue team needs at least one Encoder and one Decoder.")
            return
        }

        if abs(red.count - blue.count) > 2 {
            alertTitle = "Unbalanced Teams"
            alertMessage = "Teams are unbalanced (\(red.count) vs \(blue.count)). Continue anyway?"
            pendingUnbalancedContinue = true
            showAlert = true
            return
        }

        proceedToGame()
    }

    private func proceedToGame() {
        let gamePlayers: [Player] = players.enumerated().map { index, setup in
            Player(
                id: "player_\(index + 1)",
                name: setup.name.trimmingCharacters(in: .whitespacesAndNewlines),
                team: setup.team,
                role: setup.role,
                isHost: index == 0
            )
        }

        let settings = GameSettings(
            useTimer: useTimer,
            encoderTimer: useTimer ? timerMinutes * 60 : 60,
            decoderTimer: useTimer ? timerMinutes * 60 : 60,
            teamAssignment: .choose,
            roleAssignment: .choose
        )

        store.initializeNewGame(players: gamePlayers, settings: settings)
        path.append(AppRoute.game)
    }
}

private struct SetupSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Theme.secondary.opacity(configuration.isPressed ? 0.6 : 0.85))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
