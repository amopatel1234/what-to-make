//
//  MockRecipeRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//

@testable import ForkPlan
// In-memory mock repository for unit tests
final class MockRecipeRepository: RecipeRepository {
    private(set) var recipes: [Recipe] = []
    private(set) var addCalledCount = 0

    func add(_ recipe: Recipe) async throws {
        addCalledCount += 1
        recipes.append(recipe)
    }

    func update(_ recipe: Recipe) async throws {
        if let idx = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[idx] = recipe
        }
    }

    func delete(_ recipe: Recipe) async throws {
        recipes.removeAll(where: { $0.id == recipe.id })
    }

    func fetchAll() async throws -> [Recipe] { recipes }
}
