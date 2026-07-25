import SwiftUI

struct MediaView: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var volumeLevel: Double = 50
    @State private var volumeBaseline: Double = 50
    @State private var appLaunchMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ConnectionBanner()

                    appsCard
                    volumeCard
                    transportCard

                    if !appLaunchMessage.isEmpty {
                        StatusMessage(text: appLaunchMessage)
                    }
                }
                .padding(16)
            }
            .screenBackground()
            .deskPilotNavigation("Media")
        }
    }

    private var appsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Apps", icon: "apps.ipad")

            HStack(spacing: 12) {
                ForEach(StreamingApp.catalog) { app in
                    appButton(app)
                }
            }
        }
        .padding(16)
        .cardStyle()
    }

    private func appButton(_ app: StreamingApp) -> some View {
        Button {
            connection.send(command: RemoteCommand.launchApp(app.launchName))
            appLaunchMessage = "Opening \(app.title)…"
            Haptics.medium(enabled: settings.hapticsEnabled)
        } label: {
            VStack(spacing: 12) {
                Image(systemName: app.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(app.accent)
                Text(app.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(StreamingAppButtonStyle(accent: app.accent))
        .disabled(!connection.isConnected)
    }

    private var volumeCard: some View {
        VStack(spacing: 18) {
            SectionHeader(title: "Volume", icon: "speaker.wave.2.fill")

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

            Button {
                connection.send(command: RemoteCommand.volume(action: "mute"))
                Haptics.medium(enabled: settings.hapticsEnabled)
            } label: {
                Label("Mute", systemImage: "speaker.slash.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!connection.isConnected)
        }
        .padding(16)
        .cardStyle()
    }

    private func volumeStepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.light(enabled: settings.hapticsEnabled)
        } label: {
            Image(systemName: systemName)
        }
        .buttonStyle(IconButtonStyle())
        .disabled(!connection.isConnected)
    }

    private var transportCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Playback", icon: "play.circle.fill")

            HStack(spacing: 12) {
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
        }
        .padding(16)
        .cardStyle()
    }

    private func mediaButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.medium(enabled: settings.hapticsEnabled)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(AppTheme.accent)
                Text(label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 76)
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
}

#Preview {
    MediaView()
        .environmentObject(ConnectionManager())
        .environmentObject(SettingsStore())
}
