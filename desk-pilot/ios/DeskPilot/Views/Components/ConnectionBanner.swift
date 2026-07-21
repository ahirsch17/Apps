import SwiftUI

struct ConnectionBanner: View {
    @EnvironmentObject private var connection: ConnectionManager

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(statusText)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)

            Spacer()

            if connection.isConnected, !connection.serverName.isEmpty {
                Text(connection.serverName)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.card.opacity(0.85))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppTheme.cardBorder, lineWidth: 1))
    }

    private var statusColor: Color {
        switch connection.state {
        case .connected: return AppTheme.success
        case .connecting, .pairing: return AppTheme.warning
        case .disconnected: return AppTheme.textSecondary
        case .error: return AppTheme.danger
        }
    }

    private var statusText: String {
        switch connection.state {
        case .connected: return "Connected"
        case .connecting: return "Connecting…"
        case .pairing: return "Pairing…"
        case .disconnected: return "Not connected"
        case .error(let message): return message
        }
    }
}
