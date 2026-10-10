import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

enum GradePipeline {
    static let context = CIContext(options: [.cacheIntermediates: false])
    static let sRGB = CGColorSpace(name: CGColorSpace.sRGB)!
    static let displayP3 = CGColorSpace(name: CGColorSpace.displayP3)!

    static func apply(_ lut: LUT, to image: CIImage) -> CIImage {
        let filter = CIFilter.colorCubeWithColorSpace()
        filter.inputImage = image
        filter.cubeDimension = Float(lut.size)
        filter.cubeData = lut.data
        filter.colorSpace = sRGB
        return filter.outputImage?.cropped(to: image.extent) ?? image
    }

    /// `amount` 0 keeps `original`, 1 is fully `graded`.
    static func mix(_ original: CIImage, _ graded: CIImage, amount: Float) -> CIImage {
        if amount >= 0.999 { return graded }
        if amount <= 0.001 { return original }
        let filter = CIFilter.dissolveTransition()
        filter.inputImage = original
        filter.targetImage = graded
        filter.time = amount
        return filter.outputImage?.cropped(to: original.extent) ?? graded
    }

    /// White areas of `mask` show `foreground`, black areas show `background`.
    static func blend(_ foreground: CIImage, over background: CIImage, mask: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = foreground
        filter.backgroundImage = background
        filter.maskImage = mask
        return filter.outputImage?.cropped(to: background.extent) ?? foreground
    }

    static func cgImage(_ image: CIImage, colorSpace: CGColorSpace = sRGB) -> CGImage? {
        context.createCGImage(image, from: image.extent, format: .RGBA8, colorSpace: colorSpace)
    }

    /// Moves the image so its extent starts at the origin. Masks assume this.
    static func normalized(_ image: CIImage) -> CIImage {
        let origin = image.extent.origin
        guard origin != .zero else { return image }
        return image.transformed(by: CGAffineTransform(translationX: -origin.x, y: -origin.y))
    }

    static func downscale(_ image: CIImage, maxDimension: CGFloat) -> CIImage {
        let longest = max(image.extent.width, image.extent.height)
        guard longest > maxDimension else { return image }
        let filter = CIFilter.lanczosScaleTransform()
        filter.inputImage = image
        filter.scale = Float(maxDimension / longest)
        filter.aspectRatio = 1
        return normalized(filter.outputImage ?? image)
    }

    /// Average color around a normalized point (0...1, top-left origin).
    static func sampleColor(_ image: CGImage, at point: SIMD2<Float>, radius: Int = 4) -> RGB? {
        let x = Int(Float(image.width) * point.x)
        let y = Int(Float(image.height) * point.y)
        let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2 + 1, height: radius * 2 + 1)
            .intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard !rect.isNull, rect.width >= 1, rect.height >= 1, let crop = image.cropping(to: rect) else { return nil }

        let w = crop.width, h = crop.height
        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        let drawn: Bool = pixels.withUnsafeMutableBytes { buffer in
            guard let ctx = CGContext(
                data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                space: sRGB, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            ctx.draw(crop, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return nil }

        var sum = RGB.zero
        for i in stride(from: 0, to: pixels.count, by: 4) {
            sum += RGB(Float(pixels[i]), Float(pixels[i + 1]), Float(pixels[i + 2]))
        }
        return sum / Float(w * h * 255)
    }
}

extension UIImage {
    convenience init?(rendering image: CIImage) {
        guard let cg = GradePipeline.cgImage(image) else { return nil }
        self.init(cgImage: cg)
    }
}
