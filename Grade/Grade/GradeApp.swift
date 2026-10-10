import SwiftUI

@main
struct GradeApp: App {
    @State private var store = MediaStore()
    @State private var library = LookLibrary()

    var body: some Scene {
        WindowGroup {
            LibraryView()
                .environment(store)
                .environment(library)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}
