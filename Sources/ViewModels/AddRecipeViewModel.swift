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

/// A view model that powers the "Add Recipe" screen.
///
/// This type holds user input (name, notes), manages photo selection and preview,
/// and persists a new recipe through ``AddRecipeUseCase``. UI-observed state
/// is updated on the main actor to keep SwiftUI in sync.
///
/// Responsibilities
/// - Validate and store basic fields for a recipe (no ingredients).
/// - Load a selected photo via ``PhotosPickerItem`` and generate a Base64 thumbnail.
/// - Persist a recipe using the injected use case.
///
/// Example
/// ```swift
/// let vm = AddRecipeViewModel(addRecipeUseCase: addRecipe)
/// vm.name = "Pasta"
/// vm.notes = "Family favorite"
/// // After the user picks a photo, call vm.loadSelectedImage()
/// let success = await vm.saveRecipe()
/// ```
@Observable
final class AddRecipeViewModel {
    /// The required recipe name entered by the user.
    var name = ""
    /// Optional notes for the recipe.
    var notes = ""
    /// The currently selected photo from the system photo picker, if any.
    var selectedPhotoItem: PhotosPickerItem?
    /// A preview image displayed in the UI after loading a photo.
    var previewImage: UIImage?

    /// A Base64-encoded JPEG thumbnail generated from the selected image.
    private(set) var thumbnailBase64: String?
    /// The persisted filename of the original full-resolution image, if saved.
    private(set) var imageFilename: String?
    /// A user-presentable error message for validation or load/save failures.
    var errorMessage: String?

    private let addRecipeUseCase: AddRecipeUseCase
    private let updateRecipeUseCase: UpdateRecipesUseCase?
    private let existingRecipe: Recipe?
    
    var isEditing: Bool {
        existingRecipe != nil
    }

    /// Creates a new instance with its required dependency.
    /// - Parameter addRecipeUseCase: The use case responsible for persisting recipes.
    init(addRecipeUseCase: AddRecipeUseCase,
         updateRecipeUseCase: UpdateRecipesUseCase? = nil,
         existingRecipe: Recipe? = nil) {
        self.addRecipeUseCase = addRecipeUseCase
        self.updateRecipeUseCase = updateRecipeUseCase
        self.existingRecipe = existingRecipe
        
        if let recipe = existingRecipe {
            self.name = recipe.name
            self.notes = recipe.notes ?? ""
            self.thumbnailBase64 = recipe.thumbnailBase64
            self.imageFilename = recipe.imageFilename
            if let thumbnailBase64 = recipe.thumbnailBase64 {
                self.previewImage = ImageCodec.image(fromBase64: thumbnailBase64)
            }
            
        }
    }

    /// Processes raw image data loaded from the photo picker and updates UI state.
    ///
    /// Converts the data into a UIImage, generates a thumbnail (Base64), saves the
    /// original image to disk (capturing its filename), and clears any previous error.
    /// If the data cannot be decoded, sets an appropriate error message.
    /// - Parameter data: The raw image bytes returned by the photo picker.
    /// - Note: This method marshals state updates to the main actor.
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

    /// Loads the currently selected photo from the photo picker.
    ///
    /// When ``selectedPhotoItem`` is set, this method fetches its data asynchronously,
    /// then delegates to ``handleLoadedImageData(_:)`` for processing. If the item is
    /// `nil` or cannot be loaded, an error message is set.
    /// - Important: Triggers an asynchronous task; safe to call from the main thread.
    func loadSelectedImage() {
        guard let item = selectedPhotoItem else { return }
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    await handleLoadedImageData(data)
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

    /// Persists a new recipe using the current state.
    ///
    /// Passes name, notes, and any image metadata to the ``AddRecipeUseCase``.
    /// Clears ``errorMessage`` on success, or sets it to a user-visible description
    /// on failure.
    /// - Returns: `true` when the recipe was saved successfully; otherwise `false`.
    func saveRecipe() async -> Bool {
        do {
            if let recipe = existingRecipe, let updateUseCase = updateRecipeUseCase {
                try await updateUseCase.execute(recipe: recipe, name: name, notes: notes, thumbnailBase64: thumbnailBase64, imageFilename: imageFilename)
            } else {
                try await addRecipeUseCase.execute(name: name, notes: notes.isEmpty ? nil : notes, thumbnailBase64: thumbnailBase64, imageFilename: imageFilename)
            }
            
            await MainActor.run {
                self.errorMessage = nil
            }
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }

    /// Resets the view model to its initial state.
    ///
    /// Clears text fields, image selection and previews, image metadata, and errors.
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
