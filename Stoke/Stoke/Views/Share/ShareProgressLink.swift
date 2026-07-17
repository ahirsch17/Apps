import SwiftUI

/// Shares only the branded Stoke card image (no caption text).
struct ShareProgressLink<Label: View>: View {
    @Environment(ProgramStore.self) private var programStore
    @ViewBuilder var label: () -> Label

    @State private var shareImage: Image?
    @State private var useTextOnly = false

    var body: some View {
        Group {
            if useTextOnly {
                ShareLink(item: "Stoke weekly progress") {
                    label()
                }
            } else if let shareImage {
                ShareLink(
                    item: shareImage,
                    preview: SharePreview("Stoke Weekly Snapshot", image: shareImage)
                ) {
                    label()
                }
            } else {
                Button {
                    prepareShare()
                } label: {
                    label()
                }
            }
        }
        .task {
            prepareShare()
        }
    }

    @MainActor
    private func prepareShare() {
        if let ui = programStore.shareProgressUIImage() {
            shareImage = Image(uiImage: ui)
            useTextOnly = false
        } else {
            shareImage = nil
            useTextOnly = true
        }
    }
}
