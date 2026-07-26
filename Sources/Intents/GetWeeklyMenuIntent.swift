//
//  GetWeeklyMenuIntent.swift
//  whattomake
//
//  Created by Cursor on 25/07/2026.
//

import AppIntents
import SwiftData

/// Returns the full day → recipe snapshot from the latest menu.
struct GetWeeklyMenuIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Weekly Menu"
    static let description = IntentDescription(
        "Reads your latest ForkPlan weekly meal plan."
    )
    static let openAppWhenRun = false

    /// Must match ``WeeklyMenuApp/modelContainerDependencyKey``.
    @Dependency(key: "ModelContainer")
    private var modelContainer: ModelContainer

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String?> {
        let context = ModelContext(modelContainer)
        let menu = try MenuIntentSupport.latestMenu(in: context)
        let summary = MenuIntentSupport.weeklyMenuSummary(menu: menu)
        let dialog = MenuIntentSupport.weeklyMenuDialog(menu: menu)
        return .result(
            value: summary,
            dialog: IntentDialog(LocalizedStringResource(stringLiteral: dialog))
        )
    }
}
