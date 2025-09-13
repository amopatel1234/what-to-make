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
        let menuRepo = MockMenuRepository(recipeRepository: recipeRepo)
        let vm = GenerateMenuViewModel(menuRepository: menuRepo, recipeRepository: recipeRepo)

        await vm.loadAvailability()
        #expect(vm.availableRecipeCount == 0)
        #expect(vm.canGenerate == false)

        vm.selectedDays = ["Mon"]
        #expect(vm.canGenerate == false)
    }

    @Test
    func testGenerateValidatesNoDaySelected() async throws {
        let recipeRepo = MockRecipeRepository()
        let menuRepo = MockMenuRepository(recipeRepository: recipeRepo)
        let vm = GenerateMenuViewModel(menuRepository: menuRepo, recipeRepository: recipeRepo)

        for i in 1...7 { try await recipeRepo.addRecipe(name: "R\(i)", notes: nil, thumbnailBase64: nil, imageFilename: nil) }
        await vm.loadAvailability()
        #expect(vm.availableRecipeCount == 7)

        vm.selectedDays = []
        vm.generate()
        #expect(vm.generatedMenu == nil)
        #expect(vm.errorMessage?.isEmpty == false)
    }
}
