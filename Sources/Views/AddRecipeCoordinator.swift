//
//  AddRecipeCoordinator.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Observation
import PhotosUI
import SwiftData
import SwiftUI
import UIKit

/// Transient ingredient row state for the add/edit recipe form.
struct IngredientDraft: Identifiable, Equatable {
    let id: UUID
    var name: String
    var amountText: String
    var selectedUnit: String
    var customUnit: String
    var usesCustomUnit: Bool

    init(
        id: UUID = UUID(),
        name: String = "",
        amountText: String = "",
        selectedUnit: String = "",
        customUnit: String = "",
        usesCustomUnit: Bool = false
    ) {
        self.id = id
        self.name = name
        self.amountText = amountText
        self.selectedUnit = selectedUnit
        self.customUnit = customUnit
        self.usesCustomUnit = usesCustomUnit
    }

    var resolvedUnit: String {
        usesCustomUnit ? customUnit : selectedUnit
    }

    var isBlank: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && resolvedUnit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

@MainActor
@Observable
final class AddRecipeCoordinator {
    var name = ""
    var notes = ""
    var containsMeat = false
    var ingredientDrafts: [IngredientDraft] = []
    var selectedPhotoItem: PhotosPickerItem?
    var previewImage: UIImage?
    var thumbnailBase64: String?
    var imageFilename: String?
    var errorMessage: String?
    var isSaving = false
    private var pendingRecipe: Recipe?

    func loadExistingRecipe(from recipe: Recipe) {
        name = recipe.name
        notes = recipe.notes ?? ""
        containsMeat = recipe.containsMeat
        thumbnailBase64 = recipe.thumbnailBase64
        imageFilename = recipe.imageFilename
        ingredientDrafts = recipe.ingredients
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { ingredient in
                let unit = ingredient.unit ?? ""
                let isPreset = IngredientUnitOption.presetUnits.contains(unit)
                return IngredientDraft(
                    name: ingredient.name,
                    amountText: ingredient.amount.map(formatIngredientAmount) ?? "",
                    selectedUnit: isPreset ? unit : "",
                    customUnit: isPreset ? "" : unit,
                    usesCustomUnit: !unit.isEmpty && !isPreset
                )
            }
        if let thumbnailBase64 = recipe.thumbnailBase64 {
            previewImage = ImageCodec.image(fromBase64: thumbnailBase64)
        }
    }

    func addIngredient() {
        ingredientDrafts.append(IngredientDraft())
    }

    func removeIngredient(id: UUID) {
        ingredientDrafts.removeAll { $0.id == id }
    }

    func loadSelectedImage() {
        guard let item = selectedPhotoItem else { return }
        Task { @MainActor in
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    await handleLoadedImageData(data)
                } else {
                    errorMessage = "Could not load photo."
                }
            } catch {
                errorMessage = "Failed to load photo."
            }
        }
    }

    func handleLoadedImageData(_ data: Data) async {
        if let uiImage = UIImage(data: data) {
            let thumbnail = ImageCodec.base64JPEGThumbnail(from: uiImage)
            let filename = try? ImageStore.saveOriginal(uiImage)
            previewImage = uiImage
            thumbnailBase64 = thumbnail
            imageFilename = filename
            errorMessage = nil
        } else {
            errorMessage = "Could not load photo."
        }
    }

    func save(existingRecipe: Recipe?, in context: ModelContext) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }

        if existingRecipe == nil {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                errorMessage = "Recipe name is required."
                return false
            }
        }

        let validDrafts = ingredientDrafts.filter { !$0.isBlank }
        for draft in validDrafts where draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Each ingredient needs a name."
            return false
        }

        do {
            let recipe: Recipe
            if let existingRecipe {
                recipe = existingRecipe
                recipe.name = name
                recipe.notes = notes
                recipe.containsMeat = containsMeat
                recipe.thumbnailBase64 = thumbnailBase64
                recipe.imageFilename = imageFilename
            } else if let pendingRecipe {
                recipe = pendingRecipe
                recipe.name = name.trimmingCharacters(in: .whitespaces)
                recipe.notes = notes.isEmpty ? nil : notes
                recipe.containsMeat = containsMeat
                recipe.thumbnailBase64 = thumbnailBase64
                recipe.imageFilename = imageFilename
            } else {
                recipe = Recipe(
                    name: name.trimmingCharacters(in: .whitespaces),
                    notes: notes.isEmpty ? nil : notes,
                    thumbnailBase64: thumbnailBase64,
                    imageFilename: imageFilename,
                    containsMeat: containsMeat
                )
                context.insert(recipe)
                pendingRecipe = recipe
            }

            try syncIngredients(validDrafts, to: recipe, in: context)
            try context.save()
            pendingRecipe = nil
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    private func syncIngredients(
        _ drafts: [IngredientDraft],
        to recipe: Recipe,
        in context: ModelContext
    ) throws {
        for ingredient in recipe.ingredients {
            context.delete(ingredient)
        }
        recipe.ingredients = []

        for (index, draft) in drafts.enumerated() {
            let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedUnit = draft.resolvedUnit.trimmingCharacters(in: .whitespacesAndNewlines)
            let ingredient = RecipeIngredient(
                name: trimmedName,
                amount: parseIngredientAmount(draft.amountText),
                unit: trimmedUnit.isEmpty ? nil : trimmedUnit,
                sortOrder: index
            )
            ingredient.recipe = recipe
            recipe.ingredients.append(ingredient)
            context.insert(ingredient)
        }
    }
}
