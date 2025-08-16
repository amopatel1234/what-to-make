//
//  GenerateMenuViewModelTests.swift
//  whattomake
//
//  Created by Amish Patel on 11/08/2025.
//
// GenerateMenuViewModelTests.swift
import Testing
@testable import whattomake

@MainActor
struct GenerateMenuViewModelTests {

    // MARK: - Helpers

    private func makeViewModelWithSeededRecipes(
        recipeCount: Int
    ) async throws -> GenerateMenuViewModel {
        let recipeRepository = MockRecipeRepository()
        for index in 1...recipeCount {
            try await recipeRepository.add(
                Recipe(name: "Recipe \(index)", notes: nil)
            )
        }
        let menuRepository = MockMenuRepository()

        let generateMenuUseCase = GenerateMenuUseCase(
            recipeRepository: recipeRepository,
            menuRepository: menuRepository
        )
        let countRecipesUseCase = CountRecipesUseCase(repository: recipeRepository)

        let viewModel = GenerateMenuViewModel(
            generateUseCase: generateMenuUseCase,
            countRecipesUseCase: countRecipesUseCase
        )

        // populate availableRecipeCount via the real path
        await viewModel.loadAvailability()
        return viewModel
    }
    
    // MARK: - Helper returning the full system (so we can inspect repo state)
    private func makeSystem(
        recipeCount: Int
    ) async throws -> (viewModel: GenerateMenuViewModel, recipeRepo: MockRecipeRepository, menuRepo: MockMenuRepository) {
        let recipeRepo = MockRecipeRepository()
        for index in 1...recipeCount {
            try await recipeRepo.add(Recipe(name: "Recipe \(index)", notes: nil))
        }
        let menuRepo = MockMenuRepository()

        let generateMenuUseCase = GenerateMenuUseCase(recipeRepository: recipeRepo, menuRepository: menuRepo)
        let countRecipesUseCase = CountRecipesUseCase(repository: recipeRepo)

        let viewModel = GenerateMenuViewModel(generateUseCase: generateMenuUseCase, countRecipesUseCase: countRecipesUseCase)
        await viewModel.loadAvailability()
        return (viewModel, recipeRepo, menuRepo)
    }

    // MARK: - Tests

    @Test
    func testCanGenerateIsFalseWhenAvailableRecipeCountIsLessThanMinimumEvenIfADayIsSelected() async throws {
        let viewModel = try await makeViewModelWithSeededRecipes(recipeCount: 3) // < 7
        viewModel.selectedDays = ["Mon"]
        #expect(viewModel.canGenerate == false)
    }

    @Test
    func testCanGenerateIsTrueWhenAvailableRecipeCountMeetsMinimumAndAtLeastOneDayIsSelected() async throws {
        let viewModel = try await makeViewModelWithSeededRecipes(recipeCount: 7) // == 7
        viewModel.selectedDays = ["Mon", "Tue"]
        #expect(viewModel.canGenerate == true)
    }

    @Test
    func testGenerateSetsValidationMessageWhenCountBelowMinimum() async throws {
        let viewModel = try await makeViewModelWithSeededRecipes(recipeCount: 2) // < 7
        viewModel.selectedDays = ["Mon", "Tue"]
        viewModel.generate()

        // generate() runs validation synchronously before async work
        #expect(viewModel.generatedMenu == nil)
        #expect(viewModel.errorMessage?.contains("at least 7") == true)
    }
    
    @Test
    func testGenerateSucceedsWhenMinimumMetAndIncrementsUsageCounts() async throws {
        // Arrange: at least 7 recipes available
        let (viewModel, recipeRepo, menuRepo) = try await makeSystem(recipeCount: 8)
        viewModel.selectedDays = ["Mon", "Tue", "Wed"] // request 3 days

        // Precondition checks
        #expect(viewModel.canGenerate == true)
        let initialUsedCount = recipeRepo.recipes.filter { $0.usageCount > 0 }.count
        #expect(initialUsedCount == 0)

        // Act
        viewModel.generate()

        // Wait for async Task in ViewModel to finish and set generatedMenu
        var attempts = 0
        while viewModel.generatedMenu == nil && attempts < 50 {
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            attempts += 1
        }

        // Assert
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.generatedMenu != nil)
        #expect(viewModel.generatedMenu?.recipes.count == viewModel.selectedDays.count)
        #expect(menuRepo.menus.count == 1)

        // Exactly N recipes should have usageCount incremented
        let usedAfter = recipeRepo.recipes.filter { $0.usageCount > 0 }.count
        #expect(usedAfter == viewModel.selectedDays.count)
    }
}
