//
//  CountRecipesUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 11/08/2025.
//


/// A use case that returns the total number of stored ``Recipe`` items.
///
/// Delegates to the injected ``RecipeRepository``.
///
/// Example
/// ```swift
/// let count = try await CountRecipesUseCase(repository: repo).execute()
/// if count >= 7 { /* enable menu generation */ }
/// ```
@MainActor
struct CountRecipesUseCase {
    private let repository: RecipeRepository
    init(repository: RecipeRepository) { self.repository = repository }

    /// Counts recipes currently persisted.
    /// - Returns: The total number of recipes.
    /// - Throws: Repository errors if fetching fails.
    func execute() async throws -> Int {
        let all = try await repository.fetchAll()
        return all.count
    }
}
