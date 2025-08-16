// filepath: /Users/amishpatel/Projects/what-to-make/Tests/GenerateMenuViewModelTests.swift
//
//  GenerateMenuViewModelTests.swift
//  whattomake
//
//  Created by Amish Patel on 16/08/2025.
//
import Testing
@testable import ForkPlan

@MainActor
struct GenerateMenuViewModelTests {
    @Test
    func testCanGenerateIsDisabledWhenBelowMinimumOrNoDays() async throws {
        let recipeRepo = MockRecipeRepository()
        let menuRepo = MockMenuRepository()
        let generate = GenerateMenuUseCase(recipeRepository: recipeRepo, menuRepository: menuRepo)
        let count = CountRecipesUseCase(repository: recipeRepo)
        let vm = GenerateMenuViewModel(generateUseCase: generate, countRecipesUseCase: count)

        await vm.loadAvailability()
        #expect(vm.availableRecipeCount == 0)
        #expect(vm.canGenerate == false)

        vm.selectedDays = ["Mon"]
        #expect(vm.canGenerate == false)
    }

    @Test
    func testGenerateValidatesNoDaySelected() async throws {
        let recipeRepo = MockRecipeRepository()
        let menuRepo = MockMenuRepository()
        let generate = GenerateMenuUseCase(recipeRepository: recipeRepo, menuRepository: menuRepo)
        let count = CountRecipesUseCase(repository: recipeRepo)
        let vm = GenerateMenuViewModel(generateUseCase: generate, countRecipesUseCase: count)

        for i in 1...7 { try await recipeRepo.add(Recipe(name: "R\(i)", notes: nil)) }
        await vm.loadAvailability()
        #expect(vm.availableRecipeCount == 7)

        vm.selectedDays = []
        vm.generate()
        #expect(vm.generatedMenu == nil)
        #expect(vm.errorMessage?.isEmpty == false)
    }
}
