import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            BetweenTheme.screenBackground(colorScheme).ignoresSafeArea()

            if viewModel.me == nil {
                AuthFlowView()
            } else {
                TodayView()
            }

            if let toast = viewModel.toastMessage {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(BetweenFont.secondary().weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(BetweenTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(radius: 8, y: 4)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 28)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeOut(duration: 0.25), value: viewModel.toastMessage)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .task {
            await viewModel.bootstrap()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppViewModel.make())
}
