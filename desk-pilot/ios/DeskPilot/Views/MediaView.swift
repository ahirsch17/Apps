import SwiftUI
import UIKit

struct MediaView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var volumeLevel: Double = 50
    @State private var volumeBaseline: Double = 50
    @State private var appLaunchMessage = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ConnectionBanner()

                appsCard
                volumeCard
                transportCard

                if !appLaunchMessage.isEmpty {
                    Text(appLaunchMessage)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding(16)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Media")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var appsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Apps")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 12) {
                appButton(title: "Netflix", icon: "play.tv.fill", appName: PCDefaults.netflixApp)
                appButton(title: "Prime Video", icon: "film.fill", appName: PCDefaults.primeVideoApp)
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func appButton(title: String, icon: String, appName: String) -> some View {
        Button {
            connection.send(command: RemoteCommand.launchApp(appName))
            appLaunchMessage = "Opening \(title)…"
            haptic()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 96)
        }
        .buttonStyle(TileButtonStyle())
        .disabled(!connection.isConnected)
    }

    private var volumeCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.accent)
                .padding(.top, 8)

            Text("Volume")
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppTheme.textPrimary)

            HStack(spacing: 10) {
                volumeStepButton(systemName: "minus") {
                    connection.send(command: RemoteCommand.volume(action: "down", steps: 2))
                    volumeLevel = max(0, volumeLevel - 5)
                }

                Slider(value: $volumeLevel, in: 0...100, step: 5) { editing in
                    if !editing {
                        sendVolumeDelta()
                    }
                }
                .tint(AppTheme.accent)
                .layoutPriority(1)

                volumeStepButton(systemName: "plus") {
                    connection.send(command: RemoteCommand.volume(action: "up", steps: 2))
                    volumeLevel = min(100, volumeLevel + 5)
                }
            }

            Button("Mute") {
                connection.send(command: RemoteCommand.volume(action: "mute"))
                haptic()
            }
            .buttonStyle(PrimaryButtonStyle(isActive: true))
            .disabled(!connection.isConnected)
        }
        .padding(20)
        .cardStyle()
    }

    private func volumeStepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            haptic()
        } label: {
            Image(systemName: systemName)
                .font(.body.weight(.semibold))
                .frame(width: 32, height: 44)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!connection.isConnected)
    }

    private var transportCard: some View {
        HStack(spacing: 16) {
            mediaButton(icon: "backward.fill", label: "Prev") {
                connection.send(command: RemoteCommand.media(action: "prev"))
            }

            mediaButton(icon: "playpause.fill", label: "Play") {
                connection.send(command: RemoteCommand.media(action: "play_pause"))
            }

            mediaButton(icon: "forward.fill", label: "Next") {
                connection.send(command: RemoteCommand.media(action: "next"))
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func mediaButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            haptic()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 80)
        }
        .buttonStyle(TileButtonStyle())
        .disabled(!connection.isConnected)
    }

    private func sendVolumeDelta() {
        let delta = Int((volumeLevel - volumeBaseline) / 5)
        guard delta != 0 else { return }
        let action = delta > 0 ? "up" : "down"
        connection.send(command: RemoteCommand.volume(action: action, steps: abs(delta)))
        volumeBaseline = volumeLevel
    }

    private func haptic() {
        if settings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
}

#Preview {
    MediaView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
