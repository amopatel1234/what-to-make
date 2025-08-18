//
//  SwiftDataRecipeRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Foundation
import SwiftData

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

    /// Inserts a recipe and saves the context.
    func add(_ recipe: Recipe) async throws {
        context.insert(recipe)
        try context.save()
    }

    /// Saves pending changes for the provided recipe.
    func update(_ recipe: Recipe) async throws {
        try context.save()
    }

    /// Deletes a recipe and saves the context.
    func delete(_ recipe: Recipe) async throws {
        context.delete(recipe)
        try context.save()
    }

    /// Fetches all recipes sorted by name ascending.
    func fetchAll() async throws -> [Recipe] {
        let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor)
    }
}
