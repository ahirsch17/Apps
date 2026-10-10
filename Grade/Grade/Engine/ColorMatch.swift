import CoreGraphics
import Foundation
import simd

/// Average color and spread of a photo in Lab, used to "match the look" of a reference photo.
struct ColorStats: Codable, Hashable {
    var mean: RGB
    var std: RGB

    static func measure(_ image: CGImage) -> ColorStats? {
        guard let pixels = GradePipeline.samplePixels(image, side: 96), !pixels.isEmpty else { return nil }
        var sum = RGB.zero
        var sumSquares = RGB.zero
        for c in pixels {
            let lab = ColorMath.rgbToLab(c)
            sum += lab
            sumSquares += lab * lab
        }
        let count = Float(pixels.count)
        let mean = sum / count
        let variance = simd_max(sumSquares / count - mean * mean, RGB.zero)
        return ColorStats(mean: mean, std: simd_max(variance.squareRoot(), RGB(repeating: 1)))
    }

    /// Reinhard-style transfer: move `source`'s color distribution toward `reference`.
    /// Ratios are clamped and lightness is only partly matched so faces don't blow out.
    static func transfer(from source: ColorStats, to reference: ColorStats, amount: Float = 1) -> (RGB) -> RGB {
        let ratio = simd_clamp(reference.std / source.std, RGB(repeating: 0.5), RGB(repeating: 2))
        let weights = RGB(0.6, 1, 1) * amount
        return { c in
            let lab = ColorMath.rgbToLab(c)
            let matched = (lab - source.mean) * ratio + reference.mean
            return ColorMath.labToRGB(lab + (matched - lab) * weights)
        }
    }
}
