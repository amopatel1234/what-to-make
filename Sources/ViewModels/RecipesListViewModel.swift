//
//  RecipesListViewModel.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Foundation
import Observation

@MainActor
@Observable
final class RecipesListViewModel {
    var recipes: [Recipe] = []
    var errorMessage: String?

    private let fetchUseCase: FetchRecipesUseCase
    private let deleteUseCase: DeleteRecipeUseCase

    init(fetchUseCase: FetchRecipesUseCase, deleteUseCase: DeleteRecipeUseCase) {
        self.fetchUseCase = fetchUseCase
        self.deleteUseCase = deleteUseCase
    }

    func load() {
        Task { [weak self] in
            guard let self else { return }
            do { self.recipes = try await fetchUseCase.execute() }
            catch { self.errorMessage = error.localizedDescription }
        }
    }

    func delete(at offsets: IndexSet) {
        Task { [weak self] in
            guard let self else { return }
            for index in offsets { try? await deleteUseCase.execute(recipes[index]) }
            await loadAsync()
        }
    }

    private func loadAsync() async {
        do { recipes = try await fetchUseCase.execute() }
        catch { errorMessage = error.localizedDescription }
    }
}
