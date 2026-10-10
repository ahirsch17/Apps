import AVFoundation
import CoreImage
import ImageIO
import Photos

enum Exporter {
    struct ExportError: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    static func save(item: MediaItem, template: JobTemplate, progress: @escaping (Double) -> Void = { _ in }) async throws {
        try await requestAccess()
        let kind = item.kind
        let source = item.url
        let output: URL
        switch kind {
        case .photo:
            output = try await Task.detached(priority: .userInitiated) {
                try Exporter.renderPhoto(source, template: template)
            }.value
        case .video:
            output = try await renderVideo(source, template: template, progress: progress)
        }
        defer { try? FileManager.default.removeItem(at: output) }
        try await PHPhotoLibrary.shared().performChanges {
            let request = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = false
            request.addResource(with: kind == .photo ? .photo : .video, fileURL: output, options: options)
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

        let rendered = template.job(for: source.extent.size).render(source).settingProperties(properties)
        let colorSpace = source.colorSpace.flatMap { $0.model == .rgb ? $0 : nil } ?? GradePipeline.displayP3
        let quality = CIImageRepresentationOption(rawValue: kCGImageDestinationLossyCompressionQuality as String)
        guard let data = GradePipeline.context.jpegRepresentation(of: rendered, colorSpace: colorSpace, options: [quality: 0.95]) else {
            throw ExportError(message: "Couldn't render the photo.")
        }
        let out = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
        try data.write(to: out)
        return out
    }

    static func renderVideo(_ url: URL, template: JobTemplate, progress: @escaping (Double) -> Void) async throws -> URL {
        let asset = AVURLAsset(url: url)
        let composition = try await videoComposition(for: asset, template: template)
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError(message: "This video can't be exported.")
        }
        let out = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
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
        return try await AVVideoComposition.videoComposition(with: asset) { request in
            let frame = GradePipeline.normalized(request.sourceImage)
            let output = jobs.job(for: frame.extent.size).render(frame)
            request.finish(with: output, context: nil)
        }
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
