//
//  FetchRecipesUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


/// A use case that fetches all persisted ``Recipe`` items.
///
/// Delegates to the injected ``RecipeRepository``.
///
/// Example
/// ```swift
/// let recipes = try await FetchRecipesUseCase(repository: repo).execute()
/// ```
struct FetchRecipesUseCase {
    private let repository: RecipeRepository
    init(repository: RecipeRepository) { self.repository = repository }
    
    /// Fetches all recipes currently stored.
    /// - Returns: An array of recipes.
    /// - Throws: Repository errors if fetching fails.
    @MainActor
    func execute() async throws -> [Recipe] { try await repository.fetchAll() }
}
