//
//  ImageCodec.swift
//  whattomake
//
//  Created by Amish Patel on 14/08/2025.
//


import UIKit

enum ImageCodec {
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

    static func base64JPEGThumbnail(from image: UIImage) -> String? {
        guard let data = jpegData(image) else { return nil }
        return data.base64EncodedString()
    }

    static func image(fromBase64 base64: String) -> UIImage? {
        guard let data = Data(base64Encoded: base64) else { return nil }
        return UIImage(data: data)
    }
}

enum ImageStoreError: Error {
    case jpegEncodingFailed
}

enum ImageStore {
    // Directory for storing original images
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

    static func saveOriginal(_ image: UIImage, quality: CGFloat = 0.85) throws -> String {
        let name = "img_\(UUID().uuidString.prefix(8)).jpg"
        let url = dir.appendingPathComponent(name)
        guard let data = image.jpegData(compressionQuality: quality) else { throw ImageStoreError.jpegEncodingFailed }
        try data.write(to: url, options: .atomic)
        return name
    }

    static func loadOriginal(named filename: String) -> UIImage? {
        let url = dir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(named filename: String) {
        try? FileManager.default.removeItem(at: dir.appendingPathComponent(filename))
    }
}
