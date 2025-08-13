//
//  GenerateMenuUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


struct GenerateMenuUseCase {
    private let recipeRepository: RecipeRepository
    private let menuRepository: MenuRepository
    init(recipeRepository: RecipeRepository, menuRepository: MenuRepository) {
        self.recipeRepository = recipeRepository
        self.menuRepository = menuRepository
    }

    func execute(for days: [String]) async throws -> Menu {
        var recipes = try await recipeRepository.fetchAll()
        guard !recipes.isEmpty else { throw MenuError.noRecipesAvailable }
        recipes.shuffle()
        let selectedRecipes = Array(recipes.prefix(days.count))
        for recipe in selectedRecipes { recipe.usageCount += 1; try await recipeRepository.update(recipe) }
        let menu = Menu(days: days, recipes: selectedRecipes)
        try await menuRepository.add(menu)
        return menu
    }
}
