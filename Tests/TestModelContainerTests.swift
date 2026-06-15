//
//  TestModelContainerTests.swift
//  whattomake
//

@testable import ForkPlan
import SwiftData
import Testing

@MainActor
@Suite
struct TestModelContainerTests {
    @Test
    func makeTestContainerSeedsRecipesAndMenu() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let recipes = try seedRecipes(in: context, count: 8)
        let menu = try seedMenu(
            in: context,
            days: ["Mon", "Wed"],
            recipes: Array(recipes.prefix(2))
        )

        let storedRecipes = try context.fetch(FetchDescriptor<Recipe>())
        let storedMenus = try context.fetch(FetchDescriptor<Menu>())

        #expect(storedRecipes.count == 8)
        #expect(storedMenus.count == 1)
        #expect(menu.days == ["Mon", "Wed"])
        #expect(menu.recipes.count == 2)
        #expect(recipes.count == 8)
    }
}
