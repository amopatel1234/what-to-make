//
//  RecipesListViewModelTests.swift
//  whattomake
//
//  Created by Amish Patel on 16/08/2025.
//
import Foundation
import Testing
@testable import ForkPlan

@MainActor
struct RecipesListViewModelTests {
    @Test
    func testLoadPopulatesRecipes() async throws {
        let repo = MockRecipeRepository()
        try await repo.add(Recipe(name: "One", notes: nil))
        try await repo.add(Recipe(name: "Two", notes: "N2"))

        let fetch = FetchRecipesUseCase(repository: repo)
        let delete = DeleteRecipeUseCase(repository: repo)
        let vm = RecipesListViewModel(fetchUseCase: fetch, deleteUseCase: delete)

        vm.load()
        // wait for async Task in load()
        var attempts = 0
        while vm.recipes.count < 2 && attempts < 50 {
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05s
            attempts += 1
        }
        #expect(vm.recipes.count == 2)
        #expect(vm.errorMessage == nil)
    }

    @Test
    func testDeleteRemovesRecipeAndReloads() async throws {
        let repo = MockRecipeRepository()
        try await repo.add(Recipe(name: "One", notes: nil))
        try await repo.add(Recipe(name: "Two", notes: nil))

        let fetch = FetchRecipesUseCase(repository: repo)
        let delete = DeleteRecipeUseCase(repository: repo)
        let vm = RecipesListViewModel(fetchUseCase: fetch, deleteUseCase: delete)

        // initial load
        vm.load()
        var attempts = 0
        while vm.recipes.count < 2 && attempts < 50 {
            try? await Task.sleep(nanoseconds: 50_000_000)
            attempts += 1
        }
        #expect(vm.recipes.count == 2)

        // delete first
        vm.delete(at: IndexSet(integer: 0))
        attempts = 0
        while vm.recipes.count != 1 && attempts < 50 {
            try? await Task.sleep(nanoseconds: 50_000_000)
            attempts += 1
        }
        #expect(vm.recipes.count == 1)
        #expect(repo.recipes.count == 1)
    }
}
