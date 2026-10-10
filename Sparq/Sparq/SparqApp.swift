import SwiftUI

@main
struct SparqApp: App {
    @StateObject private var viewModel = AppViewModel.make()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .tint(SparqTheme.accent)
        }
    }
}
