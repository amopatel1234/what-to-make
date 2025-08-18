// filepath: /Users/amishpatel/Projects/what-to-make/Tests/CountRecipesUseCaseTests.swift
//
//  CountRecipesUseCaseTests.swift
//  whattomake
//
//  Created by Amish Patel on 16/08/2025.
//
import Testing
@testable import ForkPlan

@MainActor
struct CountRecipesUseCaseTests {
    @Test
    func testExecuteReturnsZeroWhenNoRecipes() async throws {
        let repo = MockRecipeRepository()
        let useCase = CountRecipesUseCase(repository: repo)
        let count = try await useCase.execute()
        #expect(count == 0)
    }

    @Test
    func testExecuteReturnsCorrectCount() async throws {
        let repo = MockRecipeRepository()
        try await repo.add(Recipe(name: "A", notes: nil))
        try await repo.add(Recipe(name: "B", notes: nil))
        let useCase = CountRecipesUseCase(repository: repo)
        let count = try await useCase.execute()
        #expect(count == 2)
    }
}
