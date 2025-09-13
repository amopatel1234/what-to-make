//
//  SwiftDataRecipeRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//  Updated by ChatGPT on 17/08/2025.
//
import Foundation
import SwiftData

@MainActor
/// SwiftData-backed implementation of ``RecipeRepository``.
///
/// Persists and queries ``Recipe`` models using a provided ``ModelContext``.
/// Fetches are returned sorted by ``Recipe/name`` ascending.
final class SwiftDataRecipeRepository: RecipeRepository {
    private let context: ModelContext

    /// Creates a repository bound to a SwiftData model context.
    /// - Parameter context: The SwiftData context used for persistence.
    init(context: ModelContext) {
        self.context = context
    }

    func addRecipe(name: String, notes: String?, thumbnailBase64: String?, imageFilename: String?) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RecipeError.emptyName }
        let recipe = Recipe(name: trimmed, notes: notes, thumbnailBase64: thumbnailBase64, imageFilename: imageFilename)
        context.insert(recipe)
        try context.save()
    }

    func updateRecipe(_ recipe: Recipe, name: String, notes: String?, thumbnailBase64: String?, imageFilename: String?) async throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw RecipeError.emptyName }
        recipe.name = trimmed
        recipe.notes = notes
        recipe.thumbnailBase64 = thumbnailBase64
        recipe.imageFilename = imageFilename
        try context.save()
    }

    func deleteRecipe(_ recipe: Recipe) async throws {
        context.delete(recipe)
        try context.save()
    }

    func fetchRecipes() async throws -> [Recipe] {
        let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor)
    }

    func countRecipes() async throws -> Int {
        let descriptor = FetchDescriptor<Recipe>()
        return try context.fetch(descriptor).count
    }
}
