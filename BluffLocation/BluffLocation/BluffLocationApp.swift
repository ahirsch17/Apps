import SwiftUI

@main
struct BluffLocationApp: App {
  @StateObject private var store = BluffLocationStore()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(store)
    }
  }
}

struct RootView: View {
  var body: some View {
    NavigationView {
      MainMenuView()
    }
    .navigationViewStyle(.stack)
  }
}

