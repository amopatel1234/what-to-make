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
    var dietaryKind: RecipeDietaryKind = .standard
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
        dietaryKind = recipe.dietaryKind
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

    /// Persists a new or existing recipe (and its ingredient lines) into `context`.
    ///
    /// - Returns: `true` when the store save succeeds; `false` when validation fails
    ///   or SwiftData throws (see ``errorMessage``).
    @discardableResult
    func save(existingRecipe: Recipe?, in context: ModelContext) -> Bool {
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
            let needsInsert: Bool
            if let existingRecipe {
                recipe = existingRecipe
                recipe.name = name
                recipe.notes = notes
                recipe.dietaryKind = dietaryKind
                recipe.thumbnailBase64 = thumbnailBase64
                recipe.imageFilename = imageFilename
                needsInsert = false
            } else if let pendingRecipe {
                recipe = pendingRecipe
                recipe.name = name.trimmingCharacters(in: .whitespaces)
                recipe.notes = notes.isEmpty ? nil : notes
                recipe.dietaryKind = dietaryKind
                recipe.thumbnailBase64 = thumbnailBase64
                recipe.imageFilename = imageFilename
                needsInsert = false
            } else {
                recipe = Recipe(
                    name: name.trimmingCharacters(in: .whitespaces),
                    notes: notes.isEmpty ? nil : notes,
                    thumbnailBase64: thumbnailBase64,
                    imageFilename: imageFilename,
                    dietaryKind: dietaryKind
                )
                pendingRecipe = recipe
                needsInsert = true
            }

            // Attach ingredients before insert so the relationship graph is registered
            // as one unit (see RecipeIngredientPersistenceTests).
            syncIngredients(validDrafts, to: recipe, in: context)
            if needsInsert {
                context.insert(recipe)
            }
            try context.save()
            pendingRecipe = nil
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// Replaces `recipe.ingredients` with lines built from `drafts`.
    ///
    /// New `RecipeIngredient` rows are linked only through the relationship —
    /// they must not be `context.insert`'d separately, which can leave the parent
    /// recipe missing from subsequent `@Query` fetches after save.
    private func syncIngredients(
        _ drafts: [IngredientDraft],
        to recipe: Recipe,
        in context: ModelContext
    ) {
        let ingredientsToRemove = recipe.ingredients
        for ingredient in ingredientsToRemove {
            context.delete(ingredient)
        }
        recipe.ingredients = []

        var replacement: [RecipeIngredient] = []
        replacement.reserveCapacity(drafts.count)
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
            replacement.append(ingredient)
        }
        recipe.ingredients = replacement
    }
}
