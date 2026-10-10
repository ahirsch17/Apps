import Foundation

/// One finger-drawn stroke on the mask, in normalized image coordinates (0...1, top-left origin).
struct MaskStroke: Codable, Hashable {
    enum Kind: String, Codable { case brush, lasso }

    var kind: Kind
    var erase: Bool
    /// Brush radius as a fraction of image width.
    var radius: Float
    var points: [SIMD2<Float>]
}

/// "Make this color look like that": a selective color change that keeps the natural shading.
struct ColorShift: Identifiable, Hashable {
    let id = UUID()
    var target: RGB
    var samplePoint: SIMD2<Float>?
    var range: Float = 0.4
    var lightness: Float = 0
    var chroma: Float = 0
    var hueShift: Float = 0
    var feather: Float = 0.025
    var strokes: [MaskStroke] = []

    init(target: RGB) {
        self.target = target
    }

    var params: ShiftParams {
        ShiftParams(target: target, range: range, lightness: lightness, chroma: chroma, hueShift: hueShift)
    }
}

/// The color math part of a ColorShift (no mask), so it can key the LUT cache.
///
/// Changes are relative, not a fill: every matched color moves by the same amount in LCh,
/// weighted by how close it is to the target. Grass keeps its light and dark blades,
/// teeth keep their shading, nothing collapses into one flat color.
struct ShiftParams: Hashable {
    var target: RGB
    var range: Float
    var lightness: Float
    var chroma: Float
    var hueShift: Float

    var isNeutral: Bool { lightness == 0 && chroma == 0 && hueShift == 0 }

    /// 1 at the target color, fading to 0 as colors get less similar.
    ///
    /// Distance is measured in LCh with lightness weighted least, so the shadowed and lit parts of
    /// one surface match each other. Hue counts double for near-neutral picks, where a small hue gap
    /// is the only thing separating off-white teeth and eye whites from the skin around them.
    func weight() -> (RGB) -> Float {
        let t = ColorMath.labToLCh(ColorMath.rgbToLab(target))
        let radius = 6 + range * 44
        let hueWeight = 2 - ColorMath.smoothstep(20, 45, t.y)
        return { c in
            let lch = ColorMath.labToLCh(ColorMath.rgbToLab(c))
            var dh = lch.z - t.z
            if dh > 180 { dh -= 360 }
            if dh < -180 { dh += 360 }
            let dH = 2 * (lch.y * t.y).squareRoot() * sinf(dh * .pi / 360) * hueWeight
            let dL = (lch.x - t.x) * 0.35
            let dC = (lch.y - t.y) * 0.7
            let distance = (dL * dL + dC * dC + dH * dH).squareRoot()
            return 1 - ColorMath.smoothstep(radius * 0.45, radius, distance)
        }
    }

    func transform() -> (RGB) -> RGB {
        let weight = weight()
        let l = lightness, ch = chroma, hs = hueShift
        return { c in
            let k = weight(c)
            guard k > 0.0001 else { return c }
            return Self.shifted(c, lightness: l * k, chroma: ch * k, hue: hs * k)
        }
    }

    /// What the target color itself turns into.
    var result: RGB {
        Self.shifted(target, lightness: lightness, chroma: chroma, hue: hueShift)
    }

    static func shifted(_ c: RGB, lightness: Float, chroma: Float, hue: Float) -> RGB {
        var lch = ColorMath.labToLCh(ColorMath.rgbToLab(c))
        lch.x = min(max(lch.x + lightness * 25, 0), 100)
        lch.y = max(lch.y * (1 + chroma), 0)
        lch.z += hue
        return ColorMath.labToRGB(ColorMath.lchToLab(lch))
    }
}

/// One-tap ideas for what the picked color could become, based on what it is.
struct ShiftPreset: Identifiable {
    let name: String
    let lightness: Float
    let chroma: Float
    let hueShift: Float

    var id: String { name }

    func preview(from target: RGB) -> RGB {
        ShiftParams.shifted(target, lightness: lightness, chroma: chroma, hue: hueShift)
    }

    static func suggestions(for color: RGB) -> [ShiftPreset] {
        let lch = ColorMath.labToLCh(ColorMath.rgbToLab(color))
        let l = lch.x, c = lch.y, h = lch.z

        // Off-whites (teeth, eye whites, white shirts, clouds) are slightly yellow, not gray.
        let offWhite = l > 60 && c < 22 && (70...115).contains(h)
        if c < 10 || offWhite {
            if l > 55 {
                return [
                    ShiftPreset(name: "Clean white", lightness: 0.35, chroma: -0.85, hueShift: 0),
                    ShiftPreset(name: "Brighter", lightness: 0.5, chroma: -0.3, hueShift: 0),
                    ShiftPreset(name: "Softer", lightness: -0.25, chroma: 0, hueShift: 0),
                    ShiftPreset(name: "Neutral", lightness: 0, chroma: -1, hueShift: 0),
                ]
            }
            return [
                ShiftPreset(name: "Deeper", lightness: -0.4, chroma: 0, hueShift: 0),
                ShiftPreset(name: "Lifted", lightness: 0.35, chroma: 0, hueShift: 0),
                ShiftPreset(name: "Neutral", lightness: 0, chroma: -1, hueShift: 0),
            ]
        }

        // Lab hue angles: red ~35, skin ~55, yellow ~95, green ~135, cyan ~200, sky ~260.
        var ideas: [ShiftPreset]
        switch h {
        case 20..<75 where c < 45:
            ideas = [
                ShiftPreset(name: "Glow", lightness: 0.25, chroma: -0.1, hueShift: 0),
                ShiftPreset(name: "Less red", lightness: 0.05, chroma: -0.15, hueShift: 8),
                ShiftPreset(name: "Sun-kissed", lightness: -0.1, chroma: 0.2, hueShift: -4),
            ]
        case 75..<110:
            ideas = [
                ShiftPreset(name: "Golden", lightness: 0, chroma: 0.25, hueShift: -12),
                ShiftPreset(name: "Lemon", lightness: 0.1, chroma: 0.2, hueShift: 10),
            ]
        case 110..<175:
            ideas = [
                ShiftPreset(name: "Lush", lightness: -0.05, chroma: 0.35, hueShift: 4),
                ShiftPreset(name: "Teal", lightness: -0.05, chroma: -0.05, hueShift: 40),
                ShiftPreset(name: "Golden", lightness: 0.05, chroma: -0.1, hueShift: -40),
                ShiftPreset(name: "Olive", lightness: -0.15, chroma: -0.35, hueShift: -15),
            ]
        case 175..<230:
            ideas = [
                ShiftPreset(name: "Turquoise", lightness: 0.05, chroma: 0.25, hueShift: -15),
                ShiftPreset(name: "Deep sea", lightness: -0.3, chroma: 0.3, hueShift: 15),
            ]
        case 230..<300:
            ideas = [
                ShiftPreset(name: "Deep blue", lightness: -0.25, chroma: 0.3, hueShift: 5),
                ShiftPreset(name: "Turquoise", lightness: 0.05, chroma: 0.15, hueShift: -40),
                ShiftPreset(name: "Lavender", lightness: 0.1, chroma: -0.2, hueShift: 30),
            ]
        default:
            ideas = [
                ShiftPreset(name: "Coral", lightness: 0.05, chroma: 0, hueShift: 15),
                ShiftPreset(name: "Berry", lightness: -0.2, chroma: 0.15, hueShift: -15),
            ]
        }
        return ideas + [
            ShiftPreset(name: "Pop", lightness: 0, chroma: 0.4, hueShift: 0),
            ShiftPreset(name: "Muted", lightness: 0, chroma: -0.5, hueShift: 0),
            ShiftPreset(name: "Brighter", lightness: 0.35, chroma: 0, hueShift: 0),
            ShiftPreset(name: "Darker", lightness: -0.35, chroma: 0.1, hueShift: 0),
        ]
    }
}
