//
//  RecipesListViewModel.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Foundation
import Observation

/// A view model that drives the Recipes list screen.
///
/// It loads recipes from persistence, exposes them for display, and coordinates
/// deletions via ``DeleteRecipeUseCase``. All UI state updates happen on the main actor.
///
/// Example
/// ```swift
/// let vm = RecipesListViewModel(fetchUseCase: fetch, deleteUseCase: delete)
/// vm.load()
/// // Bind vm.recipes to a SwiftUI List
/// ```
@MainActor
@Observable
final class RecipesListViewModel {
    /// The current list of recipes to display.
    var recipes: [Recipe] = []
    /// A user-presentable error message for load or delete failures.
    var errorMessage: String?

    private let fetchUseCase: FetchRecipesUseCase
    private let deleteUseCase: DeleteRecipeUseCase

    /// Creates a new instance with its dependencies.
    /// - Parameters:
    ///   - fetchUseCase: Use case responsible for fetching all recipes.
    ///   - deleteUseCase: Use case that deletes a single recipe.
    init(fetchUseCase: FetchRecipesUseCase, deleteUseCase: DeleteRecipeUseCase) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
    }

    /// Loads all recipes asynchronously and updates ``recipes``.
    ///
    /// On failure, leaves the existing items intact and sets ``errorMessage``.
    func load() {
        Task { [weak self] in
            guard let self else { return }
            do { self.recipes = try await fetchUseCase.execute() }
            catch { self.errorMessage = error.localizedDescription }
        }
    }

    /// Deletes recipes at the given offsets and refreshes the list.
    ///
    /// Any individual deletion failure is ignored to continue processing the rest.
    /// After attempting deletions, the list is reloaded.
    /// - Parameter offsets: Indexes of items in ``recipes`` to delete.
    func delete(at offsets: IndexSet) {
        Task { [weak self] in
            guard let self else { return }
            for index in offsets { try? await deleteUseCase.execute(recipes[index]) }
            await loadAsync()
        }
    }

    /// Async helper used to refresh ``recipes`` after deletions.
    private func loadAsync() async {
        do { recipes = try await fetchUseCase.execute() }
        catch { errorMessage = error.localizedDescription }
    }
}
