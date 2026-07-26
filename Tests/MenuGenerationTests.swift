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
    private let dayDietConstraintsKey = AppStorageKey.dayDietConstraints.rawValue

    private func resetPersistedSelection() {
        UserDefaults.standard.removeObject(forKey: selectedDaysKey)
        UserDefaults.standard.removeObject(forKey: dayDietConstraintsKey)
    }

    @Test
    func validationRejectsFewerThanSevenRecipes() {
        let message = MenuGeneration.validationMessage(
            recipeCount: 6,
            dietaryKinds: Array(repeating: .standard, count: 6),
            days: ["Mon"]
        )
        #expect(message == "You need at least 7 recipes to generate a menu. You currently have 6.")
    }

    @Test
    func validationRejectsEmptyDays() {
        let message = MenuGeneration.validationMessage(
            recipeCount: 7,
            dietaryKinds: Array(repeating: .standard, count: 7),
            days: []
        )
        #expect(message == "Please select at least one day.")
    }

    @Test
    func validationAllowsReadyLibraryAndDays() {
        #expect(
            MenuGeneration.validationMessage(
                recipeCount: 7,
                dietaryKinds: Array(repeating: .standard, count: 7),
                days: ["Wed"]
            ) == nil
        )
    }

    @Test
    func validationRejectsInsufficientVeganRecipes() {
        let kinds: [RecipeDietaryKind] = [
            .standard, .standard, .standard, .standard, .standard, .vegetarian, .vegetarian
        ]
        let message = MenuGeneration.validationMessage(
            recipeCount: 7,
            dietaryKinds: kinds,
            days: ["Mon", "Tue"],
            dietConstraints: ["Mon": .vegan]
        )
        #expect(message == "Need 1 more vegan recipe for the days you marked as vegan.")
    }

    @Test
    func validationRejectsInsufficientVegetarianRecipesAfterVeganDays() {
        let kinds: [RecipeDietaryKind] = [
            .standard, .standard, .standard, .standard, .standard, .vegan, .vegetarian
        ]
        let message = MenuGeneration.validationMessage(
            recipeCount: 7,
            dietaryKinds: kinds,
            days: ["Mon", "Tue", "Wed"],
            dietConstraints: ["Mon": .vegan, "Tue": .vegetarian, "Wed": .vegetarian]
        )
        #expect(message == "Need 1 more vegetarian recipe for the days you marked as veg.")
    }

    @Test
    func validationAllowsVeganToCoverVegetarianDay() {
        let kinds: [RecipeDietaryKind] = [
            .standard, .standard, .standard, .standard, .standard, .vegan, .vegan
        ]
        #expect(
            MenuGeneration.validationMessage(
                recipeCount: 7,
                dietaryKinds: kinds,
                days: ["Mon", "Tue"],
                dietConstraints: ["Mon": .vegan, "Tue": .vegetarian]
            ) == nil
        )
    }

    @Test
    func runPersistsMenuAndIncrementsUsage() throws {
        defer { resetPersistedSelection() }
        resetPersistedSelection()

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
    func runPersistsDietConstraintsAndHonorsThem() throws {
        defer { resetPersistedSelection() }
        resetPersistedSelection()

        let container = try makeTestContainer()
        let context = container.mainContext
        var recipes = try seedRecipes(in: context, count: 7, usageCount: 0)
        recipes[0].dietaryKind = .vegan
        recipes[1].dietaryKind = .vegetarian
        try context.save()

        try MenuGeneration.run(
            recipes: recipes,
            days: ["Mon", "Wed"],
            dietConstraints: ["Mon": .vegan, "Wed": .vegetarian],
            modelContext: context
        )

        let menu = try context.fetch(FetchDescriptor<Menu>()).first
        #expect(menu?.days == ["Mon", "Wed"])
        // Use ordered ``Menu/recipeNames`` — SwiftData relationship order is not guaranteed.
        let recipesByName = Dictionary(uniqueKeysWithValues: recipes.map { ($0.name, $0) })
        let mondayRecipe = menu.flatMap { recipesByName[$0.recipeNames[0]] }
        let wednesdayRecipe = menu.flatMap { recipesByName[$0.recipeNames[1]] }
        #expect(mondayRecipe?.dietaryKind == .vegan)
        #expect(wednesdayRecipe?.dietaryKind.satisfies(.vegetarian) == true)
        #expect(UserDefaults.standard.string(forKey: dayDietConstraintsKey) == "Mon=vegan,Wed=vegetarian")
    }

    @Test
    func runReplacesExistingMenu() throws {
        defer { resetPersistedSelection() }
        resetPersistedSelection()

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
