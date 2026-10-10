import CoreImage
import Observation
import PhotosUI
import simd
import SwiftUI

/// Everything the editor screen needs for one photo or video: the edit, live preview, undo, looks and export.
/// Color picking and masks live in EditSession+Color.swift.
@Observable
@MainActor
final class EditSession {
    enum Tab: String, CaseIterable, Identifiable {
        case looks = "Looks", tune = "Tune", color = "Color", match = "Match", crop = "Crop"
        var id: Self { self }
    }

    enum Mode {
        case view, pickColor, drawMask
    }

    enum MaskTool: String, CaseIterable, Identifiable {
        case brush = "Brush", lasso = "Lasso", erase = "Erase", move = "Move"
        var id: Self { self }

        var symbol: String {
            switch self {
            case .brush: return "paintbrush.pointed"
            case .lasso: return "lasso"
            case .erase: return "eraser"
            case .move: return "hand.draw"
            }
        }
    }

    let item: MediaItem
    let library: LookLibrary
    let original: UIImage

    var edit: EditState {
        didSet {
            guard edit != oldValue else { return }
            item.edit = edit
            recordUndo(oldValue)
            scheduleRender()
        }
    }

    var tab: Tab = .looks {
        didSet {
            guard tab != .color else { return }
            mode = .view
            showSelection = false
        }
    }

    var mode: Mode = .view
    var maskTool: MaskTool = .brush
    /// On-screen brush diameter in points; strokes store it relative to the image so zoom gives finer control.
    var brushSize: CGFloat = 36
    var activeShiftID: UUID?
    var repicking = false
    var showSelection = false {
        didSet { if showSelection != oldValue { scheduleRender() } }
    }
    var showOriginal = false
    var draft: MaskStroke?

    var preview: UIImage?
    var lookThumbs: [String: UIImage] = [:]
    var foundColors: [FoundColor] = []
    var referenceThumb: UIImage?
    var toast: String?
    var busy: String?
    var progress: Double = 0
    var shared: SharedFile?

    private(set) var graded: CGImage?
    @ObservationIgnored private var gradedKey: GradedKey?
    @ObservationIgnored private var renderTask: Task<Void, Never>?
    @ObservationIgnored private var started = false
    private let masks = MaskCache()
    @ObservationIgnored private var autoSuggestion: (recipe: LookRecipe, effects: Effects)?

    private var undoStack: [EditState] = []
    private var redoStack: [EditState] = []
    @ObservationIgnored private var lastUndoRecord = Date.distantPast
    @ObservationIgnored private var recordingUndo = true

    private struct GradedKey: Hashable {
        var spec: BaseSpec
        var strength: Float
        var protectSkin: Bool
        var tune: LookRecipe
        var highlights: Float
        var shadows: Float
    }

    init(item: MediaItem, library: LookLibrary) {
        self.item = item
        self.library = library
        self.original = UIImage(cgImage: item.proxy)
        self.edit = item.edit
    }

    /// Kicks off the first render. Kept out of `init` because SwiftUI may build throwaway sessions.
    func start() {
        guard !started else { return }
        started = true
        scheduleRender()
        loadLookThumbs()
    }

    // MARK: Undo

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    /// Slider drags arrive as dozens of tiny edits; anything within 0.8 s of the last change is one undo step.
    private func recordUndo(_ previous: EditState) {
        guard recordingUndo else { return }
        if Date().timeIntervalSince(lastUndoRecord) > 0.8 {
            undoStack.append(previous)
            if undoStack.count > 60 { undoStack.removeFirst() }
            redoStack.removeAll()
        }
        lastUndoRecord = Date()
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(edit)
        restore(previous)
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(edit)
        restore(next)
    }

    private func restore(_ state: EditState) {
        withoutUndo { edit = state }
        lastUndoRecord = .distantPast
        if activeShift == nil { activeShiftID = edit.shifts.last?.id }
        mode = .view
    }

    func withoutUndo(_ change: () -> Void) {
        recordingUndo = false
        change()
        recordingUndo = true
    }

    // MARK: Rendering

    func scheduleRender() {
        renderTask?.cancel()
        let edit = self.edit
        let key = GradedKey(
            spec: library.spec(for: edit.base, item: item),
            strength: edit.strength,
            protectSkin: edit.protectSkin,
            tune: edit.tune,
            highlights: edit.effects.highlights,
            shadows: edit.effects.shadows
        )
        let cachedGraded = key == gradedKey ? graded : nil
        let proxy = item.proxy
        let activeID = activeShiftID
        let selected = showSelection ? edit.shifts.first(where: { $0.id == activeID }) : nil
        let masks = self.masks

        renderTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(10))
            guard !Task.isCancelled else { return }

            let result = await Task.detached(priority: .userInitiated) { () -> (CGImage, UIImage)? in
                let template = JobTemplate.make(edit: edit, spec: key.spec)
                let size = CGSize(width: proxy.width, height: proxy.height)

                let gradedCG: CGImage
                if let cachedGraded {
                    gradedCG = cachedGraded
                } else {
                    let job = RenderJob(base: template.base, strength: template.strength, tune: template.tune, effects: template.effects)
                    guard let rendered = GradePipeline.cgImage(job.graded(CIImage(cgImage: proxy))) else { return nil }
                    gradedCG = rendered
                }

                var job = RenderJob(effects: template.effects)
                job.shifts = template.shifts.map {
                    ShiftLayer(lut: $0.lut, mask: masks.mask(strokes: $0.strokes, feather: $0.feather, size: size))
                }
                var output = job.shifted(CIImage(cgImage: gradedCG))
                if let selected {
                    job.selection = ShiftLayer(
                        lut: LUTCache.shared.selection(selected.params),
                        mask: masks.mask(strokes: selected.strokes, feather: selected.feather, size: size)
                    )
                    output = job.shifted(CIImage(cgImage: gradedCG))
                } else {
                    output = template.effects.finish(output)
                }
                guard let finished = GradePipeline.cgImage(output) else { return nil }
                return (gradedCG, UIImage(cgImage: finished))
            }.value

            guard let self, !Task.isCancelled, let result else { return }
            let gradedChanged = self.gradedKey != key
            self.graded = result.0
            self.gradedKey = key
            self.preview = result.1
            if gradedChanged {
                self.retargetShifts()
                self.findColors(in: result.0)
            }
        }
    }

    private func findColors(in image: CGImage) {
        Task.detached(priority: .utility) { [weak self] in
            let found = ColorFinder.find(in: image)
            await MainActor.run { self?.foundColors = found }
        }
    }

    /// What the preview shows: the whole photo while cropping, otherwise just the cropped part.
    var viewRect: CGRect {
        tab == .crop ? CGRect(x: 0, y: 0, width: 1, height: 1) : edit.crop.rect(for: CGSize(width: item.proxy.width, height: item.proxy.height))
    }

    var displayImage: UIImage {
        let image = showOriginal ? original : (preview ?? original)
        let rect = viewRect
        guard rect.width < 0.999 || rect.height < 0.999, let cg = image.cgImage else { return image }
        let pixels = CGRect(
            x: rect.minX * CGFloat(cg.width), y: rect.minY * CGFloat(cg.height),
            width: rect.width * CGFloat(cg.width), height: rect.height * CGFloat(cg.height)
        ).integral
        return cg.cropping(to: pixels).map { UIImage(cgImage: $0) } ?? image
    }

    func loadLookThumbs() {
        let looks = library.builtIns + library.custom
        let specs = looks.map { ($0.id, library.spec(for: .look($0.id), item: item)) }
        let protectSkin = edit.protectSkin
        let thumb = GradePipeline.downscale(CIImage(cgImage: item.thumbnail), maxDimension: 200)
        Task.detached(priority: .utility) { [weak self] in
            for (id, spec) in specs {
                let lut = LUTCache.shared.base(spec, protectSkin: protectSkin)
                guard let image = UIImage(rendering: GradePipeline.apply(lut, to: thumb)) else { continue }
                await MainActor.run { self?.lookThumbs[id] = image }
            }
        }
    }

    func refreshLookThumb(_ look: Look) {
        let spec = library.spec(for: .look(look.id), item: item)
        let thumb = GradePipeline.downscale(CIImage(cgImage: item.thumbnail), maxDimension: 200)
        let lut = LUTCache.shared.base(spec, protectSkin: edit.protectSkin)
        lookThumbs[look.id] = UIImage(rendering: GradePipeline.apply(lut, to: thumb))
    }

    // MARK: Looks

    func choose(_ choice: BaseChoice) {
        guard edit.base != choice else { return }
        var next = edit
        next.base = choice
        next.strength = 1
        edit = next
    }

    var hasBakeableLook: Bool { edit.base != .original || edit.tune != .neutral }

    /// The current look and Tune baked into one LUT. Color shifts, effects and crop aren't LUT-able.
    func bakedLUT(size: Int = 33) -> LUT {
        let spec = library.spec(for: edit.base, item: item)
        // Skin protection is left out of the bake; it's applied again when the saved look is used.
        let base = spec == .identity ? nil : LUTCache.shared.base(spec, protectSkin: false)
        let strength = edit.strength
        let tune = edit.tune
        return LUT.build(size: size) { c in
            var out = c
            if let base { out = ColorMath.mix(c, base.sample(c), strength) }
            return tune == .neutral ? out : tune.apply(out)
        }
    }

    func saveCurrentLook(named name: String) {
        let title = name.trimmingCharacters(in: .whitespaces).isEmpty ? "My look" : name
        do {
            let look: Look
            var strength: Float = 1
            if case .match(let stats) = edit.base, edit.tune == .neutral {
                look = library.addMatch(name: title, stats: stats)
                strength = edit.strength
            } else {
                look = try library.addLUT(name: title, lut: bakedLUT())
            }
            refreshLookThumb(look)
            var next = edit
            next.base = .look(look.id)
            next.strength = strength
            next.tune = .neutral
            edit = next
            toast = "Saved \"\(title)\" to your looks"
        } catch {
            toast = "Couldn't save the look"
        }
    }

    func exportCube(named name: String) -> URL? {
        let title = name.isEmpty ? "Grade look" : name
        let text = CubeFile.export(bakedLUT(), title: title)
        let safe = title.replacingOccurrences(of: "/", with: "-")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(safe).appendingPathExtension("cube")
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            toast = "Couldn't export the LUT"
            return nil
        }
    }

    func importCube(_ url: URL) {
        do {
            let look = try library.importCube(from: url)
            refreshLookThumb(look)
            choose(.look(look.id))
            toast = "Imported \(look.name)"
        } catch {
            toast = error.localizedDescription
        }
    }

    // MARK: Auto

    private var suggestion: (recipe: LookRecipe, effects: Effects) {
        if let autoSuggestion { return autoSuggestion }
        let made = AutoTune.suggest(for: item.proxy)
        autoSuggestion = (made.0, made.1)
        return (made.0, made.1)
    }

    var isAutoApplied: Bool {
        let s = suggestion
        let t = edit.tune
        return t.brightness == s.recipe.brightness && t.contrast == s.recipe.contrast && t.warmth == s.recipe.warmth
            && t.tint == s.recipe.tint && t.vibrance == s.recipe.vibrance
            && edit.effects.highlights == s.effects.highlights && edit.effects.shadows == s.effects.shadows
    }

    /// Fixes exposure and white balance. Tapping again puts those sliders back.
    func toggleAuto() {
        let s = suggestion
        let on = !isAutoApplied
        var next = edit
        next.tune.brightness = on ? s.recipe.brightness : 0
        next.tune.contrast = on ? s.recipe.contrast : 0
        next.tune.warmth = on ? s.recipe.warmth : 0
        next.tune.tint = on ? s.recipe.tint : 0
        next.tune.vibrance = on ? s.recipe.vibrance : 0
        next.effects.highlights = on ? s.effects.highlights : 0
        next.effects.shadows = on ? s.effects.shadows : 0
        edit = next
    }

    // MARK: Match

    func matchReference(_ pick: PhotosPickerItem) async {
        busy = "Reading colors"
        defer { busy = nil }
        guard let data = try? await pick.loadTransferable(type: Data.self) else {
            toast = "Couldn't load that photo"
            return
        }
        let result = await Task.detached(priority: .userInitiated) { () -> (ColorStats, UIImage)? in
            guard let image = CIImage(data: data, options: [.applyOrientationProperty: true]) else { return nil }
            let small = GradePipeline.downscale(GradePipeline.normalized(image), maxDimension: 300)
            guard let cg = GradePipeline.cgImage(small), let stats = ColorStats.measure(cg) else { return nil }
            return (stats, UIImage(cgImage: cg))
        }.value
        guard let result else {
            toast = "Couldn't read that photo"
            return
        }
        referenceThumb = result.1
        setMatch(result.0)
    }

    func match(to other: MediaItem) {
        let image = other.editedThumbnail?.cgImage ?? other.thumbnail
        guard let stats = ColorStats.measure(image) else { return }
        referenceThumb = UIImage(cgImage: image)
        setMatch(stats)
    }

    private func setMatch(_ stats: ColorStats) {
        var next = edit
        next.base = .match(stats)
        next.strength = 0.8
        edit = next
    }

    // MARK: Crop

    /// Drags in the crop view move the frame; `start` is the center when the drag began.
    func moveCrop(from start: SIMD2<Float>, by delta: SIMD2<Float>) {
        let size = CGSize(width: item.proxy.width, height: item.proxy.height)
        var crop = edit.crop
        crop.center = start + delta
        let rect = crop.rect(for: size)
        crop.center = SIMD2(Float(rect.midX), Float(rect.midY))
        edit.crop = crop
    }

    // MARK: Save & share

    var template: JobTemplate {
        JobTemplate.make(edit: edit, spec: library.spec(for: edit.base, item: item))
    }

    func save() async {
        busy = item.kind == .video ? "Exporting video" : "Saving"
        progress = 0
        defer { busy = nil }
        do {
            try await Exporter.save(item: item, template: template) { fraction in
                Task { @MainActor in self.progress = fraction }
            }
            toast = "Saved to Photos"
        } catch {
            toast = error.localizedDescription
        }
    }

    /// Renders at full quality and opens the share sheet (Instagram, Messages, AirDrop…).
    func share() async {
        busy = item.kind == .video ? "Preparing video" : "Preparing photo"
        progress = 0
        defer { busy = nil }
        do {
            let url = try await Exporter.render(item: item, template: template) { fraction in
                Task { @MainActor in self.progress = fraction }
            }
            shared = SharedFile(url: url)
        } catch {
            toast = error.localizedDescription
        }
    }

    func reset() {
        edit = EditState()
        activeShiftID = nil
        referenceThumb = nil
        mode = .view
        showSelection = false
    }
}

/// Rasterized masks for the preview, so moving a slider doesn't redraw every stroke.
final class MaskCache {
    private struct Key: Hashable {
        var strokes: [MaskStroke]
        var feather: Float
        var width: CGFloat
        var height: CGFloat
    }

    private var store: [Key: CIImage] = [:]
    private var order: [Key] = []
    private let lock = NSLock()

    func mask(strokes: [MaskStroke], feather: Float, size: CGSize) -> CIImage? {
        guard !strokes.isEmpty else { return nil }
        let key = Key(strokes: strokes, feather: feather, width: size.width, height: size.height)
        lock.lock()
        if let hit = store[key] {
            lock.unlock()
            return hit
        }
        lock.unlock()

        guard let rendered = MaskRenderer.mask(strokes: strokes, feather: feather, size: size),
              let cg = GradePipeline.context.createCGImage(rendered, from: rendered.extent) else { return nil }
        let mask = CIImage(cgImage: cg)

        lock.lock()
        defer { lock.unlock() }
        store[key] = mask
        order.append(key)
        if order.count > 12 { store[order.removeFirst()] = nil }
        return mask
    }
}
