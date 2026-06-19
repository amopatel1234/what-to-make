//
//  MenuGeneratorTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import Testing

@Suite
struct MenuGeneratorTests {
    private func makeInputs(count: Int, namePrefix: String = "Recipe") -> [RecipeSelectionInput] {
        (1...count).map {
            RecipeSelectionInput(id: UUID(), name: "\(namePrefix) \($0)", usageCount: 0)
        }
    }

    @Test
    func selectReturnsAtMostDayCount() {
        let recipes = makeInputs(count: 10)
        let days = ["Mon", "Wed", "Fri"]
        let selected = MenuGenerator.select(from: recipes, forDays: days)
        #expect(selected.count == days.count)
    }

    @Test
    func selectReturnsCountMinOfRecipesAndDays() {
        let recipes = makeInputs(count: 3)
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        let selected = MenuGenerator.select(from: recipes, forDays: days)
        #expect(selected.count == recipes.count)
    }

    @Test
    func selectReturnsMembersOfInputArray() {
        let recipes = makeInputs(count: 5)
        let days = ["Mon", "Wed"]
        let selected = MenuGenerator.select(from: recipes, forDays: days)
        let inputNames = Set(recipes.map(\.name))
        for recipe in selected {
            #expect(inputNames.contains(recipe.name))
        }
    }

    @Test
    func selectReturnsNoDuplicateRecipes() {
        let recipes = makeInputs(count: 10)
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        let selected = MenuGenerator.select(from: recipes, forDays: days)
        let names = selected.map(\.name)
        #expect(Set(names).count == names.count)
    }

    @Test
    func selectWithEmptyDaysReturnsEmpty() {
        let recipes = [RecipeSelectionInput(id: UUID(), name: "Recipe 1", usageCount: 0)]
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
        let recipes = makeInputs(count: 3)
        let days = ["Mon", "Tue", "Wed", "Thu", "Fri"]
        let selected = MenuGenerator.select(from: recipes, forDays: days)
        #expect(selected.count == recipes.count)
    }
}
