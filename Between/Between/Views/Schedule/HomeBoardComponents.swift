import SwiftUI

/// Bottom inset for status controls — flat surface + hairline, no floating shadow.
struct BoardStatusDock<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)
            .background(BetweenTheme.surface(colorScheme).ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) {
                Divider()
            }
    }
}
