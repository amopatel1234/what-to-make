//
//  ImageCodec.swift
//  whattomake
//
//  Created by Amish Patel on 14/08/2025.
//


import UIKit

/// Image encoding and decoding utilities used by the app.
///
/// Provides helpers to resize images into a reasonable JPEG payload, create a
/// Base64-encoded thumbnail string for lightweight UI rendering, and decode
/// Base64 back into ``UIImage``.
///
/// Example
/// ```swift
/// if let data = ImageCodec.jpegData(image) {
///     let base64 = data.base64EncodedString()
///     let thumb = ImageCodec.base64JPEGThumbnail(from: image)
///     let ui = ImageCodec.image(fromBase64: base64)
/// }
/// ```
enum ImageCodec {
    /// Produces compressed JPEG data for the given image, optionally downscaling.
    /// - Parameters:
    ///   - image: Source image.
    ///   - maxDimension: Largest width/height to scale to while preserving aspect ratio. Defaults to 600.
    ///   - quality: JPEG compression quality in the range 0.0...1.0. Defaults to 0.7.
    /// - Returns: JPEG-encoded data, or `nil` if encoding fails.
    static func jpegData(_ image: UIImage, maxDimension: CGFloat = 600, quality: CGFloat = 0.7) -> Data? {
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }

        return resized.jpegData(compressionQuality: quality)
    }

    /// Generates a Base64-encoded JPEG thumbnail string from the image.
    /// - Parameter image: Source image to downscale and encode.
    /// - Returns: Base64 string or `nil` when encoding fails.
    static func base64JPEGThumbnail(from image: UIImage) -> String? {
        guard let data = jpegData(image) else { return nil }
        return data.base64EncodedString()
    }

    /// Decodes a Base64 string into a UIImage.
    /// - Parameter base64: Base64-encoded JPEG/PNG data.
    /// - Returns: A UIImage if decoding succeeds, otherwise `nil`.
    static func image(fromBase64 base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }
}

/// Errors thrown by ``ImageStore`` when image persistence fails.
enum ImageStoreError: Error {
    /// JPEG encoding failed while attempting to persist an image.
    case jpegEncodingFailed
}

/// Lightweight on-disk storage for original, full-resolution images.
///
/// Thumbnails are embedded on the model as Base64 strings, but original images
/// are stored on disk in the app container and referenced by filename.
///
/// Example
/// ```swift
/// let filename = try ImageStore.saveOriginal(image)
/// let original = ImageStore.loadOriginal(named: filename)
/// ImageStore.delete(named: filename)
/// ```
enum ImageStore {
    /// Directory for storing original images (created if needed).
    static var dir: URL {
        let fm = FileManager.default
        if let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let url = base.appendingPathComponent("Images", isDirectory: true)
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }
        // Fallback to temporary directory if application support is unavailable
        let tmp = fm.temporaryDirectory.appendingPathComponent("Images", isDirectory: true)
        try? fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        return tmp
    }

    /// Saves an original image to disk as JPEG.
    /// - Parameters:
    ///   - image: Image to write.
    ///   - quality: JPEG compression quality (0.0...1.0). Defaults to 0.85.
    /// - Returns: The generated filename for later retrieval.
    /// - Throws: ``ImageStoreError/jpegEncodingFailed`` if JPEG encoding fails, or file I/O errors.
    static func saveOriginal(_ image: UIImage, quality: CGFloat = 0.85) throws -> String {
        let name = "img_\(UUID().uuidString.prefix(8)).jpg"
        let url = dir.appendingPathComponent(name)
        guard let data = image.jpegData(compressionQuality: quality) else { throw ImageStoreError.jpegEncodingFailed }
        try data.write(to: url, options: .atomic)
        return name
    }

    /// Loads a previously saved original image by filename.
    /// - Parameter filename: The on-disk image filename returned by ``saveOriginal(_:quality:)``.
    /// - Returns: The UIImage if found and decoded, otherwise `nil`.
    static func loadOriginal(named filename: String) -> UIImage? {
        let url = dir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    /// Deletes the on-disk image file with the provided filename.
    /// - Parameter filename: The stored image filename.
    static func delete(named filename: String) {
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(filename))
    }
}
