//
//  GetTodaysMealIntent.swift
//  whattomake
//
//  Created by Cursor on 25/07/2026.
//

import AppIntents
import SwiftData

/// Returns today’s planned recipe from the latest menu (or the next planned day).
struct GetTodaysMealIntent: AppIntent {
    static let title: LocalizedStringResource = "What's for Dinner"
    static let description = IntentDescription(
        "Looks up today’s meal from your latest ForkPlan menu."
    )
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let context = ModelContext(ForkPlanModelContainer.shared)
        let menu = try MenuIntentSupport.latestMenu(in: context)
        let result = MenuIntentSupport.todaysMeal(menu: menu)
        return .result(value: result.recipeName ?? result.dialog, dialog: IntentDialog(LocalizedStringResource(stringLiteral: result.dialog)))
    }
}
