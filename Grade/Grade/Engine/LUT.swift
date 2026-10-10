import Foundation

/// A 3D color lookup table. Entries are RGBA Float32 with red varying fastest,
/// then green, then blue: the layout Core Image's color cube filters expect.
struct LUT: Hashable {
    let id = UUID()
    let size: Int
    let values: [Float]
    let data: Data

    init(size: Int, values: [Float]) {
        self.size = size
        self.values = values
        self.data = values.withUnsafeBufferPointer { Data(buffer: $0) }
    }

    /// Reads the raw Float32 RGBA format written by `data`.
    init?(binary: Data) {
        let count = binary.count / MemoryLayout<Float>.size
        let size = Int(cbrt(Double(count / 4)).rounded())
        guard size >= 2, size * size * size * 4 == count else { return nil }
        var values = [Float](repeating: 0, count: count)
        _ = values.withUnsafeMutableBytes { binary.copyBytes(to: $0) }
        self.init(size: size, values: values)
    }

    static func == (lhs: LUT, rhs: LUT) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    static func build(size: Int = 33, _ transform: (RGB) -> RGB) -> LUT {
        let n = size
        var values = [Float](repeating: 0, count: n * n * n * 4)
        let step = 1 / Float(n - 1)
        var i = 0
        for b in 0..<n {
            for g in 0..<n {
                for r in 0..<n {
                    let input = RGB(Float(r) * step, Float(g) * step, Float(b) * step)
                    let out = ColorMath.clamp01(transform(input))
                    values[i] = out.x
                    values[i + 1] = out.y
                    values[i + 2] = out.z
                    values[i + 3] = 1
                    i += 4
                }
            }
        }
        return LUT(size: n, values: values)
    }

    /// Trilinear lookup, used when composing a LUT with other color math.
    func sample(_ color: RGB) -> RGB {
        let n = size
        let maxIndex = Float(n - 1)
        let p = ColorMath.clamp01(color) * maxIndex
        let r0 = min(Int(p.x), n - 1), g0 = min(Int(p.y), n - 1), b0 = min(Int(p.z), n - 1)
        let r1 = min(r0 + 1, n - 1), g1 = min(g0 + 1, n - 1), b1 = min(b0 + 1, n - 1)
        let fr = p.x - Float(r0), fg = p.y - Float(g0), fb = p.z - Float(b0)

        func at(_ r: Int, _ g: Int, _ b: Int) -> RGB {
            let k = ((b * n + g) * n + r) * 4
            return RGB(values[k], values[k + 1], values[k + 2])
        }

        let c00 = ColorMath.mix(at(r0, g0, b0), at(r1, g0, b0), fr)
        let c10 = ColorMath.mix(at(r0, g1, b0), at(r1, g1, b0), fr)
        let c01 = ColorMath.mix(at(r0, g0, b1), at(r1, g0, b1), fr)
        let c11 = ColorMath.mix(at(r0, g1, b1), at(r1, g1, b1), fr)
        let c0 = ColorMath.mix(c00, c10, fg)
        let c1 = ColorMath.mix(c01, c11, fg)
        return ColorMath.mix(c0, c1, fb)
    }
}

/// Thread-safe cache so sliders and video frames reuse LUTs instead of rebuilding them.
final class LUTCache {
    static let shared = LUTCache()

    private struct Key: Hashable {
        let kind: String
        let value: AnyHashable
    }

    private var store: [Key: LUT] = [:]
    private var order: [Key] = []
    private let lock = NSLock()
    private let capacity = 48

    let dim = LUT.build(size: 17) { RGB(repeating: ColorMath.luma($0) * 0.3) }

    func base(_ spec: BaseSpec, protectSkin: Bool) -> LUT {
        if case .lut(let imported) = spec, !protectSkin { return imported }
        let look = spec.transform()
        return lut(Key(kind: protectSkin ? "base.skin" : "base", value: spec), size: 33) { c in
            let graded = look(c)
            guard protectSkin else { return graded }
            return ColorMath.mix(c, graded, 1 - 0.6 * ColorMath.skinWeight(c))
        }
    }

    func tune(_ recipe: LookRecipe) -> LUT {
        lut(Key(kind: "tune", value: recipe), size: 25, recipe.apply)
    }

    func shift(_ params: ShiftParams) -> LUT {
        lut(Key(kind: "shift", value: params), size: 33, params.transform())
    }

    /// Shows the selected colors as-is and everything else as dim gray.
    func selection(_ params: ShiftParams) -> LUT {
        let weight = params.weight()
        return lut(Key(kind: "selection", value: params), size: 33) { c in
            ColorMath.mix(RGB(repeating: ColorMath.luma(c) * 0.3), c, weight(c))
        }
    }

    private func lut(_ key: Key, size: Int, _ transform: (RGB) -> RGB) -> LUT {
        lock.lock()
        if let hit = store[key] {
            lock.unlock()
            return hit
        }
        lock.unlock()

        let built = LUT.build(size: size, transform)

        lock.lock()
        defer { lock.unlock() }
        if let existing = store[key] { return existing }
        store[key] = built
        order.append(key)
        if order.count > capacity {
            store[order.removeFirst()] = nil
        }
        return built
    }
}
