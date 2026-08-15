import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var page = 0

    private let pages: [(icon: String, title: String, body: String)] = [
        ("mic.fill", "Speak without freezing", "A tutor walks you through real conversation — starters, Stuck help, and corrections when you’re ready."),
        ("rectangle.stack.fill", "Free, offline practice", "Word bank + phrase drills work today with no API key. Listen, then say it out loud."),
        ("sparkles", "AI Chat is optional", "When you want live conversation, add a cheap OpenAI key in Profile. Until then, Learn is fully usable.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(SFTheme.accent.opacity(0.15))
                                .frame(width: 120, height: 120)
                            Image(systemName: pages[index].icon)
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundStyle(SFTheme.accent)
                        }
                        Text(pages[index].title)
                            .font(.title.bold())
                            .multilineTextAlignment(.center)
                        Text(pages[index].body)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .frame(height: 420)

            Spacer()

            Button {
                if page < pages.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    settings.hasSeenWelcome = true
                }
            } label: {
                Text(page == pages.count - 1 ? "Start practicing" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)

            Button("Skip") { settings.hasSeenWelcome = true }
                .font(.subheadline)
                .padding(.vertical, 16)
        }
        .background(Color(.systemBackground))
    }
}
