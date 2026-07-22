import SwiftUI
import UIKit

struct TrackpadSurface: View {
    @EnvironmentObject private var connection: ConnectionManager
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        GeometryReader { _ in
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
                    Image(systemName: "cursorarrow")
                        .font(.title2)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.35))
                    Text("1 finger move")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.35))
                    Text("2 fingers scroll")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary.opacity(0.28))
                }
                .allowsHitTesting(false)

                TrackpadGestureRepresentable(
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
                        if settings.hapticsEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    },
                    tapToClick: settings.tapToClick,
                    moveSensitivity: settings.trackpadSensitivity,
                    scrollSensitivity: settings.scrollSensitivity,
                    invertScroll: settings.invertScroll
                )
            }
        }
    }
}

private struct TrackpadGestureRepresentable: UIViewRepresentable {
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

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isMultipleTouchEnabled = true

        let movePan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleMovePan(_:))
        )
        movePan.minimumNumberOfTouches = 1
        movePan.maximumNumberOfTouches = 1
        movePan.delegate = context.coordinator

        let scrollPan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleScrollPan(_:))
        )
        scrollPan.minimumNumberOfTouches = 2
        scrollPan.maximumNumberOfTouches = 2
        scrollPan.delegate = context.coordinator

        view.addGestureRecognizer(movePan)
        view.addGestureRecognizer(scrollPan)

        context.coordinator.movePan = movePan
        context.coordinator.scrollPan = scrollPan
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.tapToClick = tapToClick
        context.coordinator.moveSensitivity = moveSensitivity
        context.coordinator.scrollSensitivity = scrollSensitivity
        context.coordinator.invertScroll = invertScroll
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onMove: (Double, Double) -> Void
        let onScroll: (Double, Double) -> Void
        let onTap: () -> Void
        var tapToClick: Bool
        var moveSensitivity: Double
        var scrollSensitivity: Double
        var invertScroll: Bool

        weak var movePan: UIPanGestureRecognizer?
        weak var scrollPan: UIPanGestureRecognizer?

        private var accumulatedMove = CGPoint.zero
        private var lastScrollTranslation = CGPoint.zero

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

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            false
        }

        @objc func handleMovePan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began:
                accumulatedMove = .zero
            case .changed:
                let translation = gesture.translation(in: gesture.view)
                let dx = (translation.x - accumulatedMove.x) * moveSensitivity
                let dy = (translation.y - accumulatedMove.y) * moveSensitivity
                accumulatedMove = translation

                let stepX = Int(dx)
                let stepY = Int(dy)
                if stepX != 0 || stepY != 0 {
                    onMove(Double(stepX), Double(stepY))
                }
            case .ended, .cancelled:
                if tapToClick {
                    let translation = gesture.translation(in: gesture.view)
                    if hypot(translation.x, translation.y) < 8 {
                        onTap()
                    }
                }
                accumulatedMove = .zero
            default:
                break
            }
        }

        @objc func handleScrollPan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began:
                lastScrollTranslation = .zero
            case .changed:
                let translation = gesture.translation(in: gesture.view)
                let deltaX = (translation.x - lastScrollTranslation.x) * scrollSensitivity * 0.08
                let deltaY = (translation.y - lastScrollTranslation.y) * scrollSensitivity * 0.08
                lastScrollTranslation = translation

                let invert = invertScroll ? -1.0 : 1.0
                if deltaX != 0 || deltaY != 0 {
                    onScroll(deltaX, -deltaY * invert)
                }
            case .ended, .cancelled:
                lastScrollTranslation = .zero
            default:
                break
            }
        }
    }
}
