import Foundation
import PDFKit
import UIKit
import UniformTypeIdentifiers

enum ScheduleFileReader {
    enum FileError: LocalizedError {
        case unsupportedType
        case empty
        case unreadable(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedType:
                return "Use a text file, CSV, RTF, or PDF of your schedule."
            case .empty:
                return "That file had no readable schedule text."
            case let .unreadable(message):
                return message
            }
        }
    }

    static let supportedTypes: [UTType] = [
        .plainText,
        .utf8PlainText,
        .text,
        .commaSeparatedText,
        .rtf,
        .pdf,
        .image,
        .jpeg,
        .png,
        .heic,
    ]

    /// Loads schedule text (or OCR from an image/PDF page) from a security-scoped file URL.
    static func readText(from url: URL) async throws -> String {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        let values = try url.resourceValues(forKeys: [.contentTypeKey, .typeIdentifierKey])
        let type = values.contentType ?? UTType(values.typeIdentifier ?? "")

        if let type, type.conforms(to: .pdf) {
            return try await readPDF(url)
        }
        if let type, type.conforms(to: .image) {
            return try await readImageFile(url)
        }
        if let type, type.conforms(to: .rtf) {
            return try readRTF(url)
        }
        // Default: treat as UTF-8 / Latin-1 text (Banner exports, CSV, etc.)
        return try readPlainText(url)
    }

    private static func readPlainText(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        if let utf8 = String(data: data, encoding: .utf8) {
            return requireNonEmpty(utf8)
        }
        if let latin1 = String(data: data, encoding: .isoLatin1) {
            return requireNonEmpty(latin1)
        }
        throw FileError.unreadable("Couldn’t decode that text file.")
    }

    private static func readRTF(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let attributed = try NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        )
        return try requireNonEmpty(attributed.string)
    }

    private static func readImageFile(_ url: URL) async throws -> String {
        let data = try Data(contentsOf: url)
        guard let image = UIImage(data: data) else {
            throw FileError.unreadable("Couldn’t open that image.")
        }
        return try await ScheduleImageOCR.recognizeText(in: image)
    }

    private static func readPDF(_ url: URL) async throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw FileError.unreadable("Couldn’t open that PDF.")
        }

        var pageTexts: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            if let raw = page.string?.trimmingCharacters(in: .whitespacesAndNewlines), raw.isEmpty == false {
                pageTexts.append(raw)
                continue
            }
            // Scanned / image-only page — rasterize and OCR.
            let bounds = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0
            let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { ctx in
                UIColor.white.setFill()
                ctx.fill(CGRect(origin: .zero, size: size))
                ctx.cgContext.saveGState()
                ctx.cgContext.translateBy(x: 0, y: size.height)
                ctx.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: ctx.cgContext)
                ctx.cgContext.restoreGState()
            }
            if let ocr = try? await ScheduleImageOCR.recognizeText(in: image) {
                pageTexts.append(ocr)
            }
        }

        return try requireNonEmpty(pageTexts.joined(separator: "\n\n"))
    }

    private static func requireNonEmpty(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { throw FileError.empty }
        return trimmed
    }
}
