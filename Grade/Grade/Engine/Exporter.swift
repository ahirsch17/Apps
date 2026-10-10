import AVFoundation
import CoreImage
import ImageIO
import Photos

enum Exporter {
    struct ExportError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    /// Renders the edit at full quality to a temporary file (for Photos or the share sheet).
    static func render(item: MediaItem, template: JobTemplate, progress: @escaping (Double) -> Void = { _ in }) async throws -> URL {
        let source = item.url
        switch item.kind {
        case .photo:
            return try await Task.detached(priority: .userInitiated) {
                try Exporter.renderPhoto(source, template: template)
            }.value
        case .video:
            return try await renderVideo(source, template: template, progress: progress)
        }
    }

    static func save(item: MediaItem, template: JobTemplate, progress: @escaping (Double) -> Void = { _ in }) async throws {
        try await requestAccess()
        let output = try await render(item: item, template: template, progress: progress)
        defer { try? FileManager.default.removeItem(at: output) }
        let kind = item.kind
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            request.addResource(with: kind == .photo ? .photo : .video, fileURL: output, options: nil)
        }
        progress(1)
    }

    static func requestAccess() async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else {
            throw ExportError(message: "Allow Grade to add photos in Settings to save your edits.")
        }
    }

    /// Full-resolution JPEG with the original metadata (orientation is baked in, so it's reset to up).
    static func renderPhoto(_ url: URL, template: JobTemplate) throws -> URL {
        guard let loaded = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else {
            throw ExportError(message: "Couldn't read the original photo.")
        }
        let source = GradePipeline.normalized(loaded)
        var properties = loaded.properties
        properties[kCGImagePropertyOrientation as String] = 1
        if var tiff = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            tiff[kCGImagePropertyTIFFOrientation as String] = 1
            properties[kCGImagePropertyTIFFDictionary as String] = tiff
        }
        // The pixel size changes with crops, so drop the stale dimensions.
        properties[kCGImagePropertyPixelWidth as String] = nil
        properties[kCGImagePropertyPixelHeight as String] = nil
        if var exif = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            exif[kCGImagePropertyExifPixelXDimension as String] = nil
            exif[kCGImagePropertyExifPixelYDimension as String] = nil
            properties[kCGImagePropertyExifDictionary as String] = exif
        }

        let rendered = template.job(for: source.extent.size).render(source).settingProperties(properties)
        let colorSpace = source.colorSpace.flatMap { $0.model == .rgb ? $0 : nil } ?? GradePipeline.displayP3
        let quality = CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String)
        guard let data = GradePipeline.context.jpegRepresentation(of: rendered, colorSpace: colorSpace, options: [quality: 0.95]) else {
            throw ExportError(message: "Couldn't render the photo.")
        }
        let out = FileManager.default.temporaryDirectory.appendingPathComponent("Grade-\(UUID().uuidString.prefix(8))").appendingPathExtension("jpg")
        try data.write(to: out)
        return out
    }

    static func renderVideo(_ url: URL, template: JobTemplate, progress: @escaping (Double) -> Void) async throws -> URL {
        let asset = AVURLAsset(url: url)
        let composition = try await videoComposition(for: asset, template: template)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError(message: "This video can't be exported.")
        }
        let out = FileManager.default.temporaryDirectory.appendingPathComponent("Grade-\(UUID().uuidString.prefix(8))").appendingPathExtension("mov")
        session.outputURL = out
        session.outputFileType = .mov
        session.videoComposition = composition

        let poll = Task {
            while !Task.isCancelled {
                progress(Double(session.progress))
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
        await session.export()
        poll.cancel()

        guard session.status == .completed else {
            throw session.error ?? ExportError(message: "Video export failed.")
        }
        return out
    }

    /// Used both for export and for live playback in the editor.
    static func videoComposition(for asset: AVAsset, template: JobTemplate) async throws -> AVVideoComposition {
        let jobs = JobsBySize(template: template)
        let composition = try await AVVideoComposition.videoComposition(with: asset) { request in
            let frame = GradePipeline.normalized(request.sourceImage)
            let seed = Int(request.compositionTime.seconds * 30)
            let output = jobs.job(for: frame.extent.size).render(frame, seed: seed)
            request.finish(with: output, context: nil)
        }
        guard !template.crop.isIdentity,
              let mutable = composition.mutableCopy() as? AVMutableVideoComposition else { return composition }
        mutable.renderSize = template.crop.pixelRect(in: CGRect(origin: .zero, size: composition.renderSize)).size
        return mutable
    }
}

/// Masks depend on frame size, so rasterize them once per size instead of once per frame.
private final class JobsBySize {
    private let template: JobTemplate
    private var cached: (size: CGSize, job: RenderJob)?
    private let lock = NSLock()

    init(template: JobTemplate) {
        self.template = template
    }

    func job(for size: CGSize) -> RenderJob {
        lock.lock()
        defer { lock.unlock() }
        if let cached, cached.size == size { return cached.job }
        let job = template.job(for: size)
        cached = (size, job)
        return job
    }
}
