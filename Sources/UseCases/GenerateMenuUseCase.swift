//
//  GenerateMenuUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


/// A use case that generates and persists a new ``Menu`` snapshot.
///
/// Shuffles available recipes, selects as many as there are requested days,
/// increments their ``Recipe/usageCount``, persists the updated recipes, and
/// then saves the resulting menu via ``MenuRepository``.
///
/// Example
/// ```swift
/// let useCase = GenerateMenuUseCase(recipeRepository: recipes, menuRepository: menus)
/// let menu = try await useCase.execute(for: ["Mon", "Wed", "Fri"])
/// ```
@MainActor
struct GenerateMenuUseCase {
    private let recipeRepository: RecipeRepository
    private let menuRepository: MenuRepository
    init(recipeRepository: RecipeRepository, menuRepository: MenuRepository) {
        self.recipeRepository = recipeRepository
        self.menuRepository = menuRepository
    }

    /// Generates and persists a menu for the provided days.
    ///
    /// - Parameter days: Day identifiers (e.g., "Mon", "Tue"). The count dictates
    ///   how many recipes are selected. If fewer recipes exist than days requested,
    ///   only the available number is used.
    /// - Returns: The persisted menu containing the given days and selected recipes.
    /// - Throws: ``MenuError/noRecipesAvailable`` when there are no recipes to choose from,
    ///   or repository errors when updating recipes or saving the menu fails.
    /// - SideEffects: Increments ``Recipe/usageCount`` on each selected recipe and persists
    ///   those updates before saving the menu.
    @MainActor
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
