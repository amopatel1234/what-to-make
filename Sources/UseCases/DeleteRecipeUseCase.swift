//
//  DeleteRecipeUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


struct DeleteRecipeUseCase {
    private let repository: RecipeRepository
    init(repository: RecipeRepository) { self.repository = repository }
    func execute(_ recipe: Recipe) async throws {
        if let filename = recipe.imageFilename { ImageStore.delete(named: filename) }
        try await repository.delete(recipe)
    }
}
