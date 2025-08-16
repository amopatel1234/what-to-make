//
//  AddRecipeViewModel.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//

import Foundation
import Observation
import SwiftUI
import UIKit
import PhotosUI

@Observable
final class AddRecipeViewModel {
    var name = ""
    var notes = ""
    var selectedPhotoItem: PhotosPickerItem?
    var previewImage: UIImage?

    private(set) var thumbnailBase64: String?
    private(set) var imageFilename: String?
    var errorMessage: String?

    private let addRecipeUseCase: AddRecipeUseCase

    init(addRecipeUseCase: AddRecipeUseCase) {
        self.addRecipeUseCase = addRecipeUseCase
    }

    func loadSelectedImage() {
        guard let item = selectedPhotoItem else { return }
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    let thumbnail = ImageCodec.base64JPEGThumbnail(from: uiImage)
                    let filename = try? ImageStore.saveOriginal(uiImage)
                    await MainActor.run {
                        self.previewImage = uiImage
                        self.thumbnailBase64 = thumbnail
                        self.imageFilename = filename
                        self.errorMessage = nil
                    }
                } else {
                    await MainActor.run {
                        self.errorMessage = "Could not load photo."
                    }
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load photo."
                }
            }
        }
    }

    func saveRecipe() async -> Bool {
        do {
            try await addRecipeUseCase.execute(name: name, notes: notes.isEmpty ? nil : notes, thumbnailBase64: thumbnailBase64, imageFilename: imageFilename)
            await MainActor.run { self.errorMessage = nil }
            return true
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
            return false
        }
    }

    func reset() {
        name = ""
        notes = ""
        selectedPhotoItem = nil
        previewImage = nil
        thumbnailBase64 = nil
        imageFilename = nil
        errorMessage = nil
    }
}
