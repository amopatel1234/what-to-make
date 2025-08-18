//
//  DeleteRecipeUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


/// A use case that deletes a ``Recipe`` and cleans up any stored image.
///
/// If the recipe has an associated on-disk original image filename, it will be
/// removed best-effort before deleting the recipe from persistence.
///
/// Example
/// ```swift
/// let useCase = DeleteRecipeUseCase(repository: repo)
/// try await useCase.execute(recipe)
/// ```
struct DeleteRecipeUseCase {
    private let repository: RecipeRepository
    init(repository: RecipeRepository) { self.repository = repository }

    /// Deletes the given recipe and removes its original image file if present.
    /// - Parameter recipe: The recipe to delete.
    /// - Throws: Repository errors that occur while deleting the model.
    /// - Note: Image file deletion failures are ignored on purpose.
    func execute(_ recipe: Recipe) async throws {
        if let filename = recipe.imageFilename { ImageStore.delete(named: filename) }
        try await repository.delete(recipe)
    }
}
