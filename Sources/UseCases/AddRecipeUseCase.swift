//
//  AddRecipeUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


/// A use case that creates and persists a new ``Recipe``.
///
/// Validates the required fields and forwards persistence to the injected
/// ``RecipeRepository``.
///
/// Example
/// ```swift
/// let useCase = AddRecipeUseCase(repository: repo)
/// try await useCase.execute(name: "Pasta", notes: "Family favorite", thumbnailBase64: thumb, imageFilename: filename)
/// ```
@MainActor
struct AddRecipeUseCase {
    private let repository: RecipeRepository
    init(repository: RecipeRepository) { self.repository = repository }

    /// Persists a new recipe with the provided data.
    /// - Parameters:
    ///   - name: The required recipe name. Must be non-empty after trimming whitespace.
    ///   - notes: Optional free-form notes.
    ///   - thumbnailBase64: Optional Base64-encoded JPEG thumbnail for list display.
    ///   - imageFilename: Optional filename pointing to the on-disk original image.
    /// - Throws: ``RecipeError/emptyName`` when the name is blank, or repository errors on add.
    func execute(name: String, notes: String?, thumbnailBase64: String? = nil, imageFilename: String? = nil) async throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw RecipeError.emptyName }
        let recipe = Recipe(name: name, notes: notes, usageCount: 0, thumbnailBase64: thumbnailBase64, imageFilename: imageFilename)
        try await repository.add(recipe)
    }
}
