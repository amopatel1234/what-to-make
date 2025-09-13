//
//  Tests.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//  Updated by ChatGPT on 17/08/2025.
//
@testable import ForkPlan
import Testing

@MainActor
@Suite
struct RepositorySmokeTests {
    @Test
    func testAddRecipeSuccess() async throws {
        let repo = MockRecipeRepository()
        try await repo.addRecipe(name: "Toast", notes: nil, thumbnailBase64: nil, imageFilename: nil)
        #expect(repo.addCalledCount == 1)
        #expect(repo.recipes.count == 1)
        #expect(repo.recipes.first?.name == "Toast")
    }

    @Test
    func testAddRecipeEmptyNameThrows() async throws {
        let repo = MockRecipeRepository()
        await #expect(throws: RecipeError.emptyName) {
            try await repo.addRecipe(name: "   ", notes: nil, thumbnailBase64: nil, imageFilename: nil)
        }
    }

    @Test
    func testGenerateMenuIncrementsUsage() async throws {
        let recipeRepo = MockRecipeRepository()
        for name in ["A","B","C"] {
            try await recipeRepo.addRecipe(name: name, notes: nil, thumbnailBase64: nil, imageFilename: nil)
        }
        let menuRepo = MockMenuRepository(recipeRepository: recipeRepo)
        let menu = try await menuRepo.generateMenu(for: ["Mon","Tue"])
        #expect(menu.recipes.count == 2)
        #expect(menuRepo.menus.count == 1)
        #expect(recipeRepo.recipes.filter { $0.usageCount > 0 }.count == 2)
    }
}
