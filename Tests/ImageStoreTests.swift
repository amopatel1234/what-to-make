//
//  ImageStoreTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import Testing
import UIKit

@MainActor
@Suite
struct ImageStoreTests {
    private func makeSampleImage(dimension: CGFloat = 40) -> UIImage {
        let size = CGSize(width: dimension, height: dimension)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func withTemporaryImageDirectory(
        _ body: () throws -> Void
    ) throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "ForkPlanImageStore-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        ImageStore.directoryOverride = directory
        defer {
            ImageStore.directoryOverride = nil
            try? FileManager.default.removeItem(at: directory)
        }
        try body()
    }

    @Test
    func jpegDataDownscalesLargeImages() {
        let maxDimension: CGFloat = 600
        let image = makeSampleImage(dimension: 1_200)
        let data = ImageCodec.jpegData(image, maxDimension: maxDimension, quality: 0.8)
        #expect(data != nil)
        #expect((data?.count ?? 0) > 0)

        guard let data, let decoded = UIImage(data: data) else {
            Issue.record("Expected JPEG data to decode")
            return
        }
        // JPEG-decoded UIImage uses scale 1; size is in pixels.
        let pixelMaxSide = max(decoded.size.width, decoded.size.height) * decoded.scale
        #expect(pixelMaxSide <= maxDimension + 0.5)
        #expect(pixelMaxSide < 1_200)
    }

    @Test
    func base64ThumbnailRoundTrips() {
        let image = makeSampleImage()
        let base64 = ImageCodec.base64JPEGThumbnail(from: image)
        #expect(base64 != nil)

        guard let base64 else { return }
        #expect(ImageCodec.image(fromBase64: base64) != nil)
    }

    @Test
    func imageFromInvalidBase64ReturnsNil() {
        #expect(ImageCodec.image(fromBase64: "not-valid-base64!!!") == nil)
    }

    @Test
    func saveLoadDeleteOriginalRoundTrip() throws {
        try withTemporaryImageDirectory {
            let image = makeSampleImage()
            let filename = try ImageStore.saveOriginal(image)
            #expect(filename.hasPrefix("img_"))
            #expect(filename.hasSuffix(".jpg"))

            let loaded = ImageStore.loadOriginal(named: filename)
            #expect(loaded != nil)

            ImageStore.delete(named: filename)
            #expect(ImageStore.loadOriginal(named: filename) == nil)
        }
    }

    @Test
    func deleteMissingFileDoesNotThrow() throws {
        try withTemporaryImageDirectory {
            ImageStore.delete(named: "img_missing.jpg")
            #expect(ImageStore.loadOriginal(named: "img_missing.jpg") == nil)
        }
    }
}
