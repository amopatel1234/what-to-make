//
//  RecipesListViewModel.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//  Updated by ChatGPT on 17/08/2025.
//
import Foundation
import Observation

/// A view model that drives the Recipes list screen.
///
/// It loads recipes from persistence, exposes them for display, and coordinates
/// deletions via ``RecipeRepository``. All UI state updates happen on the main actor.
@MainActor
@Observable
final class RecipesListViewModel {
    var recipes: [Recipe] = []
    var errorMessage: String?

    private let repository: RecipeRepository

    init(repository: RecipeRepository) {
        self.repository = repository
    }

    func load() {
        Task { [weak self] in
            guard let self else { return }
            do { self.recipes = try await repository.fetchRecipes() }
            catch { self.errorMessage = error.localizedDescription }
        }
    }

    func delete(at offsets: IndexSet) {
        Task { [weak self] in
            guard let self else { return }
            for index in offsets {
                try? await repository.deleteRecipe(recipes[index])
            }
            await loadAsync()
        }
    }

    private func loadAsync() async {
        do { recipes = try await repository.fetchRecipes() }
        catch { errorMessage = error.localizedDescription }
    }
}
