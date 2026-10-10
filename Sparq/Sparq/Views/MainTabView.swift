import SwiftUI

enum SparqTab: Hashable {
    case forYou, discover, myWeek, friends
}

struct MainTabView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var tab: SparqTab = .forYou
    @State private var showPost = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .forYou: ForYouTabView()
                case .discover: DiscoverTabView()
                case .myWeek: MyWeekTabView()
                case .friends: MessagesTabView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomBar
        }
        .background(SparqTheme.screenBackground(colorScheme).ignoresSafeArea())
        .sheet(isPresented: $showPost) {
            PostEventSheet()
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 0) {
            tabButton(.forYou, icon: "sparkles", label: "For You")
            tabButton(.discover, icon: "magnifyingglass", label: "Discover")
            centerAction
            tabButton(.myWeek, icon: "bookmark.fill", label: "My Week")
            tabButton(.friends, icon: "person.2.fill", label: "Friends", badge: viewModel.notificationCount)
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(SparqTheme.surface(colorScheme).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Divider() }
    }

    private func tabButton(_ value: SparqTab, icon: String, label: String, badge: Int = 0) -> some View {
        Button {
            tab = value
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: tab == value ? .semibold : .regular))
                    if badge > 0 {
                        Circle()
                            .fill(SparqTheme.accentAction)
                            .frame(width: 8, height: 8)
                            .offset(x: 6, y: -2)
                    }
                }
                Text(label)
                    .font(.caption2.weight(tab == value ? .semibold : .medium))
            }
            .foregroundStyle(tab == value ? SparqTheme.accent : Color.secondary)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var centerAction: some View {
        Button { showPost = true } label: {
            Image(systemName: "plus")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(SparqTheme.accent)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .offset(y: -10)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Post an event")
    }
}
