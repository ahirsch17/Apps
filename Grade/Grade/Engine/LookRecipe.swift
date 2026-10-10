import Foundation

/// Shifts one hue band (HSV degrees), the way film stocks move greens toward yellow or blues toward teal.
struct HueBand: Codable, Hashable {
    var center: Float
    var width: Float
    var hueShift: Float = 0
    var saturation: Float = 1
    var lightness: Float = 0
}

/// A look described as color math. Built-in looks and the Tune panel both use this,
/// and it gets baked into a 3D LUT before rendering.
struct LookRecipe: Codable, Hashable {
    var warmth: Float = 0            // -1 cool ... 1 warm
    var tint: Float = 0              // -1 green ... 1 magenta
    var brightness: Float = 0        // -1 ... 1
    var contrast: Float = 0          // -1 ... 1
    var fade: Float = 0              // 0 ... 1, lifts blacks
    var highlightRolloff: Float = 0  // 0 ... 1, softens whites
    var saturation: Float = 1        // 0 ... 2
    var vibrance: Float = 0          // -1 ... 1, boosts muted colors more than vivid ones
    var shadowHue: Float = 200
    var shadowAmount: Float = 0      // 0 ... 1
    var highlightHue: Float = 40
    var highlightAmount: Float = 0   // 0 ... 1
    var monochrome = false
    var bands: [HueBand] = []

    static let neutral = LookRecipe()

    func apply(_ input: RGB) -> RGB {
        var c = input

        if warmth != 0 || tint != 0 {
            c.x *= 1 + 0.12 * warmth
            c.z *= 1 - 0.12 * warmth
            c.y *= 1 - 0.08 * tint
            c = ColorMath.clamp01(c)
        }

        if brightness != 0 {
            let gamma = powf(2, -brightness * 0.6)
            c = RGB(powf(c.x, gamma), powf(c.y, gamma), powf(c.z, gamma))
        }

        if contrast != 0 {
            c = RGB(curve(c.x), curve(c.y), curve(c.z))
        }

        if !bands.isEmpty {
            c = applyBands(c)
        }

        let gray = RGB(repeating: ColorMath.luma(c))
        if monochrome {
            c = gray
        } else if saturation != 1 || vibrance != 0 {
            let currentSat = ColorMath.rgbToHSV(c).s
            let factor = max(0, saturation * (1 + vibrance * (1 - currentSat)))
            c = gray + (c - gray) * factor
        }

        if shadowAmount > 0 || highlightAmount > 0 {
            let l = ColorMath.luma(ColorMath.clamp01(c))
            let shadowTint = ColorMath.hsvToRGB(h: shadowHue, s: 1, v: 1) - RGB(repeating: 0.5)
            let highlightTint = ColorMath.hsvToRGB(h: highlightHue, s: 1, v: 1) - RGB(repeating: 0.5)
            c += shadowTint * (shadowAmount * 0.25 * (1 - l) * (1 - l))
            c += highlightTint * (highlightAmount * 0.25 * l * l)
        }

        if fade > 0 || highlightRolloff > 0 {
            let lift = fade * 0.25
            c = RGB(repeating: lift) + c * (1 - lift - highlightRolloff * 0.12)
        }

        return ColorMath.clamp01(c)
    }

    /// Blends each channel toward a smoothstep S-curve (positive) or away from it (negative).
    private func curve(_ x: Float) -> Float {
        let s = x * x * (3 - 2 * x)
        return x + contrast * (s - x)
    }

    private func applyBands(_ c: RGB) -> RGB {
        let hsv = ColorMath.rgbToHSV(c)
        // Near-neutral colors have no reliable hue, so they stay put.
        let colorfulness = ColorMath.smoothstep(0.05, 0.25, hsv.s)
        guard colorfulness > 0 else { return c }
        var hueShift: Float = 0
        var satScale: Float = 1
        var lightShift: Float = 0
        for band in bands {
            let distance = ColorMath.hueDistance(hsv.h, band.center)
            let w = (1 - ColorMath.smoothstep(band.width * 0.5, band.width, distance)) * colorfulness
            hueShift += band.hueShift * w
            satScale *= 1 + (band.saturation - 1) * w
            lightShift += band.lightness * w
        }
        let v = min(max(hsv.v * (1 + lightShift), 0), 1)
        return ColorMath.hsvToRGB(h: hsv.h + hueShift, s: min(hsv.s * satScale, 1), v: v)
    }
}

enum BuiltInLooks {
    private static func look(_ key: String, _ name: String, _ recipe: LookRecipe) -> Look {
        Look(id: "builtin.\(key)", name: name, source: .recipe(recipe))
    }

    // HSV hue centers: red 0, orange 30, yellow 55, green 110, aqua 180, blue 220, purple 275, magenta 320.
    static let all: [Look] = [
        look("golden", "Golden Hour", LookRecipe(
            warmth: 0.45, tint: 0.05, contrast: 0.15, saturation: 1.08, vibrance: 0.15,
            shadowHue: 250, shadowAmount: 0.1, highlightHue: 38, highlightAmount: 0.35,
            bands: [HueBand(center: 30, width: 40, saturation: 1.12, lightness: 0.04),
                    HueBand(center: 220, width: 60, hueShift: -8, saturation: 0.85)])),
        look("film400", "Film 400", LookRecipe(
            warmth: 0.15, contrast: 0.1, fade: 0.25, highlightRolloff: 0.4, saturation: 0.92,
            shadowHue: 190, shadowAmount: 0.12, highlightHue: 45, highlightAmount: 0.15,
            bands: [HueBand(center: 110, width: 50, hueShift: -12, saturation: 0.8),
                    HueBand(center: 30, width: 35, saturation: 1.05, lightness: 0.03),
                    HueBand(center: 220, width: 60, hueShift: -10, saturation: 0.9)])),
        look("coolfilm", "Cool Film", LookRecipe(
            warmth: -0.25, contrast: 0.08, fade: 0.2, saturation: 0.9,
            shadowHue: 195, shadowAmount: 0.25, highlightHue: 50, highlightAmount: 0.08,
            bands: [HueBand(center: 110, width: 50, hueShift: 25, saturation: 0.8)])),
        look("tealorange", "Teal & Orange", LookRecipe(
            contrast: 0.2, saturation: 1.05,
            shadowHue: 190, shadowAmount: 0.35, highlightHue: 30, highlightAmount: 0.25,
            bands: [HueBand(center: 220, width: 70, hueShift: -25, saturation: 1.1),
                    HueBand(center: 30, width: 40, saturation: 1.15),
                    HueBand(center: 110, width: 50, hueShift: 40, saturation: 0.7)])),
        look("tropical", "Tropical", LookRecipe(
            contrast: 0.12, saturation: 1.15, vibrance: 0.35,
            bands: [HueBand(center: 200, width: 60, hueShift: -20, saturation: 1.2),
                    HueBand(center: 110, width: 50, hueShift: -5, saturation: 1.15),
                    HueBand(center: 30, width: 40, saturation: 1.05)])),
        look("sunset", "Sunset Pop", LookRecipe(
            warmth: 0.25, tint: 0.12, contrast: 0.15, vibrance: 0.3,
            shadowHue: 290, shadowAmount: 0.18,
            bands: [HueBand(center: 25, width: 45, saturation: 1.25),
                    HueBand(center: 0, width: 30, saturation: 1.15)])),
        look("clean", "Clean & Bright", LookRecipe(
            warmth: 0.05, brightness: 0.3, contrast: 0.08, highlightRolloff: 0.1, saturation: 1.04, vibrance: 0.1)),
        look("matte", "Matte", LookRecipe(
            contrast: -0.15, fade: 0.55, highlightRolloff: 0.3, saturation: 0.85)),
        look("pastel", "Pastel", LookRecipe(
            brightness: 0.25, contrast: -0.25, fade: 0.45, saturation: 0.85,
            shadowHue: 260, shadowAmount: 0.1, highlightHue: 340, highlightAmount: 0.18)),
        look("vintage", "Vintage", LookRecipe(
            warmth: 0.3, tint: 0.15, contrast: -0.05, fade: 0.4, saturation: 0.8,
            shadowHue: 330, shadowAmount: 0.12, highlightHue: 50, highlightAmount: 0.3)),
        look("desert", "Desert", LookRecipe(
            warmth: 0.35, contrast: 0.12, fade: 0.12, saturation: 0.9,
            bands: [HueBand(center: 30, width: 50, hueShift: 5, saturation: 1.1),
                    HueBand(center: 220, width: 60, saturation: 0.65),
                    HueBand(center: 110, width: 60, hueShift: -20, saturation: 0.6)])),
        look("nordic", "Nordic", LookRecipe(
            warmth: -0.2, brightness: 0.1, contrast: 0.05, fade: 0.15, saturation: 0.7,
            shadowHue: 210, shadowAmount: 0.12)),
        look("moody", "Moody", LookRecipe(
            brightness: -0.25, contrast: 0.3, saturation: 0.75,
            shadowHue: 210, shadowAmount: 0.25,
            bands: [HueBand(center: 110, width: 60, saturation: 0.6, lightness: -0.1),
                    HueBand(center: 220, width: 60, saturation: 0.8, lightness: -0.08)])),
        look("noir", "Noir", LookRecipe(contrast: 0.35, fade: 0.1, monochrome: true)),
        look("softbw", "Soft B&W", LookRecipe(
            contrast: 0.05, fade: 0.3, highlightHue: 40, highlightAmount: 0.1, monochrome: true)),
    ]
}
