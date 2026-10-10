import PhotosUI
import SwiftUI

struct LooksPanel: View {
    @Bindable var session: EditSession
    @State private var category: LookCategory?
    @State private var importing = false
    @State private var renaming: Look?
    @State private var newName = ""

    private var library: LookLibrary { session.library }

    private var isMatched: Bool {
        if case .match = session.edit.base { return true }
        return false
    }

    private var categories: [LookCategory] {
        LookCategory.allCases.filter { $0 != .yours || !library.custom.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Button { session.toggleAuto() } label: {
                        Label("Auto", systemImage: "wand.and.stars")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(session.isAutoApplied ? Theme.accent : Theme.card))
                            .foregroundStyle(session.isAutoApplied ? Color.black : Color.primary)
                    }
                    Divider().frame(height: 18)
                    chip("All", selected: category == nil) { category = nil }
                    ForEach(categories) { c in
                        chip(c.rawValue, selected: category == c) { category = c }
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: 10) {
                    Button { session.choose(.original) } label: {
                        LookTile(name: "Original", image: session.original, selected: session.edit.base == .original)
                    }

                    if isMatched {
                        LookTile(name: "Matched", image: session.preview, selected: true)
                    }

                    ForEach(library.looks(in: category)) { look in
                        tile(look)
                    }

                    if category == nil || category == .yours {
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
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
            .frame(height: 98)

            HStack(spacing: 14) {
                if session.edit.base != .original {
                    LabeledSlider(
                        title: "Strength",
                        value: $session.edit.strength,
                        range: 0...1,
                        neutral: 1,
                        format: { "\(Int(($0 * 100).rounded()))%" }
                    )
                } else {
                    Text("Tap a look to try it on your photo. Hold the split button to compare.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Button { session.edit.protectSkin.toggle() } label: {
                    VStack(spacing: 2) {
                        Image(systemName: session.edit.protectSkin ? "face.smiling.inverse" : "face.smiling")
                            .font(.system(size: 20))
                        Text("Skin").font(.caption2)
                    }
                    .foregroundStyle(session.edit.protectSkin ? Theme.accent : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(session.edit.protectSkin ? "Skin protection on" : "Skin protection off")
            }
            .padding(.horizontal)
            Spacer(minLength: 0)
        }
        .padding(.top, 12)
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
        .onChange(of: session.edit.protectSkin) { _, _ in
            session.loadLookThumbs()
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(selected ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(selected ? Theme.accent.opacity(0.25) : Color.clear))
                .foregroundStyle(selected ? Theme.accent : .secondary)
        }
    }

    private func tile(_ look: Look) -> some View {
        Button { session.choose(.look(look.id)) } label: {
            LookTile(name: look.name, image: session.lookThumbs[look.id], selected: session.edit.base == .look(look.id))
        }
        .contextMenu {
            if !look.isBuiltIn {
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
    }
}

struct TunePanel: View {
    @Bindable var session: EditSession

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Button { session.toggleAuto() } label: {
                    Label(session.isAutoApplied ? "Auto applied" : "Auto fix light & color", systemImage: "wand.and.stars")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(Capsule().fill(session.isAutoApplied ? Theme.accent : Theme.card))
                        .foregroundStyle(session.isAutoApplied ? Color.black : Color.primary)
                }
                .buttonStyle(.plain)

                section("Light")
                LabeledSlider(title: "Brightness", value: $session.edit.tune.brightness)
                LabeledSlider(title: "Contrast", value: $session.edit.tune.contrast)
                LabeledSlider(title: "Recover highlights", value: $session.edit.effects.highlights, range: 0...1, format: percent)
                LabeledSlider(title: "Lift shadows", value: $session.edit.effects.shadows, range: 0...1, format: percent)

                section("Color")
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

                section("Finish")
                LabeledSlider(title: "Fade", value: $session.edit.tune.fade, range: 0...1, format: percent)
                LabeledSlider(title: "Soften highlights", value: $session.edit.tune.highlightRolloff, range: 0...1, format: percent)
                LabeledSlider(title: "Glow", value: $session.edit.effects.glow, range: 0...1, format: percent)
                LabeledSlider(title: "Vignette", value: $session.edit.effects.vignette, range: 0...1, format: percent)
                LabeledSlider(title: "Grain", value: $session.edit.effects.grain, range: 0...1, format: percent)

                section("Split tone")
                HueSlider(title: "Shadow color", hue: $session.edit.tune.shadowHue)
                LabeledSlider(title: "Shadow amount", value: $session.edit.tune.shadowAmount, range: 0...1, format: percent)
                HueSlider(title: "Highlight color", hue: $session.edit.tune.highlightHue)
                LabeledSlider(title: "Highlight amount", value: $session.edit.tune.highlightAmount, range: 0...1, format: percent)

                Toggle("Black & white", isOn: $session.edit.tune.monochrome)
                    .font(.subheadline)

                Button("Reset Tune") {
                    var next = session.edit
                    next.tune = .neutral
                    next.effects = .none
                    session.edit = next
                }
                .font(.footnote)
                .disabled(session.edit.tune == .neutral && session.edit.effects == .none)
                .padding(.top, 4)
            }
            .padding()
        }
    }

    private func percent(_ value: Float) -> String {
        "\(Int((value * 100).rounded()))"
    }

    private func section(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }
}

struct CropPanel: View {
    @Bindable var session: EditSession

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(CropAspect.allCases) { aspect in
                        Button {
                            session.edit.crop = Crop(aspect: aspect, center: session.edit.crop.center, zoom: session.edit.crop.zoom)
                        } label: {
                            VStack(spacing: 4) {
                                AspectIcon(ratio: aspect.ratio ?? session.item.aspectRatio)
                                Text(aspect.rawValue).font(.caption.weight(.semibold))
                            }
                            .frame(width: 66, height: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(session.edit.crop.aspect == aspect ? Theme.accent.opacity(0.25) : Theme.card)
                            )
                            .foregroundStyle(session.edit.crop.aspect == aspect ? Theme.accent : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(session.edit.crop.aspect.hint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LabeledSlider(
                    title: "Zoom",
                    value: $session.edit.crop.zoom,
                    range: 1...3,
                    neutral: 1,
                    format: { String(format: "%.1f×", $0) }
                )
                Button("Reset crop") { session.edit.crop = Crop() }
                    .font(.footnote)
                    .disabled(session.edit.crop.isIdentity)
            }
            .padding(.horizontal)
            Spacer(minLength: 0)
        }
        .padding(.top, 14)
    }
}

private struct AspectIcon: View {
    let ratio: CGFloat

    var body: some View {
        let w: CGFloat = ratio >= 1 ? 26 : 26 * ratio
        let h: CGFloat = ratio >= 1 ? 26 / ratio : 26
        RoundedRectangle(cornerRadius: 3)
            .strokeBorder(lineWidth: 1.5)
            .frame(width: w, height: h)
            .frame(width: 28, height: 28)
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
                Text("Copy the colors of any photo: a shot from your feed, a movie still, a friend's edit. It adapts to each photo instead of stamping one filter on everything.")
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
                    Text("Or match one of your other shots, so a set looks consistent")
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
