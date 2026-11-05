import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var page = 0

    private let pages: [(String, String)] = [
        ("Hear it, then say it", "Three clean answers check a line off. A miss comes back after the set, and only a real answer counts."),
        ("Then answer out loud", "The same lines come back as questions. You reply. The ones you miss are asked again."),
        ("The path keeps the count", "Each language saves its own phrases and conversations. Call opens after four of them.")
    ]

    var body: some View {
        ZStack {
            SF.ink.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("SpeakFlow")
                    .font(SF.display(42))
                    .foregroundStyle(.white)
                    .padding(.top, 36)
                    .padding(.horizontal, 24)

                TabView(selection: $page) {
                    ForEach(pages.indices, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 14) {
                            Text(String(format: "%02d", i + 1))
                                .font(SF.display(48))
                                .foregroundStyle(SF.coral)
                            Text(pages[i].0)
                                .font(SF.displayItalic(32))
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(pages[i].1)
                                .font(SF.ui(17))
                                .foregroundStyle(.white.opacity(0.72))
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Button(page == pages.count - 1 ? "Start speaking" : "Next") {
                    if page < pages.count - 1 { page += 1 }
                    else { settings.hasSeenWelcome = true }
                }
                .buttonStyle(StampButton())
                .padding(.horizontal, 24)
                .padding(.top, 8)

                Button("Skip") { settings.hasSeenWelcome = true }
                    .font(SF.ui(16))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
            }
        }
    }
}
