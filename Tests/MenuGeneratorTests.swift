//
//  MenuGeneratorTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import Testing

@Suite
struct MenuGeneratorTests {
    private func makeInputs(
        count: Int,
        namePrefix: String = "Recipe",
        dietaryKind: RecipeDietaryKind = .standard,
        lastCookedAt: Date? = nil
    ) -> [RecipeSelectionInput] {
        (1...count).map {
            RecipeSelectionInput(
                id: UUID(),
                name: "\(namePrefix) \($0)",
                timesCooked: 0,
                lastCookedAt: lastCookedAt,
                dietaryKind: dietaryKind
            )
        }
    }

    private func makeInput(
        name: String,
        dietaryKind: RecipeDietaryKind,
        timesCooked: Int = 0,
        lastCookedAt: Date? = nil
    ) -> RecipeSelectionInput {
        RecipeSelectionInput(
            id: UUID(),
            name: name,
            timesCooked: timesCooked,
            lastCookedAt: lastCookedAt,
            dietaryKind: dietaryKind
        )
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
        let recipes = [makeInput(name: "Recipe 1", dietaryKind: .standard)]
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

    @Test
    func selectAssignsVeganRecipeToVeganDay() {
        let vegan = makeInput(name: "Vegan Bowl", dietaryKind: .vegan)
        let standard = makeInput(name: "Steak", dietaryKind: .standard)
        let vegetarian = makeInput(name: "Pasta", dietaryKind: .vegetarian)
        let requests = [
            DayMenuRequest(day: "Mon", diet: .vegan),
            DayMenuRequest(day: "Tue", diet: .any)
        ]

        let selected = MenuGenerator.select(
            from: [standard, vegetarian, vegan],
            requests: requests
        )

        #expect(selected.count == 2)
        #expect(selected[0].name == "Vegan Bowl")
        #expect(selected[0].dietaryKind == .vegan)
        #expect(selected[1].name != "Vegan Bowl")
    }

    @Test
    func selectAllowsVeganOnVegetarianDay() {
        let vegan = makeInput(name: "Tofu", dietaryKind: .vegan)
        let standard = makeInput(name: "Chicken", dietaryKind: .standard)
        let requests = [
            DayMenuRequest(day: "Wed", diet: .vegetarian),
            DayMenuRequest(day: "Thu", diet: .any)
        ]

        let selected = MenuGenerator.select(from: [standard, vegan], requests: requests)
        #expect(selected.count == 2)
        #expect(selected[0].dietaryKind == .vegan)
        #expect(selected[1].dietaryKind == .standard)
    }

    @Test
    func selectSkipsRestrictedDayWhenPoolEmpty() {
        let recipes = makeInputs(count: 5, dietaryKind: .standard)
        let requests = [
            DayMenuRequest(day: "Mon", diet: .vegan),
            DayMenuRequest(day: "Tue", diet: .any)
        ]

        let selected = MenuGenerator.select(from: recipes, requests: requests)
        #expect(selected.count == 1)
        #expect(selected[0].dietaryKind == .standard)
    }

    @Test
    func selectPrefersFillingVeganDaysBeforeAnyDays() {
        let veganA = makeInput(name: "Vegan A", dietaryKind: .vegan)
        let veganB = makeInput(name: "Vegan B", dietaryKind: .vegan)
        let requests = [
            DayMenuRequest(day: "Mon", diet: .any),
            DayMenuRequest(day: "Tue", diet: .vegan),
            DayMenuRequest(day: "Wed", diet: .vegan)
        ]

        let selected = MenuGenerator.select(from: [veganA, veganB], requests: requests)
        #expect(selected.count == 2)
        let selectedNames = Set(selected.map(\.name))
        #expect(selectedNames == ["Vegan A", "Vegan B"])
        #expect(selected.allSatisfy { $0.dietaryKind == .vegan })
    }

    @Test
    func neverCookedWeightExceedsRecentCook() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let never = MenuGenerator.cookRecencyWeight(lastCookedAt: nil, now: now)
        let yesterday = MenuGenerator.cookRecencyWeight(
            lastCookedAt: now.addingTimeInterval(-86_400),
            now: now
        )
        #expect(never > yesterday)
        #expect(yesterday == 1)
    }

    @Test
    func weightedPickWithZeroRandomSelectsFirstBucket() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let recent = makeInput(
            name: "Recent",
            dietaryKind: .standard,
            lastCookedAt: now
        )
        let never = makeInput(
            name: "Never",
            dietaryKind: .standard,
            lastCookedAt: nil
        )
        // Pool order: recent first (weight 1), never second (weight 3650).
        // randomValue 0 lands in the first bucket → Recent.
        let first = MenuGenerator.pickWeighted(
            from: [recent, never],
            now: now,
            randomValue: { 0 }
        )
        #expect(first?.name == "Recent")

        // A value just above recent's share of total lands in Never.
        let total = 1 + MenuGenerator.neverCookedWeight
        let intoNever = MenuGenerator.pickWeighted(
            from: [recent, never],
            now: now,
            randomValue: { (1.5) / total }
        )
        #expect(intoNever?.name == "Never")
    }

    @Test
    func selectOneExcludesUsedIDs() {
        let a = makeInput(name: "A", dietaryKind: .standard)
        let b = makeInput(name: "B", dietaryKind: .standard)
        let picked = MenuGenerator.selectOne(
            from: [a, b],
            diet: .any,
            excluding: [a.id],
            randomValue: { 0 }
        )
        #expect(picked?.id == b.id)
    }
}
