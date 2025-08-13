//
//  AddRecipeUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


struct AddRecipeUseCase {
    private let repository: RecipeRepository
    init(repository: RecipeRepository) { self.repository = repository }

    func execute(name: String, ingredients: [String], notes: String?) async throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw RecipeError.emptyName }
        guard !ingredients.isEmpty else { throw RecipeError.noIngredients }
        let recipe = Recipe(name: name, ingredients: ingredients, notes: notes)
        try await repository.add(recipe)
    }
}
