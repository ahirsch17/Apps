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
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.88))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
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
