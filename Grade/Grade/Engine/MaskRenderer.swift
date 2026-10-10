import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

/// Turns finger strokes into a soft grayscale mask the size of the image.
enum MaskRenderer {
    /// Returns nil when there are no strokes, which means "apply everywhere".
    static func mask(strokes: [MaskStroke], feather: Float, size target: CGSize) -> CIImage? {
        guard !strokes.isEmpty, target.width >= 1, target.height >= 1 else { return nil }

        // Masks are soft, so rasterize at most 2048 px and scale up rather than allocating a 48 MP bitmap.
        let scale = min(1, 2048 / max(target.width, target.height))
        let size = CGSize(width: (target.width * scale).rounded(), height: (target.height * scale).rounded())

        // Erasing first (with nothing drawn yet) means "everywhere except here".
        let startsFilled = strokes.allSatisfy(\.erase)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { ctx in
            let cg = ctx.cgContext
            cg.setFillColor(startsFilled ? UIColor.white.cgColor : UIColor.black.cgColor)
            cg.fill(CGRect(origin: .zero, size: size))
            cg.setLineCap(.round)
            cg.setLineJoin(.round)

            for stroke in strokes {
                let color = stroke.erase ? UIColor.black.cgColor : UIColor.white.cgColor
                let points = stroke.points.map { CGPoint(x: CGFloat($0.x) * size.width, y: CGFloat($0.y) * size.height) }
                guard let first = points.first else { continue }
                let path = CGMutablePath()
                path.move(to: first)
                for p in points.dropFirst() { path.addLine(to: p) }

                switch stroke.kind {
                case .lasso:
                    path.closeSubpath()
                    cg.addPath(path)
                    cg.setFillColor(color)
                    cg.fillPath()
                case .brush:
                    let width = max(CGFloat(stroke.radius) * 2 * size.width, 1)
                    if points.count == 1 {
                        cg.setFillColor(color)
                        cg.fillEllipse(in: CGRect(x: first.x - width / 2, y: first.y - width / 2, width: width, height: width))
                    } else {
                        cg.addPath(path)
                        cg.setStrokeColor(color)
                        cg.setLineWidth(width)
                        cg.strokePath()
                    }
                }
            }
        }

        guard let cgImage = image.cgImage else { return nil }
        var mask = CIImage(cgImage: cgImage)
        let blurRadius = Float(size.width) * feather
        if blurRadius > 0.5 {
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = mask.clampedToExtent()
            blur.radius = blurRadius
            mask = blur.outputImage ?? mask
        }
        if size != target {
            let sx = target.width / size.width
            let sy = target.height / size.height
            mask = mask.clampedToExtent().transformed(by: CGAffineTransform(scaleX: sx, y: sy))
        }
        return mask.cropped(to: CGRect(origin: .zero, size: target))
    }
}
