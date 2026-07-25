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

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let context = ModelContext(ForkPlanModelContainer.shared)
        let menu = try MenuIntentSupport.latestMenu(in: context)
        let dialog = MenuIntentSupport.weeklyMenuDialog(menu: menu)
        return .result(value: dialog, dialog: IntentDialog(LocalizedStringResource(stringLiteral: dialog)))
    }
}
