//
//  FetchRecipesUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


struct FetchRecipesUseCase {
    private let repository: RecipeRepository
    init(repository: RecipeRepository) { self.repository = repository }
    func execute() async throws -> [Recipe] { try await repository.fetchAll() }
}
