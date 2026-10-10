import PhotosUI
import SwiftUI

struct LooksPanel: View {
    @Bindable var session: EditSession
    @State private var importing = false
    @State private var renaming: Look?
    @State private var newName = ""

    private var library: LookLibrary { session.library }

    private var isMatched: Bool {
        if case .match = session.edit.base { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 10) {
                    Button { session.choose(.original) } label: {
                        LookTile(name: "Original", image: session.original, selected: session.edit.base == .original)
                    }

                    if isMatched {
                        LookTile(name: "Matched", image: session.preview, selected: true)
                    }

                    ForEach(library.custom) { look in
                        tile(look)
                            .contextMenu {
                                Button("Rename") {
                                    newName = look.name
                                    renaming = look
                                }
                                Button("Delete", role: .destructive) {
                                    if session.edit.base == .look(look.id) { session.choose(.original) }
                                    library.delete(look)
                                }
                            }
                    }

                    ForEach(library.builtIns) { look in
                        tile(look)
                    }

                    Button { importing = true } label: {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                .foregroundStyle(.secondary)
                                .frame(width: 72, height: 72)
                                .overlay(Image(systemName: "square.and.arrow.down").foregroundStyle(.secondary))
                            Text("Import .cube").font(.caption2).frame(width: 76)
                        }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
            .frame(height: 100)

            VStack(spacing: 10) {
                if session.edit.base != .original {
                    LabeledSlider(
                        title: "Strength",
                        value: $session.edit.strength,
                        range: 0...1,
                        neutral: 1,
                        format: { "\(Int(($0 * 100).rounded()))%" }
                    )
                }
                Toggle(isOn: $session.edit.protectSkin) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Protect skin tones").font(.subheadline)
                        Text("Keeps faces natural under strong looks").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal)
            Spacer(minLength: 0)
        }
        .padding(.top, 14)
        .fileImporter(isPresented: $importing, allowedContentTypes: CubeFile.contentTypes) { result in
            if case .success(let url) = result {
                session.importCube(url)
            }
        }
        .alert("Rename look", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Name", text: $newName)
            Button("Save") {
                if let look = renaming { library.rename(look, to: newName) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func tile(_ look: Look) -> some View {
        Button { session.choose(.look(look.id)) } label: {
            LookTile(name: look.name, image: session.lookThumbs[look.id], selected: session.edit.base == .look(look.id))
        }
    }
}

struct TunePanel: View {
    @Bindable var session: EditSession

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                LabeledSlider(title: "Brightness", value: $session.edit.tune.brightness)
                LabeledSlider(title: "Contrast", value: $session.edit.tune.contrast)
                LabeledSlider(title: "Warmth", value: $session.edit.tune.warmth)
                LabeledSlider(title: "Tint", value: $session.edit.tune.tint)
                LabeledSlider(
                    title: "Saturation",
                    value: $session.edit.tune.saturation,
                    range: 0...2,
                    neutral: 1,
                    format: { String(format: "%+.0f", ($0 - 1) * 100) }
                )
                LabeledSlider(title: "Vibrance", value: $session.edit.tune.vibrance)
                LabeledSlider(title: "Fade", value: $session.edit.tune.fade, range: 0...1)
                LabeledSlider(title: "Soften highlights", value: $session.edit.tune.highlightRolloff, range: 0...1)

                section("Split tone")
                HueSlider(title: "Shadow color", hue: $session.edit.tune.shadowHue)
                LabeledSlider(title: "Shadow amount", value: $session.edit.tune.shadowAmount, range: 0...1)
                HueSlider(title: "Highlight color", hue: $session.edit.tune.highlightHue)
                LabeledSlider(title: "Highlight amount", value: $session.edit.tune.highlightAmount, range: 0...1)

                Toggle("Black & white", isOn: $session.edit.tune.monochrome)
                    .font(.subheadline)

                Button("Reset Tune") { session.edit.tune = .neutral }
                    .font(.footnote)
                    .disabled(session.edit.tune == .neutral)
                    .padding(.top, 4)
            }
            .padding()
        }
    }

    private func section(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }
}

struct MatchPanel: View {
    @Bindable var session: EditSession
    @Environment(MediaStore.self) private var store
    @State private var pick: PhotosPickerItem?
    @State private var naming = false
    @State private var name = ""

    private var isMatched: Bool {
        if case .match = session.edit.base { return true }
        return false
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Copy the colors of any photo: a shot from your feed, a movie still, a friend's edit. Works per photo, so it adapts instead of stamping one filter on everything.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    if let reference = session.referenceThumb, isMatched {
                        Image(uiImage: reference)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 56, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    PhotosPicker(selection: $pick, matching: .images) {
                        Label(isMatched ? "Choose another" : "Choose a reference photo", systemImage: "photo")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Theme.card, in: Capsule())
                    }
                }

                let others = store.items.filter { $0.id != session.item.id }
                if !others.isEmpty {
                    Text("Or match one of your other shots")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(others) { other in
                                Button { session.match(to: other) } label: {
                                    Image(uiImage: other.displayThumbnail)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                }

                if isMatched {
                    LabeledSlider(
                        title: "Amount",
                        value: $session.edit.strength,
                        range: 0...1,
                        neutral: 0.8,
                        format: { "\(Int(($0 * 100).rounded()))%" }
                    )
                    HStack {
                        Button("Save as look") {
                            name = ""
                            naming = true
                        }
                        Spacer()
                        Button("Remove", role: .destructive) { session.choose(.original) }
                    }
                    .font(.subheadline)
                }
            }
            .padding()
        }
        .onChange(of: pick) { _, newValue in
            guard let newValue else { return }
            Task {
                await session.matchReference(newValue)
                pick = nil
            }
        }
        .alert("Save look", isPresented: $naming) {
            TextField("Name", text: $name)
            Button("Save") { session.saveCurrentLook(named: name) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Saved matches adapt to each photo you use them on.")
        }
    }
}
