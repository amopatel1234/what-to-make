//
//  MenuGeneration.swift
//  whattomake
//
//  Created by Amish Patel on 25/07/2026.
//

import Foundation
import SwiftData

/// Product-rule validation and persistence for weekly menu generation and day tweaks.
enum MenuGeneration {
    /// Minimum recipe library size required before a menu can be generated.
    static let minRecipesRequired = 7

    /// Returns a user-visible validation message, or `nil` when generation may proceed.
    /// - Parameters:
    ///   - recipes: Recipe library used for count and diet-pool checks.
    ///   - days: Selected day identifiers for the plan.
    ///   - dietConstraints: Per-day diet filters (missing keys mean ``DayDietConstraint/any``).
    static func validationMessage(
        recipes: [Recipe],
        days: Set<String>,
        dietConstraints: [String: DayDietConstraint] = [:]
    ) -> String? {
        validationMessage(
            recipeCount: recipes.count,
            dietaryKinds: recipes.map(\.dietaryKind),
            days: days,
            dietConstraints: dietConstraints
        )
    }

    /// Returns a user-visible validation message, or `nil` when generation may proceed.
    /// - Parameters:
    ///   - recipeCount: Number of recipes currently in the library.
    ///   - dietaryKinds: Dietary classification of each recipe (parallel to the library).
    ///   - days: Selected day identifiers for the plan.
    ///   - dietConstraints: Per-day diet filters (missing keys mean ``DayDietConstraint/any``).
    static func validationMessage(
        recipeCount: Int,
        dietaryKinds: [RecipeDietaryKind],
        days: Set<String>,
        dietConstraints: [String: DayDietConstraint] = [:]
    ) -> String? {
        guard recipeCount >= minRecipesRequired else {
            return "You need at least \(minRecipesRequired) recipes to generate a menu. You currently have \(recipeCount)."
        }
        guard !days.isEmpty else {
            return "Please select at least one day."
        }

        let orderedDays = DaySelectionStorage.orderedDays(from: days)
        let veganDayCount = orderedDays.filter { dietConstraints[$0] == .vegan }.count
        let vegetarianDayCount = orderedDays.filter { dietConstraints[$0] == .vegetarian }.count

        let veganRecipeCount = dietaryKinds.filter { $0 == .vegan }.count
        let vegetarianOnlyCount = dietaryKinds.filter { $0 == .vegetarian }.count

        if veganDayCount > veganRecipeCount {
            let shortfall = veganDayCount - veganRecipeCount
            return "Need \(shortfall) more vegan recipe\(shortfall == 1 ? "" : "s") for the days you marked as vegan."
        }

        let veganRemainingAfterVeganDays = veganRecipeCount - veganDayCount
        let vegetarianPoolForVegDays = vegetarianOnlyCount + veganRemainingAfterVeganDays
        if vegetarianDayCount > vegetarianPoolForVegDays {
            let shortfall = vegetarianDayCount - vegetarianPoolForVegDays
            return "Need \(shortfall) more vegetarian recipe\(shortfall == 1 ? "" : "s") for the days you marked as veg."
        }

        return nil
    }

    /// Maps library recipes into selection snapshots for ``MenuGenerator``.
    static func selectionInputs(from recipes: [Recipe]) -> [RecipeSelectionInput] {
        recipes.map {
            RecipeSelectionInput(
                id: $0.id,
                name: $0.name,
                timesCooked: $0.usageCount,
                lastCookedAt: $0.lastCookedAt,
                dietaryKind: $0.dietaryKind
            )
        }
    }

    /// Selects recipes and replaces the stored menu. Does **not** change cook stats.
    ///
    /// - Parameters:
    ///   - recipes: Available recipes to choose from.
    ///   - days: Selected day identifiers (order normalized via ``DaySelectionStorage``).
    ///   - dietConstraints: Per-day diet filters (missing keys mean ``DayDietConstraint/any``).
    ///   - modelContext: SwiftData context for menu writes.
    /// - Throws: Persistence errors from ``MenuPersistence`` or `modelContext.save()`.
    @MainActor
    static func run(
        recipes: [Recipe],
        days: Set<String>,
        dietConstraints: [String: DayDietConstraint] = [:],
        modelContext: ModelContext
    ) throws {
        let orderedDays = DaySelectionStorage.orderedDays(from: days)
        let requests = orderedDays.map { day in
            DayMenuRequest(day: day, diet: dietConstraints[day] ?? .any)
        }
        let inputs = selectionInputs(from: recipes)
        let selectedInputs = MenuGenerator.select(from: inputs, requests: requests)
        let selectedRecipes = selectedInputs.compactMap { input in
            recipes.first { $0.id == input.id }
        }
        let menu = Menu(days: orderedDays, recipes: selectedRecipes)

        try MenuPersistence.replaceMenu(with: menu, in: modelContext)
        UserDefaults.standard.set(
            DaySelectionStorage.encode(Set(orderedDays)),
            forKey: AppStorageKey.selectedDays.rawValue
        )
        let persistedConstraints = Dictionary(uniqueKeysWithValues: orderedDays.compactMap { day -> (String, DayDietConstraint)? in
            guard let constraint = dietConstraints[day], constraint != .any else { return nil }
            return (day, constraint)
        })
        UserDefaults.standard.set(
            DayDietConstraintStorage.encode(persistedConstraints),
            forKey: AppStorageKey.dayDietConstraints.rawValue
        )
    }

    /// Re-rolls a single day using cook-recency weighting.
    ///
    /// Excludes every recipe already on the menu (including the day’s current
    /// recipe) so a re-roll always picks a different dish when one is available.
    ///
    /// - Returns: A user-visible error message when the day cannot be filled, otherwise `nil`.
    @MainActor
    @discardableResult
    static func rerollDay(
        _ day: String,
        on menu: Menu,
        recipes library: [Recipe],
        diet: DayDietConstraint,
        modelContext: ModelContext
    ) throws -> String? {
        guard let dayIndex = menu.days.firstIndex(of: day) else {
            return "That day isn’t on this menu."
        }
        let ordered = orderedRecipes(for: menu, from: library)
        guard ordered.count == menu.days.count else {
            return "Couldn’t update that day. Try regenerating the menu."
        }

        let excluded = Set(ordered.map(\.id))

        let inputs = selectionInputs(from: library)
        guard let picked = MenuGenerator.selectOne(
            from: inputs,
            diet: diet,
            excluding: excluded
        ) else {
            return "No other recipes fit this day’s diet filter."
        }
        guard let recipe = library.first(where: { $0.id == picked.id }) else {
            return "No other recipes fit this day’s diet filter."
        }

        try assignRecipe(recipe, toDayIndex: dayIndex, on: menu, orderedRecipes: ordered, in: modelContext)
        return nil
    }

    /// Assigns a library recipe to an existing menu day (manual pick).
    @MainActor
    static func assignRecipe(
        _ recipe: Recipe,
        toDay day: String,
        on menu: Menu,
        library: [Recipe],
        modelContext: ModelContext
    ) throws -> String? {
        guard let dayIndex = menu.days.firstIndex(of: day) else {
            return "That day isn’t on this menu."
        }
        let ordered = orderedRecipes(for: menu, from: library)
        guard ordered.count == menu.days.count else {
            return "Couldn’t update that day. Try regenerating the menu."
        }
        try assignRecipe(recipe, toDayIndex: dayIndex, on: menu, orderedRecipes: ordered, in: modelContext)
        return nil
    }

    /// Marks a recipe as cooked: bumps ``Recipe/usageCount`` and sets ``Recipe/lastCookedAt``.
    @MainActor
    static func markCooked(
        _ recipe: Recipe,
        at date: Date = Date(),
        in modelContext: ModelContext
    ) throws {
        recipe.usageCount += 1
        recipe.lastCookedAt = date
        try modelContext.save()
    }

    /// Recipes eligible to manually assign to `day` (diet-aware; may include the current pick).
    static func eligibleRecipes(
        forDay day: String,
        on menu: Menu,
        library: [Recipe],
        diet: DayDietConstraint
    ) -> [Recipe] {
        let ordered = orderedRecipes(for: menu, from: library)
        guard let dayIndex = menu.days.firstIndex(of: day), ordered.count == menu.days.count else {
            return library.filter { $0.dietaryKind.satisfies(diet) }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
        let currentID = ordered[dayIndex].id
        let usedElsewhere = Set(ordered.enumerated().compactMap { index, recipe in
            index == dayIndex ? nil : recipe.id
        })
        return library.filter { recipe in
            recipe.dietaryKind.satisfies(diet)
                && (recipe.id == currentID || !usedElsewhere.contains(recipe.id))
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Resolves day-parallel recipes using ``Menu/recipeNames`` (relationship order is unreliable).
    static func orderedRecipes(for menu: Menu, from library: [Recipe]) -> [Recipe] {
        let names: [String]
        if menu.recipeNames.count == menu.days.count {
            names = menu.recipeNames
        } else {
            names = menu.recipes.map(\.name)
        }
        let linkedByName = Dictionary(grouping: menu.recipes, by: \.name)
        let libraryByName = Dictionary(grouping: library, by: \.name)
        return names.compactMap { name in
            linkedByName[name]?.first ?? libraryByName[name]?.first
        }
    }

    @MainActor
    private static func assignRecipe(
        _ recipe: Recipe,
        toDayIndex dayIndex: Int,
        on menu: Menu,
        orderedRecipes: [Recipe],
        in modelContext: ModelContext
    ) throws {
        var next = orderedRecipes
        next[dayIndex] = recipe
        menu.recipes = next
        menu.recipeNames = next.map(\.name)
        try modelContext.save()
    }
}
