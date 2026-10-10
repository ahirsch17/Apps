import CoreImage
import CoreImage.CIFilterBuiltins

/// Adjustments that depend on where a pixel is, not just its color, so they can't live in a LUT.
struct Effects: Codable, Hashable {
    var highlights: Float = 0   // 0...1, recovers bright skies and windows
    var shadows: Float = 0      // 0...1, lifts dark faces and backlit subjects
    var glow: Float = 0         // 0...1, soft bloom on highlights
    var vignette: Float = 0     // 0...1
    var grain: Float = 0        // 0...1

    static let none = Effects()

    var hasTone: Bool { highlights > 0 || shadows > 0 }
    var hasFinish: Bool { glow > 0 || vignette > 0 || grain > 0 }

    /// Runs before the look, like exposure fixes in a raw editor.
    func tone(_ image: CIImage) -> CIImage {
        guard hasTone else { return image }
        let extent = image.extent
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = image
        filter.highlightAmount = 1 - highlights * 0.7
        filter.shadowAmount = shadows * 0.8
        filter.radius = Float(max(extent.width, extent.height) * 0.01)
        return filter.outputImage?.cropped(to: extent) ?? image
    }

    /// Runs after all color work. `seed` changes grain per video frame so it moves like film.
    func finish(_ image: CIImage, seed: Int = 0) -> CIImage {
        guard hasFinish else { return image }
        let extent = image.extent
        let longest = max(extent.width, extent.height)
        var out = image

        if glow > 0 {
            let bloom = CIFilter.bloom()
            bloom.inputImage = out.clampedToExtent()
            bloom.radius = Float(longest * 0.015)
            bloom.intensity = glow * 0.6
            out = bloom.outputImage?.cropped(to: extent) ?? out
        }

        if vignette > 0 {
            let filter = CIFilter.vignetteEffect()
            filter.inputImage = out
            filter.center = CGPoint(x: extent.midX, y: extent.midY)
            filter.radius = Float(hypot(extent.width, extent.height) * 0.32)
            filter.intensity = vignette * 0.9
            filter.falloff = 0.7
            out = filter.outputImage?.cropped(to: extent) ?? out
        }

        if grain > 0, let noise = CIFilter.randomGenerator().outputImage {
            // Grain size follows the image size, so preview and full-res export look the same.
            let scale = max(1, longest / 1600)
            let offset = CGFloat(seed % 997) * 61
            let grainImage = noise
                .transformed(by: CGAffineTransform(translationX: offset, y: offset * 0.7))
                .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                .cropped(to: extent)
            let amplitude = CGFloat(grain * 0.22)
            let mono = CIFilter.colorMatrix()
            mono.inputImage = grainImage
            mono.rVector = CIVector(x: amplitude, y: 0, z: 0, w: 0)
            mono.gVector = CIVector(x: amplitude, y: 0, z: 0, w: 0)
            mono.bVector = CIVector(x: amplitude, y: 0, z: 0, w: 0)
            mono.aVector = CIVector(x: 0, y: 0, z: 0, w: 0)
            mono.biasVector = CIVector(x: 0.5 - amplitude / 2, y: 0.5 - amplitude / 2, z: 0.5 - amplitude / 2, w: 1)
            let overlay = CIFilter.overlayBlendMode()
            overlay.inputImage = mono.outputImage
            overlay.backgroundImage = out
            out = overlay.outputImage?.cropped(to: extent) ?? out
        }

        return out
    }
}

enum CropAspect: String, CaseIterable, Codable, Identifiable {
    case original = "Original"
    case portrait = "4:5"
    case square = "1:1"
    case story = "9:16"
    case wide = "16:9"
    case classic = "3:2"

    var id: Self { self }

    /// Width / height, or nil to keep the photo's own shape.
    var ratio: CGFloat? {
        switch self {
        case .original: return nil
        case .portrait: return 4.0 / 5.0
        case .square: return 1
        case .story: return 9.0 / 16.0
        case .wide: return 16.0 / 9.0
        case .classic: return 3.0 / 2.0
        }
    }

    var hint: String {
        switch self {
        case .original: return "Full photo"
        case .portrait: return "Instagram feed"
        case .square: return "Grid"
        case .story: return "Stories, Reels, TikTok"
        case .wide: return "YouTube, landscape"
        case .classic: return "Camera"
        }
    }
}

struct Crop: Codable, Hashable {
    var aspect: CropAspect = .original
    var center = SIMD2<Float>(0.5, 0.5)
    var zoom: Float = 1

    var isIdentity: Bool { aspect == .original && zoom <= 1.001 }

    /// The crop as a normalized rect (0...1, top-left origin) inside an image of `size`.
    func rect(for size: CGSize) -> CGRect {
        guard size.width > 0, size.height > 0 else { return CGRect(x: 0, y: 0, width: 1, height: 1) }
        let imageAspect = size.width / size.height
        let target = aspect.ratio ?? imageAspect
        var w: CGFloat = 1
        var h: CGFloat = 1
        if target > imageAspect {
            h = imageAspect / target
        } else {
            w = target / imageAspect
        }
        w /= CGFloat(max(zoom, 1))
        h /= CGFloat(max(zoom, 1))
        let cx = min(max(CGFloat(center.x), w / 2), 1 - w / 2)
        let cy = min(max(CGFloat(center.y), h / 2), 1 - h / 2)
        return CGRect(x: cx - w / 2, y: cy - h / 2, width: w, height: h)
    }

    /// Pixel rect in Core Image coordinates (bottom-left origin), with even dimensions so video encoders accept it.
    func pixelRect(in extent: CGRect) -> CGRect {
        let r = rect(for: extent.size)
        let width = max(2, (r.width * extent.width / 2).rounded(.down) * 2)
        let height = max(2, (r.height * extent.height / 2).rounded(.down) * 2)
        let x = (extent.minX + r.minX * extent.width).rounded()
        let y = (extent.minY + (1 - r.maxY) * extent.height).rounded()
        return CGRect(x: min(x, extent.maxX - width), y: min(y, extent.maxY - height), width: width, height: height)
    }

    func apply(_ image: CIImage) -> CIImage {
        guard !isIdentity else { return image }
        let rect = pixelRect(in: image.extent)
        return image.cropped(to: rect).transformed(by: CGAffineTransform(translationX: -rect.minX, y: -rect.minY))
    }
}
