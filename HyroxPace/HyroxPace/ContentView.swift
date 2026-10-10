import SwiftUI

struct ContentView: View {
    @StateObject private var engine = RaceEngine()

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Estimate — quiet, one number
                Text(engine.estimateText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(estimateColor)
                    .monospacedDigit()
                    .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                // Station + progress — the only thing you really need
                VStack(spacing: 2) {
                    Text(engine.stationTitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(engine.centerText)
                        .font(.system(size: centerFontSize, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity)

                Spacer(minLength: 0)

                // One line: who's next / how far — no box, no labels
                Text(handoffLine)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .frame(maxWidth: .infinity)
                    .frame(height: 18)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { engine.handleTap() }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.55)
                .onEnded { _ in engine.handleTap() }
        )
    }

    /// One glanceable line. During work: next person/station. During buffer: who opens.
    private var handoffLine: String {
        if engine.phase == .idle {
            return "Hold or double-tap"
        }
        if case .redAlert = engine.phase {
            return "Hold or double-tap"
        }

        let preferActive: Bool
        if case .buffering = engine.phase {
            preferActive = true
        } else {
            preferActive = false
        }

        if preferActive, let active = engine.activeSlot {
            return formatSlot(active)
        }
        if let upcoming = engine.upcomingSlot {
            return formatSlot(upcoming)
        }
        if let active = engine.activeSlot {
            return formatSlot(active)
        }
        return " "
    }

    private func formatSlot(_ slot: HandoffSlot) -> String {
        if slot.subtitle.isEmpty { return slot.title }
        return "\(slot.title)  \(slot.subtitle)"
    }

    private var background: Color {
        engine.isFlashingRed ? .red : .black
    }

    private var estimateColor: Color {
        if engine.isFlashingRed { return .white }
        switch engine.estimateStatus {
        case .ahead: return Color(red: 0.45, green: 0.92, blue: 0.55)
        case .behind: return Color(red: 1.0, green: 0.5, blue: 0.45)
        case .onPace: return .white.opacity(0.55)
        }
    }

    private var centerFontSize: CGFloat {
        if case .buffering = engine.phase { return 38 }
        if engine.phase == .idle || engine.phase == .finished { return 32 }
        let n = engine.centerText.count
        if n >= 9 { return 30 }
        if n >= 6 { return 36 }
        return 44
    }
}

#Preview {
    ContentView()
}
