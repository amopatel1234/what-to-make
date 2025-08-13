//
//  CountRecipesUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 11/08/2025.
//


struct CountRecipesUseCase {
    private let repository: RecipeRepository
    init(repository: RecipeRepository) { self.repository = repository }

    func execute() async throws -> Int {
        let all = try await repository.fetchAll()
        return all.count
    }
}
