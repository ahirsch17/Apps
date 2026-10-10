import Foundation
import simd

typealias RGB = SIMD3<Float>

/// Color conversions used to build LUTs. All RGB values are gamma-encoded sRGB in 0...1.
enum ColorMath {
    static func clamp01(_ c: RGB) -> RGB {
        simd_clamp(c, RGB(repeating: 0), RGB(repeating: 1))
    }

    static func luma(_ c: RGB) -> Float {
        simd_dot(c, RGB(0.2126, 0.7152, 0.0722))
    }

    static func mix(_ a: RGB, _ b: RGB, _ t: Float) -> RGB {
        a + (b - a) * t
    }

    static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }

    static func hueDistance(_ a: Float, _ b: Float) -> Float {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return min(d, 360 - d)
    }

    // MARK: HSV (hue in degrees)

    static func rgbToHSV(_ c: RGB) -> (h: Float, s: Float, v: Float) {
        let maxC = max(c.x, max(c.y, c.z))
        let minC = min(c.x, min(c.y, c.z))
        let delta = maxC - minC
        var h: Float = 0
        if delta > 1e-6 {
            if maxC == c.x {
                h = 60 * fmodf((c.y - c.z) / delta, 6)
            } else if maxC == c.y {
                h = 60 * ((c.z - c.x) / delta + 2)
            } else {
                h = 60 * ((c.x - c.y) / delta + 4)
            }
        }
        if h < 0 { h += 360 }
        let s: Float = maxC > 1e-6 ? delta / maxC : 0
        return (h, s, maxC)
    }

    static func hsvToRGB(h: Float, s: Float, v: Float) -> RGB {
        let hh = fmodf(fmodf(h, 360) + 360, 360) / 60
        let chroma = v * s
        let x = chroma * (1 - abs(fmodf(hh, 2) - 1))
        let m = v - chroma
        let rgb: RGB
        switch Int(hh) {
        case 0: rgb = RGB(chroma, x, 0)
        case 1: rgb = RGB(x, chroma, 0)
        case 2: rgb = RGB(0, chroma, x)
        case 3: rgb = RGB(0, x, chroma)
        case 4: rgb = RGB(x, 0, chroma)
        default: rgb = RGB(chroma, 0, x)
        }
        return rgb + RGB(repeating: m)
    }

    // MARK: CIE Lab / LCh (D65)

    static func srgbToLinear(_ v: Float) -> Float {
        v <= 0.04045 ? v / 12.92 : powf((v + 0.055) / 1.055, 2.4)
    }

    static func linearToSrgb(_ v: Float) -> Float {
        v <= 0.0031308 ? v * 12.92 : 1.055 * powf(v, 1 / 2.4) - 0.055
    }

    static func rgbToLab(_ c: RGB) -> RGB {
        let r = srgbToLinear(c.x)
        let g = srgbToLinear(c.y)
        let b = srgbToLinear(c.z)
        let x: Float = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
        let y: Float = 0.2126 * r + 0.7152 * g + 0.0722 * b
        let z: Float = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
        let fx = labF(x)
        let fy = labF(y)
        let fz = labF(z)
        return RGB(116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))
    }

    static func labToRGB(_ lab: RGB) -> RGB {
        let fy = (lab.x + 16) / 116
        let fx = fy + lab.y / 500
        let fz = fy - lab.z / 200
        let x = labFInverse(fx) * 0.95047
        let y = labFInverse(fy)
        let z = labFInverse(fz) * 1.08883
        let r: Float = 3.2406 * x - 1.5372 * y - 0.4986 * z
        let g: Float = -0.9689 * x + 1.8758 * y + 0.0415 * z
        let b: Float = 0.0557 * x - 0.2040 * y + 1.0570 * z
        return clamp01(RGB(linearToSrgb(max(r, 0)), linearToSrgb(max(g, 0)), linearToSrgb(max(b, 0))))
    }

    static func labToLCh(_ lab: RGB) -> RGB {
        let chroma = (lab.y * lab.y + lab.z * lab.z).squareRoot()
        var hue = atan2f(lab.z, lab.y) * 180 / .pi
        if hue < 0 { hue += 360 }
        return RGB(lab.x, chroma, hue)
    }

    static func lchToLab(_ lch: RGB) -> RGB {
        let radians = lch.z * .pi / 180
        return RGB(lch.x, lch.y * cosf(radians), lch.y * sinf(radians))
    }

    private static func labF(_ t: Float) -> Float {
        t > 0.008856 ? cbrtf(t) : 7.787 * t + 16 / 116
    }

    private static func labFInverse(_ t: Float) -> Float {
        let cube = t * t * t
        return cube > 0.008856 ? cube : (t - 16 / 116) / 7.787
    }

    // MARK: Skin

    /// 0...1 likelihood that a color is skin, used to keep faces natural under strong looks.
    static func skinWeight(_ c: RGB) -> Float {
        let hsv = rgbToHSV(c)
        let hue = 1 - smoothstep(14, 30, hueDistance(hsv.h, 22))
        let sat = smoothstep(0.1, 0.2, hsv.s) * (1 - smoothstep(0.6, 0.78, hsv.s))
        let value = smoothstep(0.18, 0.35, hsv.v)
        return hue * sat * value
    }
}
