//
//  MenuGenerationTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import SwiftData
import Testing

@MainActor
@Suite
struct MenuGenerationTests {
    private let selectedDaysKey = AppStorageKey.selectedDays.rawValue

    private func resetSelectedDays() {
        UserDefaults.standard.removeObject(forKey: selectedDaysKey)
    }

    @Test
    func validationRejectsFewerThanSevenRecipes() {
        let message = MenuGeneration.validationMessage(recipeCount: 6, days: ["Mon"])
        #expect(message == "You need at least 7 recipes to generate a menu. You currently have 6.")
    }

    @Test
    func validationRejectsEmptyDays() {
        let message = MenuGeneration.validationMessage(recipeCount: 7, days: [])
        #expect(message == "Please select at least one day.")
    }

    @Test
    func validationAllowsReadyLibraryAndDays() {
        #expect(MenuGeneration.validationMessage(recipeCount: 7, days: ["Wed"]) == nil)
    }

    @Test
    func runPersistsMenuAndIncrementsUsage() throws {
        defer { resetSelectedDays() }
        resetSelectedDays()

        let container = try makeTestContainer()
        let context = container.mainContext
        let recipes = try seedRecipes(in: context, count: 8, usageCount: 0)
        let days: Set<String> = ["Fri", "Mon", "Wed"]

        try MenuGeneration.run(recipes: recipes, days: days, modelContext: context)

        let menus = try context.fetch(FetchDescriptor<Menu>())
        #expect(menus.count == 1)
        #expect(menus.first?.days == ["Mon", "Wed", "Fri"])
        #expect(menus.first?.recipes.count == 3)

        let usageCounts = try context.fetch(FetchDescriptor<Recipe>()).map(\.usageCount)
        #expect(usageCounts.filter { $0 == 1 }.count == 3)
        #expect(usageCounts.filter { $0 == 0 }.count == 5)

        let storedDays = UserDefaults.standard.string(forKey: selectedDaysKey)
        #expect(storedDays == "Mon,Wed,Fri")
    }

    @Test
    func runReplacesExistingMenu() throws {
        defer { resetSelectedDays() }
        resetSelectedDays()

        let container = try makeTestContainer()
        let context = container.mainContext
        let recipes = try seedRecipes(in: context, count: 8)
        _ = try seedMenu(in: context, days: ["Tue"], recipes: [recipes[0]])

        try MenuGeneration.run(
            recipes: recipes,
            days: ["Thu", "Sat"],
            modelContext: context
        )

        let menus = try context.fetch(FetchDescriptor<Menu>())
        #expect(menus.count == 1)
        #expect(menus.first?.days == ["Thu", "Sat"])
        #expect(menus.contains { $0.days == ["Tue"] } == false)
    }
}
