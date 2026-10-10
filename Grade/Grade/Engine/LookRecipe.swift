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
            // Vibrance targets muted colors but leaves near-whites and skin alone, so a white dress
            // doesn't pick up a blue cast and faces don't go orange.
            let clamped = ColorMath.clamp01(c)
            let s = ColorMath.rgbToHSV(clamped).s
            let muted = (1 - s) * ColorMath.smoothstep(0.03, 0.18, s) * (1 - 0.6 * ColorMath.skinWeight(clamped))
            let factor = max(0, saturation * (1 + vibrance * muted))
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
        // Near-neutral colors (white clothes, gray pavement) have no reliable hue, so they stay put.
        let colorfulness = ColorMath.smoothstep(0.12, 0.35, hsv.s)
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
    private static func look(_ key: String, _ name: String, _ category: LookCategory, _ recipe: LookRecipe) -> Look {
        Look(id: "builtin.\(key)", name: name, category: category, source: .recipe(recipe))
    }

    // Tuned against real portrait, couple, group, sunset and night photos.
    // HSV hue centers: red 0, orange 30, yellow 55, green 110, aqua 180, blue 220, purple 275, magenta 320.
    static let all: [Look] = [
        look("airy", "Bright & Airy", .portrait, LookRecipe(
            warmth: 0.08, brightness: 0.35, contrast: -0.05, fade: 0.08, highlightRolloff: 0.3, saturation: 0.92, vibrance: 0.1,
            bands: [HueBand(center: 110, width: 50, hueShift: -8, saturation: 0.75, lightness: 0.05),
                    HueBand(center: 220, width: 60, saturation: 0.85)])),
        look("portra", "Portra", .portrait, LookRecipe(
            warmth: 0.18, tint: 0.04, contrast: 0.08, fade: 0.15, highlightRolloff: 0.35, saturation: 0.95,
            shadowHue: 200, shadowAmount: 0.08, highlightHue: 40, highlightAmount: 0.12,
            bands: [HueBand(center: 110, width: 50, hueShift: -10, saturation: 0.75),
                    HueBand(center: 30, width: 35, saturation: 1.05, lightness: 0.04),
                    HueBand(center: 220, width: 60, hueShift: -8, saturation: 0.85)])),
        look("golden", "Golden Hour", .portrait, LookRecipe(
            warmth: 0.45, tint: 0.05, contrast: 0.15, saturation: 1.05, vibrance: 0.15,
            shadowHue: 250, shadowAmount: 0.08, highlightHue: 38, highlightAmount: 0.35,
            bands: [HueBand(center: 30, width: 40, saturation: 1.1, lightness: 0.04),
                    HueBand(center: 220, width: 60, hueShift: -8, saturation: 0.85)])),
        look("peach", "Peach", .portrait, LookRecipe(
            warmth: 0.15, tint: 0.1, brightness: 0.15, contrast: 0.05, fade: 0.1, highlightRolloff: 0.2, saturation: 0.95,
            highlightHue: 15, highlightAmount: 0.22,
            bands: [HueBand(center: 110, width: 50, hueShift: -10, saturation: 0.8)])),
        look("vivid", "Vivid", .travel, LookRecipe(
            contrast: 0.18, highlightRolloff: 0.15, saturation: 1.04, vibrance: 0.4)),
        look("azure", "Azure", .travel, LookRecipe(
            warmth: 0.05, contrast: 0.12, vibrance: 0.25,
            bands: [HueBand(center: 195, width: 50, hueShift: -8, saturation: 1.25, lightness: 0.03),
                    HueBand(center: 225, width: 50, hueShift: -12, saturation: 1.15),
                    HueBand(center: 30, width: 40, saturation: 1.05)])),
        look("tropical", "Tropical", .travel, LookRecipe(
            contrast: 0.12, saturation: 1.08, vibrance: 0.35,
            bands: [HueBand(center: 200, width: 60, hueShift: -15, saturation: 1.2),
                    HueBand(center: 110, width: 50, hueShift: -5, saturation: 1.15),
                    HueBand(center: 30, width: 40, saturation: 1.05)])),
        look("tealorange", "Teal & Orange", .travel, LookRecipe(
            contrast: 0.18, saturation: 1.02,
            shadowHue: 190, shadowAmount: 0.2, highlightHue: 30, highlightAmount: 0.2,
            bands: [HueBand(center: 220, width: 70, hueShift: -25, saturation: 1.1),
                    HueBand(center: 30, width: 40, saturation: 1.12),
                    HueBand(center: 110, width: 50, hueShift: 40, saturation: 0.7)])),
        look("sunset", "Sunset Pop", .travel, LookRecipe(
            warmth: 0.25, tint: 0.06, contrast: 0.15, vibrance: 0.3,
            shadowHue: 280, shadowAmount: 0.07,
            bands: [HueBand(center: 25, width: 45, saturation: 1.22),
                    HueBand(center: 0, width: 30, saturation: 1.12)])),
        look("desert", "Desert", .travel, LookRecipe(
            warmth: 0.35, contrast: 0.12, fade: 0.12, saturation: 0.9,
            bands: [HueBand(center: 30, width: 50, hueShift: 5, saturation: 1.1),
                    HueBand(center: 220, width: 60, saturation: 0.65),
                    HueBand(center: 110, width: 60, hueShift: -20, saturation: 0.6)])),
        look("greenfilm", "Green Film", .film, LookRecipe(
            warmth: -0.05, contrast: 0.12, fade: 0.15, highlightRolloff: 0.25, saturation: 0.92,
            shadowHue: 170, shadowAmount: 0.12,
            bands: [HueBand(center: 110, width: 50, hueShift: 12, saturation: 0.85),
                    HueBand(center: 0, width: 30, saturation: 0.9)])),
        look("vintage", "Vintage", .film, LookRecipe(
            warmth: 0.3, tint: 0.1, contrast: 0.12, fade: 0.3, highlightRolloff: 0.25, saturation: 0.82,
            shadowHue: 330, shadowAmount: 0.08, highlightHue: 50, highlightAmount: 0.25)),
        look("matte", "Matte", .film, LookRecipe(
            contrast: 0.08, fade: 0.42, highlightRolloff: 0.3, saturation: 0.9)),
        look("pastel", "Pastel", .film, LookRecipe(
            brightness: 0.25, contrast: -0.1, fade: 0.3, saturation: 0.85,
            shadowHue: 260, shadowAmount: 0.06, highlightHue: 340, highlightAmount: 0.12)),
        look("moody", "Moody", .moody, LookRecipe(
            brightness: -0.2, contrast: 0.3, saturation: 0.78,
            shadowHue: 210, shadowAmount: 0.2,
            bands: [HueBand(center: 110, width: 60, saturation: 0.6, lightness: -0.1),
                    HueBand(center: 220, width: 60, saturation: 0.8, lightness: -0.08)])),
        look("nordic", "Nordic", .moody, LookRecipe(
            warmth: -0.2, brightness: 0.1, contrast: 0.08, fade: 0.12, saturation: 0.7,
            shadowHue: 210, shadowAmount: 0.1)),
        look("noir", "Noir", .blackAndWhite, LookRecipe(contrast: 0.35, fade: 0.08, monochrome: true)),
        look("softbw", "Soft B&W", .blackAndWhite, LookRecipe(
            brightness: 0.1, contrast: 0.05, fade: 0.25, highlightHue: 40, highlightAmount: 0.08, monochrome: true)),
    ]
}
