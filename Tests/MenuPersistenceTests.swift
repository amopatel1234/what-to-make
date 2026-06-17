//
//  MenuPersistenceTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import SwiftData
import Testing

@MainActor
@Suite
struct MenuPersistenceTests {
    @Test
    func replaceMenuInsertsIntoEmptyStore() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let recipes = try seedRecipes(in: context, count: 3)

        let menu = Menu(days: ["Mon"], recipes: [recipes[0]])
        try MenuPersistence.replaceMenu(with: menu, in: context)

        let stored = try context.fetch(FetchDescriptor<Menu>())
        #expect(stored.count == 1)
        #expect(stored.first?.days == ["Mon"])
    }

    @Test
    func replaceMenuDeletesExistingMenus() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let recipes = try seedRecipes(in: context, count: 3)
        _ = try seedMenu(in: context, days: ["Mon"], recipes: [recipes[0]])
        _ = try seedMenu(in: context, days: ["Tue"], recipes: [recipes[1]])
        #expect(try context.fetch(FetchDescriptor<Menu>()).count == 2)

        let replacement = Menu(days: ["Wed"], recipes: [recipes[2]])
        try MenuPersistence.replaceMenu(with: replacement, in: context)

        let remaining = try context.fetch(FetchDescriptor<Menu>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.days == ["Wed"])
    }

    @Test
    func replaceMenuPersistsExpectedContent() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let recipes = try seedRecipes(in: context, count: 2)

        let menu = Menu(days: ["Mon", "Wed"], recipes: Array(recipes.prefix(2)))
        try MenuPersistence.replaceMenu(with: menu, in: context)

        let stored = try context.fetch(FetchDescriptor<Menu>()).first
        #expect(stored?.days == ["Mon", "Wed"])
        #expect(Set(stored?.recipes.map(\.name) ?? []) == Set(recipes.prefix(2).map(\.name)))
    }

    @Test
    func latestDescriptorReturnsNewestMenuFirst() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let recipes = try seedRecipes(in: context, count: 2)

        _ = try seedMenu(
            in: context,
            days: ["Mon"],
            recipes: [recipes[0]],
            generatedDate: Date().addingTimeInterval(-3600)
        )
        _ = try seedMenu(
            in: context,
            days: ["Wed"],
            recipes: [recipes[1]],
            generatedDate: Date()
        )

        let latest = try context.fetch(Menu.latestDescriptor()).first
        #expect(latest?.days == ["Wed"])
    }

    @Test
    func replaceMenuBecomesLatestByGeneratedDate() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let recipes = try seedRecipes(in: context, count: 2)

        _ = try seedMenu(
            in: context,
            days: ["Mon"],
            recipes: [recipes[0]],
            generatedDate: Date().addingTimeInterval(-3600)
        )

        let replacement = Menu(
            generatedDate: Date(),
            days: ["Wed"],
            recipes: [recipes[1]]
        )
        try MenuPersistence.replaceMenu(with: replacement, in: context)

        let latest = try context.fetch(Menu.latestDescriptor()).first
        #expect(latest?.days == ["Wed"])
    }

    @Test
    func replaceMenuDoesNotDeleteLinkedRecipes() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let recipes = try seedRecipes(in: context, count: 2)
        _ = try seedMenu(in: context, days: ["Mon"], recipes: [recipes[0]])

        let replacement = Menu(days: ["Wed"], recipes: [recipes[1]])
        try MenuPersistence.replaceMenu(with: replacement, in: context)

        let storedRecipes = try context.fetch(FetchDescriptor<Recipe>())
        #expect(storedRecipes.count == 2)
    }
}
