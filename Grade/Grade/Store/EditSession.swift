import CoreImage
import Observation
import PhotosUI
import simd
import SwiftUI

@Observable
@MainActor
final class EditSession {
    enum Tab: String, CaseIterable, Identifiable {
        case looks = "Looks", tune = "Tune", color = "Color", match = "Match"
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
    var referenceThumb: UIImage?
    var toast: String?
    var busy: String?
    var progress: Double = 0

    private var graded: CGImage?
    private var gradedKey: GradedKey?
    private var renderTask: Task<Void, Never>?
    private var started = false
    private let masks = MaskCache()

    private struct GradedKey: Hashable {
        var spec: BaseSpec
        var strength: Float
        var protectSkin: Bool
        var tune: LookRecipe
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

    // MARK: Rendering

    func scheduleRender() {
        renderTask?.cancel()
        let edit = self.edit
        let key = GradedKey(
            spec: library.spec(for: edit.base, item: item),
            strength: edit.strength,
            protectSkin: edit.protectSkin,
            tune: edit.tune
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
                    let job = RenderJob(base: template.base, strength: template.strength, tune: template.tune)
                    guard let rendered = GradePipeline.cgImage(job.graded(CIImage(cgImage: proxy))) else { return nil }
                    gradedCG = rendered
                }
                if Task.isCancelled { return nil }

                var job = RenderJob()
                job.shifts = template.shifts.map {
                    ShiftLayer(lut: $0.lut, mask: masks.mask(strokes: $0.strokes, feather: $0.feather, size: size))
                }
                if let selected {
                    job.selection = ShiftLayer(
                        lut: LUTCache.shared.selection(selected.params),
                        mask: masks.mask(strokes: selected.strokes, feather: selected.feather, size: size)
                    )
                }
                let output = job.shifted(CIImage(cgImage: gradedCG))
                guard let finished = GradePipeline.cgImage(output) else { return nil }
                return (gradedCG, UIImage(cgImage: finished))
            }.value

            guard let self, !Task.isCancelled, let result else { return }
            let gradedChanged = self.gradedKey != key
            self.graded = result.0
            self.gradedKey = key
            self.preview = result.1
            if gradedChanged { self.retargetShifts() }
        }
    }

    /// Color shifts remember where they were picked; when the look underneath changes, re-read the color there.
    private func retargetShifts() {
        guard let graded else { return }
        var shifts = edit.shifts
        var changed = false
        for i in shifts.indices {
            guard let point = shifts[i].samplePoint, let color = GradePipeline.sampleColor(graded, at: point) else { continue }
            if simd_length(color - shifts[i].target) > 0.01 {
                shifts[i].target = color
                changed = true
            }
        }
        if changed { edit.shifts = shifts }
    }

    private func loadLookThumbs() {
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
        edit.base = choice
        edit.strength = 1
    }

    var hasBakeableLook: Bool { edit.base != .original || edit.tune != .neutral }

    /// The current look and Tune baked into one LUT (color shifts aren't included; they're photo-specific).
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
            edit = EditState(base: .look(look.id), strength: strength, protectSkin: edit.protectSkin, tune: .neutral, shifts: edit.shifts)
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
        edit.base = .match(result.0)
        edit.strength = 0.8
    }

    func match(to other: MediaItem) {
        let image = other.editedThumbnail?.cgImage ?? other.thumbnail
        guard let stats = ColorStats.measure(image) else { return }
        referenceThumb = UIImage(cgImage: image)
        edit.base = .match(stats)
        edit.strength = 0.8
    }

    // MARK: Color shifts

    var activeShift: ColorShift? {
        edit.shifts.first { $0.id == activeShiftID }
    }

    func startPicking(replacingActive: Bool = false) {
        repicking = replacingActive && activeShift != nil
        mode = .pickColor
    }

    func pick(at point: SIMD2<Float>) {
        mode = .view
        guard let graded, let color = GradePipeline.sampleColor(graded, at: point) else { return }
        if repicking, let index = activeIndex {
            edit.shifts[index].target = color
            edit.shifts[index].samplePoint = point
        } else {
            var shift = ColorShift(target: color)
            shift.samplePoint = point
            // Near-white and near-gray picks (teeth, eyes, clouds) start narrow so skin isn't caught too.
            let chroma = ColorMath.labToLCh(ColorMath.rgbToLab(color)).y
            shift.range = chroma < 20 ? 0.25 : 0.4
            edit.shifts.append(shift)
            activeShiftID = shift.id
        }
        repicking = false
        showSelection = true
    }

    func applyPreset(_ preset: ShiftPreset) {
        updateActive {
            $0.lightness = preset.lightness
            $0.chroma = preset.chroma
            $0.hueShift = preset.hueShift
        }
        showSelection = false
    }

    func deleteActiveShift() {
        edit.shifts.removeAll { $0.id == activeShiftID }
        activeShiftID = edit.shifts.last?.id
        mode = .view
        showSelection = false
    }

    func clearMask() {
        updateActive { $0.strokes = [] }
    }

    func undoStroke() {
        updateActive { if !$0.strokes.isEmpty { $0.strokes.removeLast() } }
    }

    func shiftBinding(_ keyPath: WritableKeyPath<ColorShift, Float>) -> Binding<Float> {
        Binding(
            get: { self.activeShift?[keyPath: keyPath] ?? 0 },
            set: { value in self.updateActive { $0[keyPath: keyPath] = value } }
        )
    }

    /// Lets the user pick exactly what the color should become. Stored as relative offsets,
    /// so similar colors around it still move together instead of turning one flat color.
    var resultColorBinding: Binding<Color> {
        Binding(
            get: { Color(rgb: self.activeShift?.params.result ?? RGB(repeating: 1)) },
            set: { newColor in
                guard let shift = self.activeShift, let rgb = newColor.rgb else { return }
                let from = ColorMath.labToLCh(ColorMath.rgbToLab(shift.target))
                let to = ColorMath.labToLCh(ColorMath.rgbToLab(rgb))
                var hue = to.z - from.z
                if hue > 180 { hue -= 360 }
                if hue < -180 { hue += 360 }
                self.updateActive {
                    $0.lightness = min(max((to.x - from.x) / 25, -1), 1)
                    $0.chroma = from.y > 2 ? min(max(to.y / from.y - 1, -1), 1) : 0
                    $0.hueShift = from.y > 6 && to.y > 6 ? hue : 0
                }
            }
        )
    }

    private var activeIndex: Int? {
        edit.shifts.firstIndex { $0.id == activeShiftID }
    }

    private func updateActive(_ change: (inout ColorShift) -> Void) {
        guard let index = activeIndex else { return }
        change(&edit.shifts[index])
    }

    // MARK: Masks

    func beginStroke(at point: SIMD2<Float>, imageWidthOnScreen: CGFloat) {
        guard activeShift != nil, maskTool != .move else { return }
        let radius = Float(brushSize / 2 / max(imageWidthOnScreen, 1))
        draft = MaskStroke(
            kind: maskTool == .lasso ? .lasso : .brush,
            erase: maskTool == .erase,
            radius: radius,
            points: [point]
        )
    }

    func extendStroke(to point: SIMD2<Float>) {
        guard var stroke = draft else { return }
        if let last = stroke.points.last, simd_distance(last, point) < 0.002 { return }
        stroke.points.append(point)
        draft = stroke
    }

    func endStroke() {
        guard let stroke = draft else { return }
        draft = nil
        if stroke.kind == .lasso && stroke.points.count < 3 { return }
        updateActive { $0.strokes.append(stroke) }
    }

    // MARK: Save

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
