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
/// Asks for confirmation before writing because the replace is destructive.
struct GenerateWeeklyMenuIntent: AppIntent {
    static let title: LocalizedStringResource = "Generate Weekly Menu"
    static let description = IntentDescription(
        "Creates a new meal plan from your recipes using saved days and diet filters. Replaces any existing menu."
    )
    static let openAppWhenRun = false

    /// Must match ``WeeklyMenuApp/modelContainerDependencyKey``.
    @Dependency(key: "ModelContainer")
    private var modelContainer: ModelContainer

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let context = ModelContext(modelContainer)
        let recipes = try MenuIntentSupport.allRecipes(in: context)
        let days = MenuIntentSupport.savedSelectedDays()
        let dietConstraints = MenuIntentSupport.savedDietConstraints()

        if let validationMessage = MenuGeneration.validationMessage(
            recipes: recipes,
            days: days,
            dietConstraints: dietConstraints
        ) {
            throw MenuIntentError.validationFailed(validationMessage)
        }

        // Cancellation throws — let it propagate so perform() stops without generating.
        try await requestConfirmation(
            actionName: .continue,
            dialog: IntentDialog("This replaces your current weekly menu.")
        )

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
        return .result(
            value: dialog,
            dialog: IntentDialog(LocalizedStringResource(stringLiteral: dialog))
        )
    }
}
