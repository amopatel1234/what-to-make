//
//  MockRecipeRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//  Updated by ChatGPT on 17/08/2025.
//
@testable import ForkPlan

@MainActor
final class MockRecipeRepository: RecipeRepository {
    private(set) var recipes: [Recipe] = []
    private(set) var addCalledCount = 0

    func addRecipe(name: String, notes: String?, thumbnailBase64: String?, imageFilename: String?) async throws {
        addCalledCount += 1
        let recipe = Recipe(name: name, notes: notes, thumbnailBase64: thumbnailBase64, imageFilename: imageFilename)
        recipes.append(recipe)
    }

    func updateRecipe(_ recipe: Recipe, name: String, notes: String?, thumbnailBase64: String?, imageFilename: String?) async throws {
        if let idx = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[idx].name = name
            recipes[idx].notes = notes
            recipes[idx].thumbnailBase64 = thumbnailBase64
            recipes[idx].imageFilename = imageFilename
        }
    }

    func deleteRecipe(_ recipe: Recipe) async throws {
        recipes.removeAll { $0.id == recipe.id }
    }

    func fetchRecipes() async throws -> [Recipe] { recipes }

    func countRecipes() async throws -> Int { recipes.count }
}
