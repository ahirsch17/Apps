import Foundation
import UIKit
import Vision

enum ScheduleImageOCR {
    enum OCRError: LocalizedError {
        case noText
        case recognitionFailed(String)

        var errorDescription: String? {
            switch self {
            case .noText:
                return "Couldn’t read any text from that image. Try a sharper screenshot or paste the schedule text."
            case let .recognitionFailed(message):
                return message
            }
        }
    }

    /// Reads schedule text from a screenshot or photo using on-device Vision OCR.
    static func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.normalizedCGImage() else {
            throw OCRError.recognitionFailed("Couldn’t process that image.")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                // Sort top-to-bottom, then left-to-right so tabular schedules stay readable.
                let ordered = observations.sorted { a, b in
                    let ay = a.boundingBox.origin.y
                    let by = b.boundingBox.origin.y
                    if abs(ay - by) > 0.015 { return ay > by } // Vision coords: origin bottom-left
                    return a.boundingBox.origin.x < b.boundingBox.origin.x
                }
                let lines = ordered
                    .compactMap { $0.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { $0.isEmpty == false }
                guard lines.isEmpty == false else {
                    continuation.resume(throwing: OCRError.noText)
                    return
                }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            if #available(iOS 16.0, *) {
                request.automaticallyDetectsLanguage = true
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                }
            }
        }
    }
}

private extension UIImage {
    /// Flatten orientation so Vision always sees upright pixels.
    func normalizedCGImage() -> CGImage? {
        if imageOrientation == .up, let cgImage { return cgImage }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let rendered = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
        return rendered.cgImage
    }
}
