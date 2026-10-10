import PhotosUI
import SwiftUI

struct LibraryView: View {
    @Environment(MediaStore.self) private var store
    @Environment(LookLibrary.self) private var library
    @State private var picks: [PhotosPickerItem] = []
    @State private var toast: String?
    @State private var saving = false

    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 4)]

    var body: some View {
        NavigationStack {
            Group {
                if store.items.isEmpty && store.importing == 0 {
                    emptyState
                } else {
                    grid
                }
            }
            .navigationTitle("Grade")
            .navigationDestination(for: MediaItem.ID.self) { id in
                if let item = store.items.first(where: { $0.id == id }) {
                    EditorView(item: item, library: library)
                }
            }
            .toolbar {
                if !store.items.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Save all") { saveAll() }
                            .disabled(!store.items.contains(where: { $0.edit.isEdited }) || saving)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        picker { Image(systemName: "plus") }
                    }
                }
            }
            .toast($toast)
            .overlay {
                if let label = store.progressLabel {
                    BusyOverlay(label: label, progress: store.progress)
                }
            }
        }
        .onChange(of: picks) { _, newValue in
            guard !newValue.isEmpty else { return }
            Task {
                await store.add(newValue)
                picks = []
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "camera.filters")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(Theme.accent)
            VStack(spacing: 8) {
                Text("Color grade your photos and videos")
                    .font(.title3.weight(.semibold))
                Text("Pick a look, then fine-tune any color: whiter teeth, bluer water, greener grass, without the fake filter feel.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            picker {
                Label("Add photos & videos", systemImage: "photo.on.rectangle.angled")
                    .font(.headline)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(Theme.accent, in: Capsule())
                    .foregroundStyle(.black)
            }
            Spacer()
            Spacer()
        }
        .padding(32)
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(store.items) { item in
                    NavigationLink(value: item.id) {
                        Thumbnail(item: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Use this look on all") {
                            store.applyLook(from: item, library: library)
                        }
                        .disabled(!item.edit.isEdited)
                        Button("Remove", role: .destructive) { store.remove(item) }
                    }
                }
                ForEach(0..<store.importing, id: \.self) { _ in
                    Theme.card
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(ProgressView())
                }
            }
            .padding(4)
        }
    }

    private func picker<Content: View>(@ViewBuilder label: () -> Content) -> some View {
        PhotosPicker(
            selection: $picks,
            maxSelectionCount: 40,
            matching: .any(of: [.images, .videos]),
            preferredItemEncoding: .current,
            label: label
        )
    }

    private func saveAll() {
        saving = true
        Task {
            let result = await store.saveAllEdited(library: library)
            saving = false
            if result.failed > 0 {
                toast = "Saved \(result.saved), \(result.failed) failed"
            } else {
                toast = "Saved \(result.saved) to Photos"
            }
        }
    }
}

private struct Thumbnail: View {
    let item: MediaItem

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Image(uiImage: item.displayThumbnail)
                    .resizable()
                    .scaledToFill()
            )
            .clipped()
            .overlay(alignment: .bottomLeading) {
                HStack(spacing: 4) {
                    if item.kind == .video {
                        Image(systemName: "video.fill")
                        Text(Duration.seconds(item.duration).formatted(.time(pattern: .minuteSecond)))
                    }
                    Spacer()
                    if item.edit.isEdited {
                        Image(systemName: "wand.and.stars")
                    }
                }
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white)
                .shadow(radius: 2)
                .padding(6)
            }
    }
}
