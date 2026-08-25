import SwiftUI

struct ConnectionBanner: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @State private var pulse = false

    var body: some View {
        Button {
            Task { await connection.bootstrap(settings: settings, force: true) }
        } label: {
            HStack(spacing: 10) {
                statusDot

                VStack(alignment: .leading, spacing: 2) {
                    Text(statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusTextColor)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if connection.isConnected, !connection.serverName.isEmpty {
                        Text(connection.serverName)
                            .font(.caption2)
                            .foregroundStyle(AppTheme.textTertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                if !connection.isConnected {
                    Text("Retry")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.accentMuted)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.card.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(statusBorderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onAppear { pulse = isAnimating }
        .onChange(of: isAnimating) { _, animating in
            withAnimation(animating ? .easeInOut(duration: 0.9).repeatForever(autoreverses: true) : .default) {
                pulse = animating
            }
        }
    }

    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 10, height: 10)
            .overlay(
                Circle()
                    .stroke(statusColor.opacity(pulse ? 0.15 : 0.45), lineWidth: pulse ? 6 : 2)
            )
    }

    private var isAnimating: Bool {
        if connection.isBusyConnecting { return true }
        if case .error(let message) = connection.state, message.contains("Reconnecting") {
            return true
        }
        return false
    }

    private var statusBorderColor: Color {
        switch connection.state {
        case .connected: return AppTheme.success.opacity(0.35)
        case .connecting, .pairing: return AppTheme.warning.opacity(0.35)
        case .error: return AppTheme.danger.opacity(0.35)
        case .disconnected: return AppTheme.cardBorder
        }
    }

    private var statusColor: Color {
        switch connection.state {
        case .connected: return AppTheme.success
        case .connecting, .pairing: return AppTheme.warning
        case .disconnected: return AppTheme.textTertiary
        case .error: return AppTheme.danger
        }
    }

    private var statusTextColor: Color {
        if case .error = connection.state { return AppTheme.danger }
        return AppTheme.textPrimary
    }

    private var statusText: String {
        switch connection.state {
        case .connected: return "Connected to PC"
        case .pairing: return "Pairing…"
        case .connecting: return "Connecting…"
        case .disconnected: return "Not connected"
        case .error(let message):
            if message.contains("Reconnecting") { return "Reconnecting…" }
            return message
        }
    }
}
