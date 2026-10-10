import AVFoundation
import CoreImage
import Observation
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

enum MediaKind {
    case photo, video
}

enum BaseChoice: Hashable {
    case original
    case look(String)
    /// Unsaved "match this photo" look, holding the reference photo's color stats.
    case match(ColorStats)
}

struct EditState: Hashable {
    var base: BaseChoice = .original
    var strength: Float = 1
    var protectSkin = true
    var tune = LookRecipe.neutral
    var effects = Effects.none
    var shifts: [ColorShift] = []
    var crop = Crop()

    var isEdited: Bool {
        base != .original || tune != .neutral || effects != .none || !crop.isIdentity
            || shifts.contains { !$0.params.isNeutral }
    }

    /// The parts of an edit that make sense on another photo from the same shoot.
    /// Drawn areas and crop position are photo-specific; color changes carry over by color, not by location.
    func transferable() -> EditState {
        var copy = self
        copy.shifts = shifts.filter { $0.strokes.isEmpty }.map {
            var shift = $0
            shift.samplePoint = nil
            return shift
        }
        copy.crop = Crop(aspect: crop.aspect)
        return copy
    }
}

@Observable
final class MediaItem: Identifiable {
    let id = UUID()
    let kind: MediaKind
    /// Local copy of the original file, used for full-quality export.
    let url: URL
    /// Display-size copy (about 1600 px) used for previews and color picking.
    let proxy: CGImage
    let thumbnail: CGImage
    let stats: ColorStats?
    let duration: Double

    var edit = EditState()
    var editedThumbnail: UIImage?

    init(kind: MediaKind, url: URL, proxy: CGImage, thumbnail: CGImage, duration: Double = 0) {
        self.kind = kind
        self.url = url
        self.proxy = proxy
        self.thumbnail = thumbnail
        self.stats = ColorStats.measure(proxy)
        self.duration = duration
    }

    var aspectRatio: CGFloat { CGFloat(proxy.width) / CGFloat(max(proxy.height, 1)) }
    var displayThumbnail: UIImage { editedThumbnail ?? UIImage(cgImage: thumbnail) }
}

@Observable
@MainActor
final class MediaStore {
    var items: [MediaItem] = []
    var importing = 0
    var progressLabel: String?
    var progress: Double = 0
    /// "Copy edit" clipboard for pasting a look onto other photos from the same shoot.
    var copiedEdit: EditState?

    func add(_ picks: [PhotosPickerItem]) async {
        importing += picks.count
        for pick in picks {
            if let item = await MediaImporter.load(pick) {
                items.append(item)
            }
            importing -= 1
        }
    }

    func remove(_ item: MediaItem) {
        items.removeAll { $0.id == item.id }
        try? FileManager.default.removeItem(at: item.url)
    }

    func removeAll() {
        for item in items { try? FileManager.default.removeItem(at: item.url) }
        items = []
    }

    func copyEdit(from item: MediaItem) {
        copiedEdit = item.edit.transferable()
    }

    /// Pastes the copied edit, keeping any drawn-area color fixes the target photo already has.
    func paste(_ edit: EditState, onto item: MediaItem, library: LookLibrary) {
        var pasted = edit
        pasted.shifts = item.edit.shifts.filter { !$0.strokes.isEmpty } + edit.shifts
        item.edit = pasted
        refreshThumbnail(item, library: library)
    }

    func pasteToAll(_ edit: EditState, except source: MediaItem? = nil, library: LookLibrary) {
        for item in items where item.id != source?.id {
            paste(edit, onto: item, library: library)
        }
    }

    func refreshThumbnail(_ item: MediaItem, library: LookLibrary) {
        guard item.edit.isEdited else {
            item.editedThumbnail = nil
            return
        }
        let template = JobTemplate.make(edit: item.edit, spec: library.spec(for: item.edit.base, item: item))
        let thumb = item.thumbnail
        let edit = item.edit
        Task.detached(priority: .utility) {
            let input = CIImage(cgImage: thumb)
            let output = template.job(for: input.extent.size).render(input)
            let image = UIImage(rendering: output)
            await MainActor.run {
                if item.edit == edit { item.editedThumbnail = image }
            }
        }
    }

    /// Saves every edited item to Photos. Returns how many saved and how many failed.
    func saveAllEdited(library: LookLibrary) async -> (saved: Int, failed: Int) {
        let edited = items.filter { $0.edit.isEdited }
        guard !edited.isEmpty else { return (0, 0) }
        var saved = 0
        var failed = 0
        for (index, item) in edited.enumerated() {
            progressLabel = "Saving \(index + 1) of \(edited.count)"
            progress = Double(index) / Double(edited.count)
            let template = JobTemplate.make(edit: item.edit, spec: library.spec(for: item.edit.base, item: item))
            do {
                try await Exporter.save(item: item, template: template) { fraction in
                    Task { @MainActor in
                        self.progress = (Double(index) + fraction) / Double(edited.count)
                    }
                }
                saved += 1
            } catch {
                failed += 1
            }
        }
        progressLabel = nil
        return (saved, failed)
    }
}

enum MediaImporter {
    static let proxySize: CGFloat = 1600
    static let thumbnailSize: CGFloat = 360

    static var importDirectory: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Imports", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func newFileURL(extension ext: String) -> URL {
        importDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
    }

    static func load(_ pick: PhotosPickerItem) async -> MediaItem? {
        if pick.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) {
            guard let movie = try? await pick.loadTransferable(type: Movie.self) else { return nil }
            return await makeVideo(url: movie.url)
        }
        guard let data = try? await pick.loadTransferable(type: Data.self) else { return nil }
        let ext = pick.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
        let url = newFileURL(extension: ext)
        do {
            try data.write(to: url)
        } catch {
            return nil
        }
        return await Task.detached(priority: .userInitiated) { MediaImporter.makePhoto(url: url) }.value
    }

    static func makePhoto(url: URL) -> MediaItem? {
        guard let source = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else { return nil }
        let oriented = GradePipeline.normalized(source)
        return makeItem(kind: .photo, url: url, frame: oriented)
    }

    static func makeVideo(url: URL) async -> MediaItem? {
        let asset = AVURLAsset(url: url)
        guard let duration = try? await asset.load(.duration) else { return nil }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: proxySize, height: proxySize)
        let seconds = duration.seconds.isFinite ? duration.seconds : 0
        let time = CMTime(seconds: seconds / 3, preferredTimescale: 600)
        guard let frame = try? await generator.image(at: time).image else { return nil }
        return makeItem(kind: .video, url: url, frame: CIImage(cgImage: frame), duration: seconds)
    }

    private static func makeItem(kind: MediaKind, url: URL, frame: CIImage, duration: Double = 0) -> MediaItem? {
        let proxyImage = GradePipeline.downscale(frame, maxDimension: proxySize)
        guard let proxy = GradePipeline.cgImage(proxyImage),
              let thumb = GradePipeline.cgImage(GradePipeline.downscale(proxyImage, maxDimension: thumbnailSize))
        else { return nil }
        return MediaItem(kind: kind, url: url, proxy: proxy, thumbnail: thumb, duration: duration)
    }
}

struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let copy = MediaImporter.newFileURL(extension: ext)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Movie(url: copy)
        }
    }
}
