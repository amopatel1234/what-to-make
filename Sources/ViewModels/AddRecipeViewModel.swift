//
//  AddRecipeViewModel.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//  Updated by ChatGPT on 17/08/2025.
//
import Foundation
import Observation
import SwiftUI
import UIKit
import PhotosUI

/// A view model that powers the "Add Recipe" screen.
///
/// This type holds user input (name, notes), manages photo selection and preview,
/// and persists a recipe through ``RecipeRepository``. UI-observed state
/// is updated on the main actor to keep SwiftUI in sync.
@Observable
final class AddRecipeViewModel {
    var name = ""
    var notes = ""
    var selectedPhotoItem: PhotosPickerItem?
    var previewImage: UIImage?

    private(set) var thumbnailBase64: String?
    private(set) var imageFilename: String?
    var errorMessage: String?

    private let repository: RecipeRepository
    private let existingRecipe: Recipe?

    var isEditing: Bool { existingRecipe != nil }

    init(repository: RecipeRepository, existingRecipe: Recipe? = nil) {
        self.repository = repository
        self.existingRecipe = existingRecipe

        if let recipe = existingRecipe {
            self.name = recipe.name
            self.notes = recipe.notes ?? ""
            self.thumbnailBase64 = recipe.thumbnailBase64
            self.imageFilename = recipe.imageFilename
            if let thumb = recipe.thumbnailBase64 {
                self.previewImage = ImageCodec.image(fromBase64: thumb)
            }
        }
    }

    // Testable helper: process loaded image data and update state
    func handleLoadedImageData(_ data: Data) async {
        if let uiImage = UIImage(data: data) {
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
    }

    func loadSelectedImage() {
        guard let item = selectedPhotoItem else { return }
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    await handleLoadedImageData(data)
                } else {
                    await MainActor.run { self.errorMessage = "Could not load photo." }
                }
            } catch {
                await MainActor.run { self.errorMessage = "Failed to load photo." }
            }
        }
    }

    func saveRecipe() async -> Bool {
        do {
            if let recipe = existingRecipe {
                try await repository.updateRecipe(recipe,
                                                  name: name,
                                                  notes: notes.isEmpty ? nil : notes,
                                                  thumbnailBase64: thumbnailBase64,
                                                  imageFilename: imageFilename)
            } else {
                try await repository.addRecipe(name: name,
                                               notes: notes.isEmpty ? nil : notes,
                                               thumbnailBase64: thumbnailBase64,
                                               imageFilename: imageFilename)
            }
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
