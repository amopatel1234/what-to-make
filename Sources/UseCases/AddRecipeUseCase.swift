//
//  AddRecipeUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


struct AddRecipeUseCase {
    private let repository: RecipeRepository
    init(repository: RecipeRepository) { self.repository = repository }

    func execute(name: String, notes: String?) async throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { throw RecipeError.emptyName }
        let recipe = Recipe(name: name, notes: notes)
        try await repository.add(recipe)
    }
}
