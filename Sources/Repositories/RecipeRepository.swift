//
//  RecipeRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//

import Foundation

/// Abstraction for persisting and querying ``Recipe`` models.
///
/// Concrete implementations should provide simple CRUD operations used by the
/// app’s use cases. Implementations can choose appropriate fetch ordering.
///
/// Example
/// ```swift
/// let repo: RecipeRepository = SwiftDataRecipeRepository(context: context)
/// try await repo.add(Recipe(name: "Pasta", notes: nil, usageCount: 0))
/// let all = try await repo.fetchAll()
/// var first = all[0]
/// first.usageCount += 1
/// try await repo.update(first)
/// try await repo.delete(first)
/// ```
protocol RecipeRepository {
    /// Persists a new recipe.
    /// - Parameter recipe: The recipe to insert.
    /// - Throws: An error if persistence fails.
    func add(_ recipe: Recipe) async throws
    /// Updates a previously persisted recipe.
    /// - Parameter recipe: The recipe to update.
    /// - Throws: An error if persistence fails.
    func update(_ recipe: Recipe) async throws
    /// Deletes a recipe.
    /// - Parameter recipe: The recipe to delete.
    /// - Throws: An error if deletion fails.
    func delete(_ recipe: Recipe) async throws
    /// Returns all stored recipes.
    /// - Returns: An array of recipes, order defined by the implementation.
    /// - Throws: An error if fetching fails.
    func fetchAll() async throws -> [Recipe]
}
