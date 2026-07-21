import SwiftUI
import UIKit

struct TrackpadSurface: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    @Binding var scrollMode: Bool

    @State private var lastLocation: CGPoint?
    @State private var accumulatedDelta = CGSize.zero

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppTheme.card,
                                AppTheme.card.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius)
                            .stroke(AppTheme.accent.opacity(0.15), lineWidth: 1)
                    )

                VStack(spacing: 8) {
                    Image(systemName: scrollMode ? "arrow.up.and.down" : "cursorarrow")
                        .font(.title2)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.35))
                    Text(scrollMode ? "Scroll mode" : "Trackpad")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.35))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(value, in: geo.size)
                    }
                    .onEnded { value in
                        handleEnd(value)
                    }
            )
        }
    }

    private func handleDrag(_ value: DragGesture.Value, in size: CGSize) {
        guard connection.isConnected else { return }

        if scrollMode {
            let scrollDy = value.translation.height * settings.scrollSensitivity * 0.08
            let scrollDx = value.translation.width * settings.scrollSensitivity * 0.08
            let invert = settings.invertScroll ? -1.0 : 1.0
            connection.send(command: RemoteCommand.scroll(dx: scrollDx, dy: -scrollDy * invert))
            return
        }

        if let last = lastLocation {
            let dx = (value.location.x - last.x) * settings.trackpadSensitivity
            let dy = (value.location.y - last.y) * settings.trackpadSensitivity
            accumulatedDelta.width += dx
            accumulatedDelta.height += dy

            let stepX = Int(accumulatedDelta.width)
            let stepY = Int(accumulatedDelta.height)
            if stepX != 0 || stepY != 0 {
                connection.send(command: RemoteCommand.mouseMove(dx: Double(stepX), dy: Double(stepY)))
                accumulatedDelta.width -= Double(stepX)
                accumulatedDelta.height -= Double(stepY)
            }
        }
        lastLocation = value.location
    }

    private func handleEnd(_ value: DragGesture.Value) {
        if !scrollMode && settings.tapToClick {
            let dist = hypot(value.translation.width, value.translation.height)
            if dist < 8 {
                click(button: "left")
            }
        }
        lastLocation = nil
        accumulatedDelta = .zero
    }

    private func click(button: String) {
        connection.send(command: RemoteCommand.mouseClick(button: button))
        if button == "left" {
            connection.requestKeyboard()
        }
        if settings.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
