//
//  GenerateWeeklyMenuIntent.swift
//  whattomake
//
//  Created by Cursor on 25/07/2026.
//

import AppIntents
import SwiftData

/// Generates a new weekly menu using the saved day and diet preferences.
///
/// Replaces any existing menu (same delete-before-insert path as the Menu tab).
struct GenerateWeeklyMenuIntent: AppIntent {
    static let title: LocalizedStringResource = "Generate Weekly Menu"
    static let description = IntentDescription(
        "Creates a new meal plan from your recipes using saved days and diet filters. Replaces any existing menu."
    )
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let context = ModelContext(ForkPlanModelContainer.shared)
        let recipes = try MenuIntentSupport.allRecipes(in: context)
        let days = MenuIntentSupport.savedSelectedDays()
        let dietConstraints = MenuIntentSupport.savedDietConstraints()

        if let validationMessage = MenuGeneration.validationMessage(
            recipes: recipes,
            days: days,
            dietConstraints: dietConstraints
        ) {
            return .result(value: validationMessage, dialog: IntentDialog(LocalizedStringResource(stringLiteral: validationMessage)))
        }

        try MenuGeneration.run(
            recipes: recipes,
            days: days,
            dietConstraints: dietConstraints,
            modelContext: context
        )

        let menu = try MenuIntentSupport.latestMenu(in: context)
        let dialog: String
        if let menu {
            dialog = MenuIntentSupport.generationSuccessDialog(menu: menu)
        } else {
            dialog = "New plan ready."
        }
        return .result(value: dialog, dialog: IntentDialog(LocalizedStringResource(stringLiteral: dialog)))
    }
}
