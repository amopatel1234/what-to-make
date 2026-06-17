//
//  MenuGeneratorTests.swift
//  whattomake
//

@testable import ForkPlan
import Testing

@MainActor
@Suite
struct MenuGeneratorTests {
    @Test
    func selectReturnsAtMostDayCount() {
        let recipes = (1...10).map { Recipe(name: "Recipe \($0)") }
        let days = ["Mon", "Wed", "Fri"]
        let selected = MenuGenerator.select(from: recipes, forDays: days)
        #expect(selected.count == days.count)
    }

    @Test
    func selectReturnsCountMinOfRecipesAndDays() {
        let recipes = (1...3).map { Recipe(name: "Recipe \($0)") }
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        let selected = MenuGenerator.select(from: recipes, forDays: days)
        #expect(selected.count == recipes.count)
    }

    @Test
    func selectReturnsMembersOfInputArray() {
        let recipes = (1...5).map { Recipe(name: "Recipe \($0)") }
        let days = ["Mon", "Wed"]
        let selected = MenuGenerator.select(from: recipes, forDays: days)
        let inputNames = Set(recipes.map(\.name))
        for recipe in selected {
            #expect(inputNames.contains(recipe.name))
        }
    }

    @Test
    func selectReturnsNoDuplicateRecipes() {
        let recipes = (1...10).map { Recipe(name: "Recipe \($0)") }
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        let selected = MenuGenerator.select(from: recipes, forDays: days)
        let names = selected.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test
    func selectWithEmptyDaysReturnsEmpty() {
        let recipes = [Recipe(name: "Recipe 1")]
        let selected = MenuGenerator.select(from: recipes, forDays: [])
        #expect(selected.isEmpty)
    }

    @Test
    func selectWithEmptyRecipesReturnsEmpty() {
        let selected = MenuGenerator.select(from: [], forDays: ["Mon", "Wed"])
        #expect(selected.isEmpty)
    }

    @Test
    func selectWithMoreDaysThanRecipesReturnsAllRecipes() {
        let recipes = (1...3).map { Recipe(name: "Recipe \($0)") }
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        let selected = MenuGenerator.select(from: recipes, forDays: days)
        #expect(selected.count == recipes.count)
    }
}
