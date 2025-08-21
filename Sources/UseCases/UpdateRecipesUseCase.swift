//
//  UpdateRecipesUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 20/08/2025.
//

@MainActor
struct UpdateRecipesUseCase {
    
    private let repository: RecipeRepository
    
    init(repository: RecipeRepository) {
        self.repository = repository
    }


    func execute(recipe: Recipe,
                 name: String,
                 notes: String?,
                 thumbnailBase64: String?,
                 imageFilename: String?) async throws {
        recipe.name = name
        recipe.notes = notes
        recipe.name = name
        recipe.notes = notes
        recipe.thumbnailBase64 = thumbnailBase64
        recipe.imageFilename = imageFilename
        
        try await repository.update(recipe)
    }
}
