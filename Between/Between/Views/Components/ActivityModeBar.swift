import SwiftUI

struct ActivityModeBar: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    var activeMode: ActivityMode? { viewModel.eventsData?.activeMode }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "What's the vibe?", subtitle: "Friends in the same mode can find you")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ActivityMode.allCases) { mode in
                        modeChip(mode)
                    }
                }
            }
        }
    }

    private func modeChip(_ mode: ActivityMode) -> some View {
        let selected = activeMode == mode
        return Button {
            Task { await viewModel.setActivityMode(mode) }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                Text(mode.label)
                    .font(BetweenFont.captionMedium())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(selected ? BetweenTheme.accent : BetweenTheme.surfaceMuted(colorScheme))
            .foregroundStyle(selected ? .white : .primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
