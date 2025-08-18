//
//  Tests.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
@testable import ForkPlan
import Testing

@Test
func testAddRecipeUseCaseSuccess() async throws {
    let repo = await MockRecipeRepository()
    let useCase = AddRecipeUseCase(repository: repo)
    try await useCase.execute(name: "Toast", notes: nil)
    await #expect(repo.addCalledCount == 1)
    await #expect(repo.recipes.count == 1)
    await #expect(repo.recipes.first?.name == "Toast")
}

@Test
func testAddRecipeUseCaseEmptyName() async throws {
    let repo = await MockRecipeRepository()
    let useCase = AddRecipeUseCase(repository: repo)
    await #expect(throws: RecipeError.emptyName) {
        try await useCase.execute(name: "   ", notes: nil)
    }
}

@Test
func testGenerateMenuUseCaseIncrementsUsage() async throws {
    let repo = await MockRecipeRepository(); let menuRepo = MockMenuRepository()
    try await repo.add(Recipe(name: "A", notes: nil))
    try await repo.add(Recipe(name: "B", notes: nil))
    try await repo.add(Recipe(name: "C", notes: nil))
    let useCase = GenerateMenuUseCase(recipeRepository: repo, menuRepository: menuRepo)
    let menu = try await useCase.execute(for: ["Mon","Tue"])
    #expect(menu.recipes.count == 2)
    #expect(menuRepo.menus.count == 1)
    await #expect(repo.recipes.filter { $0.usageCount > 0 }.count == 2)
}
