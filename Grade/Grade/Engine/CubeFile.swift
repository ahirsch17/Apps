import Foundation
import simd
import UniformTypeIdentifiers

/// Reads and writes Adobe/Resolve `.cube` 3D LUT files.
enum CubeFile {
    struct ParseError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static var contentTypes: [UTType] {
        [UTType(filenameExtension: "cube"), .plainText, .data].compactMap { $0 }
    }

    static func parse(_ text: String) throws -> (title: String?, lut: LUT) {
        var size = 0
        var title: String?
        var domainMin = RGB(repeating: 0)
        var domainMax = RGB(repeating: 1)
        var rows: [Float] = []

        for rawLine in text.split(whereSeparator: \.isNewline) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" })
            guard let keyword = parts.first else { continue }

            switch keyword.uppercased() {
            case "TITLE":
                title = line.dropFirst(5).trimmingCharacters(in: CharacterSet(charactersIn: " \t\""))
            case "LUT_3D_SIZE":
                size = parts.count > 1 ? Int(parts[1]) ?? 0 : 0
            case "LUT_1D_SIZE":
                throw ParseError(message: "This is a 1D LUT. Grade needs a 3D .cube file.")
            case "DOMAIN_MIN":
                if let v = vector(parts) { domainMin = v }
            case "DOMAIN_MAX":
                if let v = vector(parts) { domainMax = v }
            case "LUT_3D_INPUT_RANGE", "LUT_1D_INPUT_RANGE":
                continue
            default:
                guard parts.count >= 3,
                      let r = Float(parts[0]), let g = Float(parts[1]), let b = Float(parts[2]) else { continue }
                rows.append(contentsOf: [r, g, b])
            }
        }

        guard size >= 2, size <= 128 else {
            throw ParseError(message: "Missing or unsupported LUT_3D_SIZE.")
        }
        guard rows.count == size * size * size * 3 else {
            throw ParseError(message: "Expected \(size * size * size) entries, found \(rows.count / 3).")
        }

        // .cube data is already red-fastest; scale the domain to 0...1 and add alpha.
        let span = simd_max(domainMax - domainMin, RGB(repeating: 1e-6))
        var values = [Float](repeating: 1, count: size * size * size * 4)
        for i in 0..<(size * size * size) {
            let raw = RGB(rows[i * 3], rows[i * 3 + 1], rows[i * 3 + 2])
            let v = ColorMath.clamp01((raw - domainMin) / span)
            values[i * 4] = v.x
            values[i * 4 + 1] = v.y
            values[i * 4 + 2] = v.z
        }
        return (title, LUT(size: size, values: values))
    }

    static func export(_ lut: LUT, title: String) -> String {
        var out = "TITLE \"\(title.replacingOccurrences(of: "\"", with: "'"))\"\n"
        out += "# Made with Grade\n"
        out += "LUT_3D_SIZE \(lut.size)\n\n"
        let count = lut.size * lut.size * lut.size
        out.reserveCapacity(count * 26)
        for i in 0..<count {
            let k = i * 4
            out += String(format: "%.6f %.6f %.6f\n", lut.values[k], lut.values[k + 1], lut.values[k + 2])
        }
        return out
    }

    private static func vector(_ parts: [Substring]) -> RGB? {
        guard parts.count >= 4, let r = Float(parts[1]), let g = Float(parts[2]), let b = Float(parts[3]) else {
            return nil
        }
        return RGB(r, g, b)
    }
}
