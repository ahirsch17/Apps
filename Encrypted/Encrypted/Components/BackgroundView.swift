import SwiftUI

struct BackgroundView<Content: View>: View {
    let imageName: String
    var overlayOpacity: Double = 0.55
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            Color.black.opacity(overlayOpacity)
                .ignoresSafeArea()

            content()
        }
    }
}
