//
//  MenuPersistenceIntegrationTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import SwiftData
import Testing

@MainActor
@Suite
struct MenuPersistenceIntegrationTests {
    @Test
    func menuSurvivesSimulatedRelaunch() throws {
        let storeURL = try makePersistentTestStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent()) }

        let expectedDays = ["Mon", "Wed", "Fri"]
        var expectedRecipeNames: [String] = []

        do {
            let container = try makePersistentTestContainer(storeURL: storeURL)
            let context = container.mainContext
            let recipes = try seedRecipes(in: context, count: 3)
            expectedRecipeNames = Array(recipes.prefix(3).map(\.name))
            let menu = Menu(days: expectedDays, recipes: Array(recipes.prefix(3)))
            try MenuPersistence.replaceMenu(with: menu, in: context)
        }

        let relaunchContainer = try makePersistentTestContainer(storeURL: storeURL)
        let relaunchContext = relaunchContainer.mainContext

        let latest = try relaunchContext.fetch(Menu.latestDescriptor()).first
        #expect(latest?.days == expectedDays)
        #expect(latest?.recipeNames == expectedRecipeNames)
        #expect(try relaunchContext.fetch(FetchDescriptor<Menu>()).count == 1)
        #expect(try relaunchContext.fetch(FetchDescriptor<Recipe>()).count == 3)
    }

    @Test
    func regenerateReplacesMenuAfterRelaunch() throws {
        let storeURL = try makePersistentTestStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent()) }

        var expectedRegenerateRecipeNames: [String] = []

        do {
            let container = try makePersistentTestContainer(storeURL: storeURL)
            let context = container.mainContext
            let recipes = try seedRecipes(in: context, count: 3)
            expectedRegenerateRecipeNames = [recipes[1].name, recipes[2].name]
            let menuOne = Menu(days: ["Mon"], recipes: [recipes[0]])
            try MenuPersistence.replaceMenu(with: menuOne, in: context)
        }

        do {
            let container = try makePersistentTestContainer(storeURL: storeURL)
            let context = container.mainContext
            let latest = try context.fetch(Menu.latestDescriptor()).first
            #expect(latest?.days == ["Mon"])
        }

        do {
            let container = try makePersistentTestContainer(storeURL: storeURL)
            let context = container.mainContext
            let recipes = try context.fetch(FetchDescriptor<Recipe>())
            let menuTwoRecipes = expectedRegenerateRecipeNames.compactMap { name in
                recipes.first { $0.name == name }
            }
            #expect(menuTwoRecipes.count == expectedRegenerateRecipeNames.count)
            let menuTwo = Menu(days: ["Wed", "Fri"], recipes: menuTwoRecipes)
            try MenuPersistence.replaceMenu(with: menuTwo, in: context)
        }

        let finalContainer = try makePersistentTestContainer(storeURL: storeURL)
        let finalContext = finalContainer.mainContext

        let allMenus = try finalContext.fetch(FetchDescriptor<Menu>())
        #expect(allMenus.count == 1)

        let latest = try finalContext.fetch(Menu.latestDescriptor()).first
        #expect(latest?.days == ["Wed", "Fri"])
        #expect(latest?.recipeNames == expectedRegenerateRecipeNames)
        #expect(allMenus.contains { $0.days == ["Mon"] } == false)
        #expect(try finalContext.fetch(FetchDescriptor<Recipe>()).count == 3)
    }
}
