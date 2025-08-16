// filepath: /Users/amishpatel/Projects/what-to-make/Tests/FetchRecipesUseCaseTests.swift
//
//  FetchRecipesUseCaseTests.swift
//  whattomake
//
//  Created by Amish Patel on 16/08/2025.
//
import Testing
@testable import ForkPlan

struct FetchRecipesUseCaseTests {
    @Test
    func testExecuteReturnsAllRecipes() async throws {
        let repo = MockRecipeRepository()
        try await repo.add(Recipe(name: "One", notes: "N1"))
        try await repo.add(Recipe(name: "Two", notes: nil))
        let useCase = FetchRecipesUseCase(repository: repo)
        let result = try await useCase.execute()
        #expect(result.count == 2)
        #expect(result.map { $0.name }.sorted() == ["One", "Two"]) 
    }
}
