//
//  MockMenuRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//  Updated by ChatGPT on 17/08/2025.
//
@testable import ForkPlan

@MainActor
final class MockMenuRepository: MenuRepository {
    private(set) var menus: [Menu] = []
    let recipeRepository: RecipeRepository

    init(recipeRepository: RecipeRepository) {
        self.recipeRepository = recipeRepository
    }

    func add(_ menu: Menu) async throws { menus.append(menu) }

    func fetchAll() async throws -> [Menu] { menus }

    func delete(_ menu: Menu) async throws { menus.removeAll { $0.id == menu.id } }

    func generateMenu(for days: [String]) async throws -> Menu {
        var recipes = try await recipeRepository.fetchRecipes()
        guard !recipes.isEmpty else { throw MenuError.noRecipesAvailable }
        recipes.shuffle()
        let selected = Array(recipes.prefix(days.count))
        for recipe in selected {
            recipe.usageCount += 1
            try await recipeRepository.updateRecipe(recipe,
                                                    name: recipe.name,
                                                    notes: recipe.notes,
                                                    thumbnailBase64: recipe.thumbnailBase64,
                                                    imageFilename: recipe.imageFilename)
        }
        let menu = Menu(days: days, recipes: selected)
        menus.append(menu)
        return menu
    }
}
