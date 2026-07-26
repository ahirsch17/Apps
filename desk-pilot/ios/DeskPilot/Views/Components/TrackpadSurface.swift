import SwiftUI
import UIKit

struct TrackpadSurface: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        GeometryReader { _ in
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.cardHighlight, AppTheme.card.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(trackpadGrid)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                            .stroke(
                                connection.isConnected ? AppTheme.accent.opacity(0.22) : AppTheme.cardBorder,
                                lineWidth: 1
                            )
                    )

                VStack(spacing: 6) {
                    Image(systemName: "cursorarrow.rays")
                        .font(.title2)
                        .foregroundStyle(AppTheme.textTertiary)
                    Text("Move · Tap · Scroll")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(AppTheme.textTertiary)
                }
                .allowsHitTesting(false)
                .opacity(connection.isConnected ? 0.55 : 0.25)

                TrackpadTouchRepresentable(
                    onMove: { dx, dy in
                        guard connection.isConnected else { return }
                        connection.send(command: RemoteCommand.mouseMove(dx: dx, dy: dy))
                    },
                    onScroll: { dx, dy in
                        guard connection.isConnected else { return }
                        connection.send(command: RemoteCommand.scroll(dx: dx, dy: dy))
                    },
                    onTap: {
                        guard connection.isConnected else { return }
                        connection.send(command: RemoteCommand.mouseClick(button: "left"))
                        Haptics.light(enabled: settings.hapticsEnabled)
                    },
                    tapToClick: settings.tapToClick,
                    moveSensitivity: settings.trackpadSensitivity,
                    scrollSensitivity: settings.scrollSensitivity,
                    invertScroll: settings.invertScroll
                )
            }
        }
    }

    private var trackpadGrid: some View {
        Canvas { context, size in
            let spacing: CGFloat = 28
            var path = Path()
            stride(from: spacing, to: size.width, by: spacing).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: spacing, to: size.height, by: spacing).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(AppTheme.textTertiary.opacity(0.08)), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous))
    }
}

private struct TrackpadTouchRepresentable: UIViewRepresentable {
    let onMove: (Double, Double) -> Void
    let onScroll: (Double, Double) -> Void
    let onTap: () -> Void
    let tapToClick: Bool
    let moveSensitivity: Double
    let scrollSensitivity: Double
    let invertScroll: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onMove: onMove,
            onScroll: onScroll,
            onTap: onTap,
            tapToClick: tapToClick,
            moveSensitivity: moveSensitivity,
            scrollSensitivity: scrollSensitivity,
            invertScroll: invertScroll
        )
    }

    func makeUIView(context: Context) -> TrackpadTouchView {
        let view = TrackpadTouchView()
        view.coordinator = context.coordinator
        view.isMultipleTouchEnabled = true
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ uiView: TrackpadTouchView, context: Context) {
        uiView.coordinator = context.coordinator
        context.coordinator.tapToClick = tapToClick
        context.coordinator.moveSensitivity = moveSensitivity
        context.coordinator.scrollSensitivity = scrollSensitivity
        context.coordinator.invertScroll = invertScroll
    }

    final class Coordinator {
        let onMove: (Double, Double) -> Void
        let onScroll: (Double, Double) -> Void
        let onTap: () -> Void
        var tapToClick: Bool
        var moveSensitivity: Double
        var scrollSensitivity: Double
        var invertScroll: Bool

        private var pendingMove = CGPoint.zero
        private var lastScrollCenter: CGPoint?

        init(
            onMove: @escaping (Double, Double) -> Void,
            onScroll: @escaping (Double, Double) -> Void,
            onTap: @escaping () -> Void,
            tapToClick: Bool,
            moveSensitivity: Double,
            scrollSensitivity: Double,
            invertScroll: Bool
        ) {
            self.onMove = onMove
            self.onScroll = onScroll
            self.onTap = onTap
            self.tapToClick = tapToClick
            self.moveSensitivity = moveSensitivity
            self.scrollSensitivity = scrollSensitivity
            self.invertScroll = invertScroll
        }

        func sendMove(dx: CGFloat, dy: CGFloat) {
            pendingMove.x += dx * moveSensitivity
            pendingMove.y += dy * moveSensitivity

            let stepX = Int(pendingMove.x)
            let stepY = Int(pendingMove.y)
            if stepX != 0 || stepY != 0 {
                onMove(Double(stepX), Double(stepY))
                pendingMove.x -= Double(stepX)
                pendingMove.y -= Double(stepY)
            }
        }

        func sendScroll(at center: CGPoint) {
            guard let previous = lastScrollCenter else {
                lastScrollCenter = center
                return
            }

            let deltaX = (center.x - previous.x) * scrollSensitivity * 0.08
            let deltaY = (center.y - previous.y) * scrollSensitivity * 0.08
            lastScrollCenter = center

            let invert = invertScroll ? -1.0 : 1.0
            if deltaX != 0 || deltaY != 0 {
                onScroll(deltaX, -deltaY * invert)
            }
        }

        func resetScroll() {
            lastScrollCenter = nil
        }

        func resetMove() {
            pendingMove = .zero
        }
    }
}

private final class TrackpadTouchView: UIView {
    weak var coordinator: TrackpadTouchRepresentable.Coordinator?

    private var activeMoveTouch: UITouch?
    private var moveStartPoint: CGPoint = .zero
    private var lastMovePoint: CGPoint = .zero
    private var didMove = false

    private var scrollTouches: [UITouch] = []
    private var didScrollSession = false

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let event else { return }
        didScrollSession = false
        let allTouches = event.allTouches?.filter { $0.view == self } ?? Array(touches)

        if allTouches.count >= 2 {
            beginScroll(with: allTouches)
            return
        }

        guard activeMoveTouch == nil, let touch = touches.first else { return }
        activeMoveTouch = touch
        moveStartPoint = touch.location(in: self)
        lastMovePoint = moveStartPoint
        didMove = false
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let event, let coordinator else { return }
        let allTouches = event.allTouches?.filter { $0.view == self } ?? Array(touches)

        if scrollTouches.count >= 2 || allTouches.count >= 2 {
            updateScroll(with: allTouches)
            return
        }

        guard let touch = activeMoveTouch, touches.contains(touch) else { return }
        let point = touch.location(in: self)
        let dx = point.x - lastMovePoint.x
        let dy = point.y - lastMovePoint.y

        if hypot(point.x - moveStartPoint.x, point.y - moveStartPoint.y) > 6 {
            didMove = true
        }

        coordinator.sendMove(dx: dx, dy: dy)
        lastMovePoint = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let coordinator else { return }

        if scrollTouches.contains(where: { touches.contains($0) }) {
            scrollTouches.removeAll { touches.contains($0) }
            if scrollTouches.count < 2 {
                scrollTouches.removeAll()
                coordinator.resetScroll()
            }
            return
        }

        guard let touch = activeMoveTouch, touches.contains(touch) else { return }
        if coordinator.tapToClick && !didMove && !didScrollSession {
            coordinator.onTap()
        }

        activeMoveTouch = nil
        didMove = false
        coordinator.resetMove()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }

    private func beginScroll(with touches: [UITouch]) {
        activeMoveTouch = nil
        didMove = true
        didScrollSession = true
        scrollTouches = Array(touches.prefix(2))
        coordinator?.resetScroll()
        coordinator?.resetMove()
    }

    private func updateScroll(with touches: [UITouch]) {
        guard let coordinator, touches.count >= 2 else { return }

        if scrollTouches.count < 2 {
            beginScroll(with: touches)
            return
        }

        let center = averagePoint(for: Array(touches.prefix(2)))
        coordinator.sendScroll(at: center)
    }

    private func averagePoint(for touches: [UITouch]) -> CGPoint {
        guard !touches.isEmpty else { return .zero }
        let points = touches.map { $0.location(in: self) }
        let sum = points.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
        return CGPoint(x: sum.x / CGFloat(points.count), y: sum.y / CGFloat(points.count))
    }
}
