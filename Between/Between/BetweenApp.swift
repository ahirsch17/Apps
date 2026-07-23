import SwiftUI

@main
struct BetweenApp: App {
    @StateObject private var viewModel = AppViewModel.make()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
