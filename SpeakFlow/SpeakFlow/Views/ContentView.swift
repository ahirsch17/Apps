import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var vocabulary: VocabularyStore
    @StateObject private var conversation = ConversationViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            LearnView()
                .tabItem { Label("Learn", systemImage: "rectangle.stack.fill") }
                .tag(0)

            ChatView(viewModel: conversation, onOpenProfile: { selectedTab = 2 })
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(1)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
                .tag(2)
        }
        .onAppear {
            conversation.bind(settings: settings, vocabulary: vocabulary)
        }
        .task { await conversation.onAppear() }
    }
}
