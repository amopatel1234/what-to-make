//
//  AddRecipeUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


struct AddRecipeUseCase {
    private let repository: RecipeRepository
    init(repository: RecipeRepository) { self.repository = repository }

    func execute(name: String, notes: String?, thumbnailBase64: String? = nil, imageFilename: String? = nil) async throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw RecipeError.emptyName }
        let recipe = Recipe(name: name, notes: notes, usageCount: 0, thumbnailBase64: thumbnailBase64, imageFilename: imageFilename)
        try await repository.add(recipe)
    }
}
