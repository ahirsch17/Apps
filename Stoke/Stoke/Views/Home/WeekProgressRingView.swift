import SwiftUI

struct WeekProgressRingView: View {
    let actualFraction: Double
    /// Use `ProgramStore.paceRingDisplayFraction` so cold starts and slack match messaging.
    let paceDisplayFraction: Double
    let weekPoints: Int
    let periodTarget: Int

    private let size: CGFloat = 200
    private let outerLineWidth: CGFloat = 14
    private let innerLineWidth: CGFloat = 10
    private let ringGap: CGFloat = 4

    var body: some View {
        let paceFrac = max(0, min(1, paceDisplayFraction))
        let actualFrac = max(0, min(1, actualFraction))

        ZStack {
            // Outer pace track ring
            Circle()
                .strokeBorder(
                    StokeTheme.paceTrack,
                    style: StrokeStyle(lineWidth: outerLineWidth, lineCap: .round, lineJoin: .round)
                )

            if paceFrac > 0 {
                Circle()
                    .trim(from: 0, to: paceFrac)
                    .stroke(
                        StokeTheme.paceFill,
                        style: StrokeStyle(
                            lineWidth: outerLineWidth,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .rotationEffect(Angle.degrees(-90))
                    .padding(outerLineWidth / 2)
            }

            Circle()
                .trim(from: 0, to: actualFrac)
                .stroke(
                    StokeTheme.progressFill,
                    style: StrokeStyle(lineWidth: innerLineWidth, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(Angle.degrees(-90))
                .padding(outerLineWidth + ringGap + innerLineWidth / 2)

            VStack(spacing: 4) {
                Text("\(weekPoints)")
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(StokeTheme.ink)
                Text("of \(periodTarget)")
                    .font(.subheadline)
                    .foregroundStyle(StokeTheme.inkMuted)
            }
            .padding(.horizontal, 8)
        }
        .frame(width: size, height: size)
        .drawingGroup()
        .animation(.easeInOut(duration: 0.35), value: actualFrac)
        .animation(.easeInOut(duration: 0.35), value: paceFrac)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(weekPoints) of \(periodTarget) points. Pace ring \(Int(paceFrac * 100)) percent through expected progress today."
        )
    }
}
