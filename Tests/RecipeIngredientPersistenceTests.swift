//
//  RecipeIngredientPersistenceTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import SwiftData
import Testing

@MainActor
@Suite
struct RecipeIngredientPersistenceTests {
    @Test
    func savesIngredientsInOrderAndContainsMeat() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let recipe = Recipe(name: "Roast Chicken", containsMeat: true)
        let first = RecipeIngredient(name: "chicken", amount: 1, unit: "kg", sortOrder: 0)
        let second = RecipeIngredient(name: "olive oil", amount: 2, unit: "tbsp", sortOrder: 1)
        first.recipe = recipe
        second.recipe = recipe
        recipe.ingredients = [first, second]
        context.insert(recipe)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Recipe>()).first
        #expect(fetched?.containsMeat == true)
        let sortedIngredients = fetched?.ingredients.sorted { $0.sortOrder < $1.sortOrder } ?? []
        #expect(sortedIngredients.count == 2)
        #expect(sortedIngredients[0].name == "chicken")
        #expect(sortedIngredients[0].amount == 1)
        #expect(sortedIngredients[0].unit == "kg")
        #expect(sortedIngredients[1].name == "olive oil")
    }

    @Test
    func deletingRecipeCascadesToIngredients() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let recipe = Recipe(name: "Pasta")
        let ingredient = RecipeIngredient(name: "pasta", amount: 400, unit: "g", sortOrder: 0)
        ingredient.recipe = recipe
        recipe.ingredients = [ingredient]
        context.insert(recipe)
        try context.save()

        context.delete(recipe)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Recipe>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<RecipeIngredient>()).isEmpty)
    }

    @Test
    func ingredientsSurviveSimulatedRelaunch() throws {
        let storeURL = try makePersistentTestStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent()) }

        do {
            let container = try makePersistentTestContainer(storeURL: storeURL)
            let context = container.mainContext
            let recipe = Recipe(name: "Stew", containsMeat: true)
            let ingredient = RecipeIngredient(name: "beef", amount: 500, unit: "g", sortOrder: 0)
            ingredient.recipe = recipe
            recipe.ingredients = [ingredient]
            context.insert(recipe)
            try context.save()
        }

        let relaunchContainer = try makePersistentTestContainer(storeURL: storeURL)
        let relaunchContext = relaunchContainer.mainContext
        let recipe = try relaunchContext.fetch(FetchDescriptor<Recipe>()).first
        #expect(recipe?.containsMeat == true)
        let ingredient = recipe?.ingredients.sorted { $0.sortOrder < $1.sortOrder }.first
        #expect(ingredient?.name == "beef")
        #expect(ingredient?.amount == 500)
        #expect(ingredient?.unit == "g")
    }
}
