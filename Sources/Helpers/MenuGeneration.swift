//
//  MenuGeneration.swift
//  whattomake
//
//  Created by Amish Patel on 25/07/2026.
//

import Foundation
import SwiftData

/// Product-rule validation and persistence for weekly menu generation.
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

    /// Selects recipes, replaces the stored menu, increments usage, and persists day selection.
    /// - Parameters:
    ///   - recipes: Available recipes to choose from.
    ///   - days: Selected day identifiers (order normalized via ``DaySelectionStorage``).
    ///   - dietConstraints: Per-day diet filters (missing keys mean ``DayDietConstraint/any``).
    ///   - modelContext: SwiftData context for menu and usage writes.
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
        let inputs = recipes.map {
            RecipeSelectionInput(
                id: $0.id,
                name: $0.name,
                usageCount: $0.usageCount,
                dietaryKind: $0.dietaryKind
            )
        }
        let selectedInputs = MenuGenerator.select(from: inputs, requests: requests)
        let selectedRecipes = selectedInputs.compactMap { input in
            recipes.first { $0.id == input.id }
        }
        let menu = Menu(days: orderedDays, recipes: selectedRecipes)

        try MenuPersistence.replaceMenu(with: menu, in: modelContext)
        for recipe in selectedRecipes {
            recipe.usageCount += 1
        }
        try modelContext.save()
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
}
