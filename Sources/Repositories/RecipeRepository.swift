//
//  RecipeRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//  Updated by ChatGPT on 17/08/2025.
//

import Foundation

/// Abstraction for persisting and querying ``Recipe`` models.
///
/// Concrete implementations should provide high-level CRUD operations used by the
/// app’s view models. Implementations can choose appropriate fetch ordering.
@MainActor
protocol RecipeRepository {
    /// Adds a new recipe after validating input.
    func addRecipe(name: String,
                   notes: String?,
                   thumbnailBase64: String?,
                   imageFilename: String?) async throws

    /// Updates an existing recipe with new values after validating input.
    func updateRecipe(_ recipe: Recipe,
                      name: String,
                      notes: String?,
                      thumbnailBase64: String?,
                      imageFilename: String?) async throws

    /// Deletes a recipe.
    func deleteRecipe(_ recipe: Recipe) async throws

    /// Returns all stored recipes.
    func fetchRecipes() async throws -> [Recipe]

    /// Returns the number of stored recipes.
    func countRecipes() async throws -> Int
}
