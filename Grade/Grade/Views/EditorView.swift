import AVKit
import SwiftUI

struct EditorView: View {
    @Environment(MediaStore.self) private var store
    @State private var session: EditSession
    @State private var namingLook = false
    @State private var exportingCube = false
    @State private var lookName = ""
    @State private var cubeFile: SharedFile?
    @State private var playing = false

    init(item: MediaItem, library: LookLibrary) {
        _session = State(initialValue: EditSession(item: item, library: library))
    }

    var body: some View {
        VStack(spacing: 0) {
            PreviewArea(session: session)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            VStack(spacing: 0) {
                panel
                    .frame(height: 236)
                Picker("Tool", selection: $session.tab) {
                    ForEach(EditSession.Tab.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 10)
            }
            .background(Theme.panel)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if session.item.kind == .video {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { playing = true } label: { Image(systemName: "play.circle") }
                        .accessibilityLabel("Play preview")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await session.share() } } label: { Image(systemName: "square.and.arrow.up") }
                    .disabled(session.busy != nil)
                    .accessibilityLabel("Share")
            }
            ToolbarItem(placement: .topBarTrailing) {
                menu
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { Task { await session.save() } }
                    .fontWeight(.semibold)
                    .disabled(!session.edit.isEdited || session.busy != nil)
            }
        }
        .toast($session.toast)
        .overlay {
            if let busy = session.busy {
                BusyOverlay(label: busy, progress: session.item.kind == .video ? session.progress : nil)
            }
        }
        .alert("Save look", isPresented: $namingLook) {
            TextField("Name", text: $lookName)
            Button("Save") { session.saveCurrentLook(named: lookName) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Saves the look and Tune colors so you can use them on any photo. Color fixes, effects and crop stay with this photo.")
        }
        .alert("Export .cube LUT", isPresented: $exportingCube) {
            TextField("Name", text: $lookName)
            Button("Export") {
                if let url = session.exportCube(named: lookName) { cubeFile = SharedFile(url: url) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Works in Lightroom, CapCut, Premiere, Final Cut and DaVinci Resolve.")
        }
        .sheet(item: $session.shared) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $cubeFile) { file in
            ActivityView(items: [file.url])
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $playing) {
            VideoPreview(item: session.item, template: session.template)
        }
        .task { session.start() }
        .onDisappear {
            store.refreshThumbnail(session.item, library: session.library)
        }
    }

    @ViewBuilder
    private var panel: some View {
        switch session.tab {
        case .looks: LooksPanel(session: session)
        case .tune: TunePanel(session: session)
        case .color: ColorPanel(session: session)
        case .match: MatchPanel(session: session)
        case .crop: CropPanel(session: session)
        }
    }

    private var menu: some View {
        Menu {
            Button {
                store.copyEdit(from: session.item)
                session.toast = "Edit copied. Paste it from the menu or the photo grid."
            } label: {
                Label("Copy edit", systemImage: "doc.on.doc")
            }
            .disabled(!session.edit.isEdited)

            if let copied = store.copiedEdit {
                Button {
                    var pasted = copied
                    pasted.shifts = session.edit.shifts.filter { !$0.strokes.isEmpty } + copied.shifts
                    session.edit = pasted
                } label: {
                    Label("Paste edit", systemImage: "doc.on.clipboard")
                }
            }

            Button {
                store.pasteToAll(session.edit.transferable(), except: session.item, library: session.library)
                session.toast = "Applied to \(store.items.count - 1) more"
            } label: {
                Label("Use this edit on all", systemImage: "square.stack.3d.down.right")
            }
            .disabled(!session.edit.isEdited || store.items.count < 2)

            Divider()

            Button {
                lookName = ""
                namingLook = true
            } label: {
                Label("Save as look", systemImage: "plus.square.on.square")
            }
            .disabled(!session.hasBakeableLook)

            Button {
                lookName = session.library.name(for: session.edit.base)
                exportingCube = true
            } label: {
                Label("Export .cube LUT", systemImage: "cube")
            }
            .disabled(!session.hasBakeableLook)

            Divider()

            Button(role: .destructive) {
                session.reset()
            } label: {
                Label("Reset all edits", systemImage: "arrow.counterclockwise")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

struct PreviewArea: View {
    @Bindable var session: EditSession
    @State private var zoom: CGFloat = 1
    @State private var steadyZoom: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var steadyOffset: CGSize = .zero
    @State private var cropDragStart: SIMD2<Float>?

    private var drawing: Bool {
        session.mode == .drawMask && session.maskTool != .move
    }

    private var cropping: Bool { session.tab == .crop }

    var body: some View {
        GeometryReader { geo in
            let view = session.viewRect
            let fitted = fittedSize(in: geo.size, view: view)

            ZStack {
                Image(uiImage: session.displayImage)
                    .resizable()
                    .interpolation(.high)
                if session.mode == .drawMask {
                    MaskOverlay(session: session, view: view, size: fitted)
                }
                if cropping {
                    CropOverlay(rect: session.edit.crop.rect(for: imageSize), size: fitted)
                }
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(pickGesture(fitted, view: view), including: session.mode == .pickColor ? .all : .none)
                    .gesture(drawGesture(fitted, view: view), including: drawing ? .all : .none)
                    .gesture(cropGesture(fitted), including: cropping ? .all : .none)
            }
            .frame(width: fitted.width, height: fitted.height)
            .scaleEffect(zoom)
            .offset(offset)
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .clipped()
            .simultaneousGesture(panGesture(fitted: fitted, container: geo.size), including: drawing || cropping ? .none : .all)
            .simultaneousGesture(zoomGesture(fitted: fitted, container: geo.size), including: cropping ? .none : .all)
            .onTapGesture(count: 2) {
                withAnimation(.snappy) { resetZoom() }
            }
        }
        .background(Color.black)
        .overlay(alignment: .top) { hint }
        .overlay(alignment: .bottomLeading) { undoButtons }
        .overlay(alignment: .bottomTrailing) { compareButton }
        .onChange(of: session.tab) { _, tab in
            if tab == .crop { withAnimation(.snappy) { resetZoom() } }
        }
    }

    private var imageSize: CGSize {
        CGSize(width: session.item.proxy.width, height: session.item.proxy.height)
    }

    private func fittedSize(in container: CGSize, view: CGRect) -> CGSize {
        let aspect = session.item.aspectRatio * view.width / max(view.height, 0.0001)
        let inset = CGSize(width: max(container.width - 16, 1), height: max(container.height - 16, 1))
        if inset.width / inset.height > aspect {
            return CGSize(width: inset.height * aspect, height: inset.height)
        }
        return CGSize(width: inset.width, height: inset.width / aspect)
    }

    /// Converts a touch in the displayed (possibly cropped) image to full-image coordinates.
    private func imagePoint(_ location: CGPoint, fitted: CGSize, view: CGRect) -> SIMD2<Float> {
        let x = view.minX + min(max(location.x / fitted.width, 0), 1) * view.width
        let y = view.minY + min(max(location.y / fitted.height, 0), 1) * view.height
        return SIMD2(Float(x), Float(y))
    }

    private func pickGesture(_ fitted: CGSize, view: CGRect) -> some Gesture {
        SpatialTapGesture()
            .onEnded { value in
                session.pick(at: imagePoint(value.location, fitted: fitted, view: view))
            }
    }

    private func drawGesture(_ fitted: CGSize, view: CGRect) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = imagePoint(value.location, fitted: fitted, view: view)
                if session.draft == nil {
                    session.beginStroke(at: point, imageWidthOnScreen: fitted.width / view.width * zoom)
                } else {
                    session.extendStroke(to: point)
                }
            }
            .onEnded { _ in session.endStroke() }
    }

    private func cropGesture(_ fitted: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let start = cropDragStart ?? session.edit.crop.center
                if cropDragStart == nil { cropDragStart = start }
                let delta = SIMD2(Float(value.translation.width / fitted.width), Float(value.translation.height / fitted.height))
                session.moveCrop(from: start, by: delta)
            }
            .onEnded { _ in cropDragStart = nil }
    }

    private func panGesture(fitted: CGSize, container: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                guard zoom > 1.01 else { return }
                offset = clampedOffset(
                    CGSize(width: steadyOffset.width + value.translation.width, height: steadyOffset.height + value.translation.height),
                    fitted: fitted, container: container
                )
            }
            .onEnded { _ in steadyOffset = offset }
    }

    private func zoomGesture(fitted: CGSize, container: CGSize) -> some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoom = min(max(steadyZoom * value.magnification, 1), 8)
                offset = clampedOffset(offset, fitted: fitted, container: container)
            }
            .onEnded { _ in
                steadyZoom = zoom
                steadyOffset = offset
                if zoom < 1.05 { withAnimation(.snappy) { resetZoom() } }
            }
    }

    private func clampedOffset(_ proposed: CGSize, fitted: CGSize, container: CGSize) -> CGSize {
        let maxX = max((fitted.width * zoom - container.width) / 2 + 40, 0)
        let maxY = max((fitted.height * zoom - container.height) / 2 + 40, 0)
        return CGSize(width: min(max(proposed.width, -maxX), maxX), height: min(max(proposed.height, -maxY), maxY))
    }

    private func resetZoom() {
        zoom = 1
        steadyZoom = 1
        offset = .zero
        steadyOffset = .zero
    }

    private var hintText: String? {
        if cropping { return session.edit.crop.isIdentity ? nil : "Drag to reposition" }
        switch session.mode {
        case .pickColor:
            return "Tap a color in the photo. Pinch to zoom in for small things like teeth."
        case .drawMask:
            switch session.maskTool {
            case .brush: return "Paint where the change should apply"
            case .lasso: return "Draw a loop around the area"
            case .erase: return "Paint to remove areas"
            case .move: return "Drag to move around"
            }
        case .view:
            return session.showSelection ? "Bright areas are what this change affects" : nil
        }
    }

    @ViewBuilder
    private var hint: some View {
        if let text = hintText {
            Text(text)
                .font(.footnote.weight(.medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.top, 10)
                .padding(.horizontal)
                .allowsHitTesting(false)
        }
    }

    private var undoButtons: some View {
        HStack(spacing: 8) {
            circleButton("arrow.uturn.backward", label: "Undo", enabled: session.canUndo) { session.undo() }
            circleButton("arrow.uturn.forward", label: "Redo", enabled: session.canRedo) { session.redo() }
        }
        .padding(12)
    }

    private func circleButton(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.35)
        .accessibilityLabel(label)
    }

    private var compareButton: some View {
        Image(systemName: session.showOriginal ? "eye.slash.fill" : "square.split.2x1")
            .font(.system(size: 15, weight: .semibold))
            .frame(width: 40, height: 40)
            .background(.ultraThinMaterial, in: Circle())
            .padding(12)
            .onLongPressGesture(minimumDuration: 0, perform: {}, onPressingChanged: { pressing in
                session.showOriginal = pressing
            })
            .accessibilityLabel("Hold to compare with original")
    }
}

/// Shows the painted area for the active color change while drawing.
private struct MaskOverlay: View {
    let session: EditSession
    let view: CGRect
    let size: CGSize

    var body: some View {
        let strokes = (session.activeShift?.strokes ?? []) + (session.draft.map { [$0] } ?? [])
        Canvas { context, canvasSize in
            let fullWidth = canvasSize.width / view.width
            for stroke in strokes {
                let points = stroke.points.map {
                    CGPoint(
                        x: (CGFloat($0.x) - view.minX) / view.width * canvasSize.width,
                        y: (CGFloat($0.y) - view.minY) / view.height * canvasSize.height
                    )
                }
                guard let first = points.first else { continue }
                var path = Path()
                path.move(to: first)
                for p in points.dropFirst() { path.addLine(to: p) }
                let color: Color = stroke.erase ? .red : Theme.accent
                switch stroke.kind {
                case .lasso:
                    path.closeSubpath()
                    context.fill(path, with: .color(color.opacity(0.25)))
                    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                case .brush:
                    let width = CGFloat(stroke.radius) * 2 * fullWidth
                    if points.count == 1 {
                        context.fill(Path(ellipseIn: CGRect(x: first.x - width / 2, y: first.y - width / 2, width: width, height: width)),
                                     with: .color(color.opacity(0.3)))
                    } else {
                        context.stroke(path, with: .color(color.opacity(0.3)),
                                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                    }
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

/// Dims everything outside the crop and draws a rule-of-thirds grid inside it.
private struct CropOverlay: View {
    let rect: CGRect
    let size: CGSize

    var body: some View {
        let frame = CGRect(x: rect.minX * size.width, y: rect.minY * size.height,
                           width: rect.width * size.width, height: rect.height * size.height)
        Canvas { context, _ in
            var outside = Path(CGRect(origin: .zero, size: size))
            outside.addRect(frame)
            context.fill(outside, with: .color(.black.opacity(0.55)), style: FillStyle(eoFill: true))
            context.stroke(Path(frame), with: .color(.white), lineWidth: 1.5)
            var grid = Path()
            for i in 1...2 {
                let x = frame.minX + frame.width * CGFloat(i) / 3
                let y = frame.minY + frame.height * CGFloat(i) / 3
                grid.move(to: CGPoint(x: x, y: frame.minY))
                grid.addLine(to: CGPoint(x: x, y: frame.maxY))
                grid.move(to: CGPoint(x: frame.minX, y: y))
                grid.addLine(to: CGPoint(x: frame.maxX, y: y))
            }
            context.stroke(grid, with: .color(.white.opacity(0.4)), lineWidth: 0.5)
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

private struct VideoPreview: View {
    let item: MediaItem
    let template: JobTemplate
    @State private var player: AVPlayer?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let player {
                    VideoPlayer(player: player)
                        .onAppear { player.play() }
                } else {
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .task {
            let asset = AVURLAsset(url: item.url)
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.videoComposition = try? await Exporter.videoComposition(for: asset, template: template)
            player = AVPlayer(playerItem: playerItem)
        }
        .onDisappear { player?.pause() }
    }
}
