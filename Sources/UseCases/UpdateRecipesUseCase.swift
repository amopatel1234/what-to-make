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
                 thunbnailBase64: String?,
                 imageFilename: String?) async throws {
        recipe.name = name
        recipe.notes = notes
        recipe.thumbnailBase64 = thunbnailBase64
        recipe.imageFilename = imageFilename
        
        try await repository.update(recipe)
    }
}
