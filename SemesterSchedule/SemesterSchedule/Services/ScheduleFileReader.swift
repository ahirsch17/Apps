import Foundation
import PDFKit
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
    ]

    /// Loads schedule text from a security-scoped file URL. Images are not supported.
    static func readText(from url: URL) async throws -> String {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        let values = try url.resourceValues(forKeys: [.contentTypeKey, .typeIdentifierKey])
        let type = values.contentType ?? UTType(values.typeIdentifier ?? "")

        if let type, type.conforms(to: .pdf) {
            return try readPDF(url)
        }
        if let type, type.conforms(to: .image) {
            throw FileError.unreadable("Photos and screenshots aren’t supported yet. Paste the schedule text from the student portal.")
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
            return try requireNonEmpty(utf8)
        }
        if let latin1 = String(data: data, encoding: .isoLatin1) {
            return try requireNonEmpty(latin1)
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

    private static func readPDF(_ url: URL) throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw FileError.unreadable("Couldn’t open that PDF.")
        }

        var pageTexts: [String] = []
        for index in 0..<document.pageCount {
            guard let page = document.page(at: index) else { continue }
            if let raw = page.string?.trimmingCharacters(in: .whitespacesAndNewlines), raw.isEmpty == false {
                pageTexts.append(raw)
            }
        }

        let joined = pageTexts.joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard joined.isEmpty == false else {
            throw FileError.unreadable("That PDF has no copyable text. Paste the schedule from the student portal instead.")
        }
        return joined
    }

    private static func requireNonEmpty(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { throw FileError.empty }
        return trimmed
    }
}
