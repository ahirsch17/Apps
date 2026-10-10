import simd
import SwiftUI

/// Tap-a-color edits and the areas they apply to.
extension EditSession {
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
            var shift = edit.shifts[index]
            shift.target = color
            shift.samplePoint = point
            edit.shifts[index] = shift
        } else {
            // Near-white and near-gray picks (teeth, eyes, clouds) start narrow so skin isn't caught too.
            let chroma = ColorMath.labToLCh(ColorMath.rgbToLab(color)).y
            addShift(target: color, point: point, range: chroma < 20 ? 0.25 : 0.4)
        }
        repicking = false
        showSelection = true
    }

    /// One tap on a "Sky" / "Greenery" / "Skin" chip instead of hunting for the right pixel.
    func pick(_ found: FoundColor) {
        mode = .view
        addShift(target: found.color, point: found.point, range: found.range)
        showSelection = true
    }

    private func addShift(target: RGB, point: SIMD2<Float>, range: Float) {
        var shift = ColorShift(target: target)
        shift.samplePoint = point
        shift.range = range
        edit.shifts.append(shift)
        activeShiftID = shift.id
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
                    $0.hueShift = from.y > 6 && to.y > 6 ? min(max(hue, -60), 60) : 0
                }
            }
        )
    }

    /// Color shifts remember where they were picked; when the look underneath changes, re-read the color there.
    func retargetShifts() {
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
        if changed { withoutUndo { edit.shifts = shifts } }
    }

    private var activeIndex: Int? {
        edit.shifts.firstIndex { $0.id == activeShiftID }
    }

    private func updateActive(_ change: (inout ColorShift) -> Void) {
        guard let index = activeIndex else { return }
        var shift = edit.shifts[index]
        change(&shift)
        edit.shifts[index] = shift
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
}
