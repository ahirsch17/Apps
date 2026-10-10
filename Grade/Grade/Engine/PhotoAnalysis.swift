import CoreGraphics
import Foundation
import simd

/// One-tap fix: exposure, contrast and white balance from the photo's own histogram.
enum AutoTune {
    static func suggest(for image: CGImage, keeping current: LookRecipe = .neutral) -> (LookRecipe, Effects) {
        var recipe = current
        var effects = Effects()
        guard let pixels = GradePipeline.samplePixels(image, side: 96), !pixels.isEmpty else { return (recipe, effects) }

        let lumas = pixels.map(ColorMath.luma).sorted()
        func percentile(_ p: Float) -> Float { lumas[min(Int(p * Float(lumas.count - 1)), lumas.count - 1)] }
        let p2 = percentile(0.02), p25 = percentile(0.25), p50 = percentile(0.5), p75 = percentile(0.75), p98 = percentile(0.98)

        // Move the median toward a natural mid-gray, but don't brighten backlit or sky-heavy shots,
        // which are usually meant to be dark (sunsets, silhouettes).
        let gamma = logf(0.46) / logf(min(max(p50, 0.05), 0.95))
        var brightness = -log2f(gamma) / 0.6 * 0.75
        if brightness > 0 { brightness *= 1 - ColorMath.smoothstep(0.55, 0.85, p75) }
        recipe.brightness = rounded(min(max(brightness, -0.4), 0.5))
        recipe.contrast = rounded(min(max((0.85 - (p98 - p2)) * 0.6, 0), 0.25))

        // White balance from near-gray pixels only, and only partway: warm light is often the point.
        let neutrals = pixels.filter {
            let hsv = ColorMath.rgbToHSV($0)
            return hsv.s < 0.18 && hsv.v > 0.2 && hsv.v < 0.95
        }
        if Float(neutrals.count) / Float(pixels.count) > 0.05 {
            let count = Float(neutrals.count)
            let warm = neutrals.reduce(Float(0)) { $0 + ($1.x - $1.z) } / count
            let green = neutrals.reduce(Float(0)) { $0 + ($1.y - ($1.x + $1.z) / 2) } / count
            recipe.warmth = rounded(min(max(-warm * 3, -0.25), 0.25))
            recipe.tint = rounded(min(max(green * 4, -0.2), 0.2))
        }
        recipe.vibrance = 0.15

        effects.shadows = rounded(min(max((0.15 - p25) * 2.5, 0), 0.35))
        effects.highlights = p98 > 0.97 ? 0.3 : 0
        return (recipe, effects)
    }

    private static func rounded(_ v: Float) -> Float { (v * 100).rounded() / 100 }
}

/// Something worth recoloring that Grade spotted in the photo, so people don't have to know what to tap.
struct FoundColor: Identifiable {
    let name: String
    let color: RGB
    let point: SIMD2<Float>
    let range: Float

    var id: String { name }
}

enum ColorFinder {
    private struct Bucket {
        let name: String
        let range: Float
        let minShare: Float
        var members: [(color: RGB, lab: RGB, point: SIMD2<Float>)] = []
    }

    static func find(in image: CGImage) -> [FoundColor] {
        let side = 64
        guard let pixels = GradePipeline.samplePixels(image, side: side) else { return [] }

        var buckets = [
            Bucket(name: "Skin", range: 0.35, minShare: 0.01),
            Bucket(name: "Sky", range: 0.5, minShare: 0.03),
            Bucket(name: "Water", range: 0.5, minShare: 0.03),
            Bucket(name: "Greenery", range: 0.5, minShare: 0.03),
            Bucket(name: "Golden light", range: 0.45, minShare: 0.03),
            Bucket(name: "Whites", range: 0.25, minShare: 0.02),
        ]

        for (index, c) in pixels.enumerated() {
            let point = SIMD2<Float>((Float(index % side) + 0.5) / Float(side), (Float(index / side) + 0.5) / Float(side))
            let lab = ColorMath.rgbToLab(c)
            let lch = ColorMath.labToLCh(lab)
            let skin = ColorMath.skinWeight(c)
            let entry = (color: c, lab: lab, point: point)

            // Lab hue angles: skin ~55, yellow-orange ~70, green ~130, teal ~220, sky blue ~260.
            if skin > 0.6 && lch.y > 10 && lch.y < 50 {
                buckets[0].members.append(entry)
            } else if (215...300).contains(lch.z) && lch.y > 8 && lch.x > 45 && point.y < 0.6 {
                buckets[1].members.append(entry)
            } else if (180...260).contains(lch.z) && lch.y > 10 && point.y >= 0.4 {
                buckets[2].members.append(entry)
            } else if (100...170).contains(lch.z) && lch.y > 10 {
                buckets[3].members.append(entry)
            } else if (50...95).contains(lch.z) && lch.y > 40 && lch.x > 50 {
                buckets[4].members.append(entry)
            } else if lch.y < 10 && lch.x > 82 {
                buckets[5].members.append(entry)
            }
        }

        let total = Float(pixels.count)
        return buckets.compactMap { bucket in
            guard Float(bucket.members.count) / total >= bucket.minShare else { return nil }
            let count = Float(bucket.members.count)
            let meanLab = bucket.members.reduce(RGB.zero) { $0 + $1.lab } / count
            // Use a real pixel near the average so the color shift can re-read it when the look changes.
            guard let nearest = bucket.members.min(by: {
                simd_distance_squared($0.lab, meanLab) < simd_distance_squared($1.lab, meanLab)
            }) else { return nil }
            return FoundColor(name: bucket.name, color: nearest.color, point: nearest.point, range: bucket.range)
        }
    }
}
