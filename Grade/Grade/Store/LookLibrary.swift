import Foundation
import Observation

struct Look: Identifiable, Hashable {
    enum Source: Hashable {
        case recipe(LookRecipe)
        case lut(LUT)
        /// Matches each photo to a reference photo's color, so it adapts per photo instead of being fixed.
        case match(ColorStats)
    }

    let id: String
    var name: String
    var source: Source

    var isBuiltIn: Bool { id.hasPrefix("builtin.") }
}

/// Built-in looks plus the user's saved looks (imported .cube files, baked edits, matched photos).
@Observable
@MainActor
final class LookLibrary {
    let builtIns = BuiltInLooks.all
    private(set) var custom: [Look] = []

    private struct Stored: Codable {
        var id: String
        var name: String
        var stats: ColorStats?
    }

    private let directory: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Looks", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private var indexURL: URL { directory.appendingPathComponent("looks.json") }

    init() {
        load()
    }

    func look(_ id: String) -> Look? {
        custom.first(where: { $0.id == id }) ?? builtIns.first(where: { $0.id == id })
    }

    func name(for choice: BaseChoice) -> String {
        switch choice {
        case .original: return "Original"
        case .look(let id): return look(id)?.name ?? "Look"
        case .match: return "Matched"
        }
    }

    func spec(for choice: BaseChoice, item: MediaItem) -> BaseSpec {
        switch choice {
        case .original:
            return .identity
        case .match(let reference):
            return matchSpec(item: item, reference: reference)
        case .look(let id):
            switch look(id)?.source {
            case .recipe(let recipe): return .recipe(recipe)
            case .lut(let lut): return .lut(lut)
            case .match(let reference): return matchSpec(item: item, reference: reference)
            case nil: return .identity
            }
        }
    }

    private func matchSpec(item: MediaItem, reference: ColorStats) -> BaseSpec {
        guard let stats = item.stats else { return .identity }
        return .match(source: stats, reference: reference)
    }

    @discardableResult
    func importCube(from url: URL) throws -> Look {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let text = try String(contentsOf: url, encoding: .utf8)
        let parsed = try CubeFile.parse(text)
        let fallback = url.deletingPathExtension().lastPathComponent
        return try addLUT(name: parsed.title?.isEmpty == false ? parsed.title! : fallback, lut: parsed.lut)
    }

    @discardableResult
    func addLUT(name: String, lut: LUT) throws -> Look {
        let look = Look(id: "custom.\(UUID().uuidString)", name: name, source: .lut(lut))
        try lut.data.write(to: lutURL(look.id), options: .atomic)
        custom.insert(look, at: 0)
        save()
        return look
    }

    @discardableResult
    func addMatch(name: String, stats: ColorStats) -> Look {
        let look = Look(id: "custom.\(UUID().uuidString)", name: name, source: .match(stats))
        custom.insert(look, at: 0)
        save()
        return look
    }

    func rename(_ look: Look, to name: String) {
        guard let index = custom.firstIndex(where: { $0.id == look.id }), !name.isEmpty else { return }
        custom[index].name = name
        save()
    }

    func delete(_ look: Look) {
        custom.removeAll { $0.id == look.id }
        try? FileManager.default.removeItem(at: lutURL(look.id))
        save()
    }

    private func lutURL(_ id: String) -> URL {
        directory.appendingPathComponent(id).appendingPathExtension("lut")
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let stored = try? JSONDecoder().decode([Stored].self, from: data) else { return }
        custom = stored.compactMap { entry in
            if let stats = entry.stats {
                return Look(id: entry.id, name: entry.name, source: .match(stats))
            }
            guard let data = try? Data(contentsOf: lutURL(entry.id)), let lut = LUT(binary: data) else { return nil }
            return Look(id: entry.id, name: entry.name, source: .lut(lut))
        }
    }

    private func save() {
        let stored = custom.compactMap { look -> Stored? in
            switch look.source {
            case .lut: return Stored(id: look.id, name: look.name, stats: nil)
            case .match(let stats): return Stored(id: look.id, name: look.name, stats: stats)
            case .recipe: return nil
            }
        }
        if let data = try? JSONEncoder().encode(stored) {
            try? data.write(to: indexURL, options: .atomic)
        }
    }
}
