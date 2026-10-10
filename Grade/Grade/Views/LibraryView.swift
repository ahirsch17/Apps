import PhotosUI
import SwiftUI

struct LibraryView: View {
    @Environment(MediaStore.self) private var store
    @Environment(LookLibrary.self) private var library
    @State private var picks: [PhotosPickerItem] = []
    @State private var toast: String?
    @State private var saving = false
    @State private var confirmingRemoveAll = false

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
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Menu {
                            if let copied = store.copiedEdit {
                                Button("Paste edit to all", systemImage: "doc.on.clipboard") {
                                    store.pasteToAll(copied, library: library)
                                    toast = "Pasted to \(store.items.count) photos"
                                }
                            }
                            Button("Remove all", systemImage: "trash", role: .destructive) {
                                confirmingRemoveAll = true
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        picker { Image(systemName: "plus") }
                    }
                }
            }
            .toast($toast)
            .confirmationDialog("Remove all photos from Grade?", isPresented: $confirmingRemoveAll, titleVisibility: .visible) {
                Button("Remove all", role: .destructive) { store.removeAll() }
            } message: {
                Text("Your originals in Photos aren't touched. Unsaved edits are lost.")
            }
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
                Text("Pick a look, fix the light, then fine-tune any color: whiter teeth, bluer water, greener grass, without the fake filter feel. Edit one shot and paste it onto the whole set.")
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
                        Button("Copy edit", systemImage: "doc.on.doc") {
                            store.copyEdit(from: item)
                            toast = "Edit copied"
                        }
                        .disabled(!item.edit.isEdited)
                        if let copied = store.copiedEdit {
                            Button("Paste edit", systemImage: "doc.on.clipboard") {
                                store.paste(copied, onto: item, library: library)
                            }
                        }
                        Button("Use this edit on all", systemImage: "square.stack.3d.down.right") {
                            store.pasteToAll(item.edit.transferable(), except: item, library: library)
                            toast = "Applied to \(store.items.count - 1) more"
                        }
                        .disabled(!item.edit.isEdited || store.items.count < 2)
                        Button("Remove", systemImage: "trash", role: .destructive) { store.remove(item) }
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
