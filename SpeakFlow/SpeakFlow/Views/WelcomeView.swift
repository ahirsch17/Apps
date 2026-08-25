import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var page = 0

    private let pages: [(String, String, String)] = [
        ("phone.fill", "Talk like it's a real call", "No record button. Just speak — it knows when you're done. Fail out loud. That's how it sticks."),
        ("message.fill", "Or text your tutor", "Same character, chat style. Corrections show up right on your bubbles."),
        ("flame.fill", "Learn free, unlock Call later", "Level-based practice with zero API key. When you're ready, paste a key in Profile and Call/Text turn on.")
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [SF.tealDeep, Color.black], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                Text("SpeakFlow")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(spacing: 18) {
                            ZStack {
                                Circle().fill(SF.teal.opacity(0.25)).frame(width: 110, height: 110)
                                Image(systemName: pages[i].0)
                                    .font(.system(size: 40, weight: .semibold))
                                    .foregroundStyle(SF.mint)
                            }
                            Text(pages[i].1)
                                .font(.system(.title2, design: .rounded).weight(.bold))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white)
                            Text(pages[i].2)
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        }
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 360)

                Spacer()

                Button {
                    if page < pages.count - 1 { withAnimation { page += 1 } }
                    else { settings.hasSeenWelcome = true }
                } label: {
                    Text(page == pages.count - 1 ? "Let's go" : "Next")
                        .font(.system(.headline, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(SF.coral)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)

                Button("Skip") { settings.hasSeenWelcome = true }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.vertical, 16)
            }
        }
    }
}
