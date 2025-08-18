// filepath: /Users/amishpatel/Projects/what-to-make/Tests/GenerateMenuUseCaseTests.swift
//
//  GenerateMenuUseCaseTests.swift
//
import Testing
@testable import ForkPlan

struct GenerateMenuUseCaseTests {
    @Test
    func testThrowsWhenNoRecipesAvailable() async throws {
        let recipeRepo = await MockRecipeRepository()
        let menuRepo = MockMenuRepository()
        let useCase = GenerateMenuUseCase(recipeRepository: recipeRepo, menuRepository: menuRepo)
        await #expect(throws: MenuError.noRecipesAvailable) {
            _ = try await useCase.execute(for: ["Mon"])
        }
        #expect(menuRepo.menus.isEmpty)
    }

    @Test
    func testGeneratesMenuForSelectedDays_persistsMenu_andIncrementsUsage() async throws {
        // Seed >=7 recipes to simulate real app readiness
        let recipeRepo = await MockRecipeRepository(); let menuRepo = MockMenuRepository()
        for i in 1...8 { try await recipeRepo.add(Recipe(name: "R\(i)", notes: nil)) }
        let useCase = GenerateMenuUseCase(recipeRepository: recipeRepo, menuRepository: menuRepo)

        let days = ["Mon","Tue","Wed"]
        let menu = try await useCase.execute(for: days)

        // Menu correctness
        #expect(menu.days == days)
        #expect(menu.recipes.count == days.count)

        // Persistence
        #expect(menuRepo.menus.count == 1)

        // Usage increments on exactly the number of selected recipes
        let incrementedCount = await recipeRepo.recipes.filter { $0.usageCount > 0 }.count
        #expect(incrementedCount == days.count)
    }

    @Test
    func testDaysExceedingAvailableRecipes_selectsAtMostAvailable_andStillPersistsMenuDays() async throws {
        let recipeRepo = await MockRecipeRepository(); let menuRepo = MockMenuRepository()
        for i in 1...5 { try await recipeRepo.add(Recipe(name: "R\(i)", notes: nil)) }
        let useCase = GenerateMenuUseCase(recipeRepository: recipeRepo, menuRepository: menuRepo)

        let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"] // 7 days, 5 recipes only
        let menu = try await useCase.execute(for: days)

        // The use case selects prefix(days.count) after shuffle; when fewer recipes exist, it returns all available
        #expect(menu.recipes.count == 5)
        #expect(menu.days == days)
        #expect(menuRepo.menus.count == 1)

        let incrementedCount = await recipeRepo.recipes.filter { $0.usageCount > 0 }.count
        #expect(incrementedCount == 5)
    }

    @Test
    func testEmptyDays_returnsEmptyMenu_noUsageIncrement_butPersistsMenu() async throws {
        let recipeRepo = await MockRecipeRepository(); let menuRepo = MockMenuRepository()
        for i in 1...3 { try await recipeRepo.add(Recipe(name: "R\(i)", notes: nil)) }
        let useCase = GenerateMenuUseCase(recipeRepository: recipeRepo, menuRepository: menuRepo)

        let days: [String] = []
        let menu = try await useCase.execute(for: days)

        #expect(menu.days.isEmpty)
        #expect(menu.recipes.isEmpty)
        #expect(menuRepo.menus.count == 1)
        let incrementedCount = await recipeRepo.recipes.filter { $0.usageCount > 0 }.count
        #expect(incrementedCount == 0)
    }
}
