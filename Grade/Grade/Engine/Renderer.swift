import CoreImage
import Foundation

/// What the "base" look is, resolved to color math for a specific photo.
enum BaseSpec: Hashable {
    case identity
    case recipe(LookRecipe)
    case lut(LUT)
    case match(source: ColorStats, reference: ColorStats)

    func transform() -> (RGB) -> RGB {
        switch self {
        case .identity:
            return { $0 }
        case .recipe(let recipe):
            return recipe.apply
        case .lut(let lut):
            return lut.sample
        case .match(let source, let reference):
            return ColorStats.transfer(from: source, to: reference)
        }
    }
}

struct ShiftLayer {
    var lut: LUT
    var mask: CIImage?
}

/// A fully resolved edit for one image size. Preview and export use the same order:
/// base look (mixed by strength), then Tune, then each color shift inside its mask.
struct RenderJob {
    var base: LUT?
    var strength: Float = 1
    var tune: LUT?
    var shifts: [ShiftLayer] = []
    /// Preview-only: highlights what the active color shift will touch.
    var selection: ShiftLayer?

    func graded(_ image: CIImage) -> CIImage {
        var out = image
        if let base {
            out = GradePipeline.mix(image, GradePipeline.apply(base, to: image), amount: strength)
        }
        if let tune {
            out = GradePipeline.apply(tune, to: out)
        }
        return out
    }

    func shifted(_ graded: CIImage) -> CIImage {
        var out = graded
        for layer in shifts {
            let changed = GradePipeline.apply(layer.lut, to: out)
            out = layer.mask.map { GradePipeline.blend(changed, over: out, mask: $0) } ?? changed
        }
        if let selection {
            let highlighted = GradePipeline.apply(selection.lut, to: out)
            if let mask = selection.mask {
                let dimmed = GradePipeline.apply(LUTCache.shared.dim, to: out)
                out = GradePipeline.blend(highlighted, over: dimmed, mask: mask)
            } else {
                out = highlighted
            }
        }
        return out
    }

    func render(_ image: CIImage) -> CIImage {
        shifted(graded(image))
    }
}

struct ShiftTemplate {
    var lut: LUT
    var strokes: [MaskStroke]
    var feather: Float
}

/// An edit with its LUTs built but masks not yet rasterized, so it can be rendered at any size.
struct JobTemplate {
    var base: LUT?
    var strength: Float
    var tune: LUT?
    var shifts: [ShiftTemplate]

    var isIdentity: Bool { base == nil && tune == nil && shifts.isEmpty }

    static func make(edit: EditState, spec: BaseSpec) -> JobTemplate {
        let cache = LUTCache.shared
        let base: LUT? = spec == .identity ? nil : cache.base(spec, protectSkin: edit.protectSkin)
        let tune: LUT? = edit.tune == .neutral ? nil : cache.tune(edit.tune)
        let shifts = edit.shifts.filter { !$0.params.isNeutral }.map {
            ShiftTemplate(lut: cache.shift($0.params), strokes: $0.strokes, feather: $0.feather)
        }
        return JobTemplate(base: base, strength: edit.strength, tune: tune, shifts: shifts)
    }

    func job(for size: CGSize) -> RenderJob {
        RenderJob(
            base: base,
            strength: strength,
            tune: tune,
            shifts: shifts.map {
                ShiftLayer(lut: $0.lut, mask: MaskRenderer.mask(strokes: $0.strokes, feather: $0.feather, size: size))
            }
        )
    }
}
