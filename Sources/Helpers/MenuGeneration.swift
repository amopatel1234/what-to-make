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
    ///   - recipeCount: Number of recipes currently in the library.
    ///   - days: Selected day identifiers for the plan.
    static func validationMessage(recipeCount: Int, days: Set<String>) -> String? {
        guard recipeCount >= minRecipesRequired else {
            return "You need at least \(minRecipesRequired) recipes to generate a menu. You currently have \(recipeCount)."
        }
        guard !days.isEmpty else {
            return "Please select at least one day."
        }
        return nil
    }

    /// Selects recipes, replaces the stored menu, increments usage, and persists day selection.
    /// - Parameters:
    ///   - recipes: Available recipes to choose from.
    ///   - days: Selected day identifiers (order normalized via ``DaySelectionStorage``).
    ///   - modelContext: SwiftData context for menu and usage writes.
    /// - Throws: Persistence errors from ``MenuPersistence`` or `modelContext.save()`.
    @MainActor
    static func run(
        recipes: [Recipe],
        days: Set<String>,
        modelContext: ModelContext
    ) throws {
        let orderedDays = DaySelectionStorage.orderedDays(from: days)
        let inputs = recipes.map {
            RecipeSelectionInput(id: $0.id, name: $0.name, usageCount: $0.usageCount)
        }
        let selectedInputs = MenuGenerator.select(from: inputs, forDays: orderedDays)
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
    }
}
