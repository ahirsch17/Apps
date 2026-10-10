import CoreGraphics
import Foundation
import simd

/// Average color and spread of a photo in Lab, used to "match the look" of a reference photo.
struct ColorStats: Codable, Hashable {
    var mean: RGB
    var std: RGB

    static func measure(_ image: CGImage) -> ColorStats? {
        let side = 96
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8,
                bytesPerRow: side * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        guard drawn else { return nil }

        var sum = RGB.zero
        var sumSquares = RGB.zero
        let count = Float(side * side)
        for i in stride(from: 0, to: pixels.count, by: 4) {
            let c = RGB(Float(pixels[i]), Float(pixels[i + 1]), Float(pixels[i + 2])) / 255
            let lab = ColorMath.rgbToLab(c)
            sum += lab
            sumSquares += lab * lab
        }
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
