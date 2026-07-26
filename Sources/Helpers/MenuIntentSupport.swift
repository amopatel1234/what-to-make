//
//  MenuIntentSupport.swift
//  whattomake
//
//  Created by Cursor on 25/07/2026.
//

import Foundation
import SwiftData

/// Errors surfaced through App Intents (validation / empty results that should fail the run).
enum MenuIntentError: Error, CustomLocalizedStringResourceConvertible {
    /// Menu generation cannot proceed; associated value is the user-visible reason.
    case validationFailed(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .validationFailed(let message):
            LocalizedStringResource(stringLiteral: message)
        }
    }
}

/// Pure helpers shared by App Intents: fetch latest menu, format spoken dialogs,
/// and load saved day/diet preferences from `UserDefaults`.
enum MenuIntentSupport {
    /// Spoken / Shortcuts result for “what’s for dinner?”.
    struct TodaysMealResult: Equatable, Sendable {
        let dialog: String
        /// Recipe name when a meal was resolved; `nil` when Shortcuts should not treat a value as a recipe.
        let recipeName: String?
        let day: String?
        let kind: MenuHighlightDay.Kind?
    }

    /// Fetches the newest menu snapshot, if any.
    @MainActor
    static func latestMenu(in context: ModelContext) throws -> Menu? {
        var descriptor = Menu.latestDescriptor()
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    /// Fetches the recipe library sorted by name.
    @MainActor
    static func allRecipes(in context: ModelContext) throws -> [Recipe] {
        try context.fetch(FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.name)]))
    }

    /// Day selection last saved by the Menu tab / generation flow.
    static func savedSelectedDays(
        defaults: UserDefaults = .standard
    ) -> Set<String> {
        let raw = defaults.string(forKey: AppStorageKey.selectedDays.rawValue)
            ?? DaySelectionStorage.defaultValue
        return DaySelectionStorage.decode(raw)
    }

    /// Per-day diet constraints last saved by the Menu tab / generation flow.
    static func savedDietConstraints(
        defaults: UserDefaults = .standard
    ) -> [String: DayDietConstraint] {
        let raw = defaults.string(forKey: AppStorageKey.dayDietConstraints.rawValue)
            ?? DayDietConstraintStorage.defaultValue
        return DayDietConstraintStorage.decode(raw)
    }

    /// Builds the “today / up next” dialog from a menu snapshot.
    static func todaysMeal(
        menu: Menu?,
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> TodaysMealResult {
        guard let menu else {
            return TodaysMealResult(
                dialog: "No menu yet. Generate one in ForkPlan first.",
                recipeName: nil,
                day: nil,
                kind: nil
            )
        }

        let recipeNames = orderedRecipeNames(for: menu)
        guard !recipeNames.isEmpty else {
            return TodaysMealResult(
                dialog: "Nothing planned for today.",
                recipeName: nil,
                day: nil,
                kind: nil
            )
        }

        let rows = Array(zip(menu.days, recipeNames))
        guard let highlight = MenuHighlightDay.resolve(
            menuDays: menu.days,
            on: referenceDate,
            calendar: calendar
        ),
            let recipeName = rows.first(where: { $0.0 == highlight.day })?.1
        else {
            return TodaysMealResult(
                dialog: "Nothing planned for today.",
                recipeName: nil,
                day: nil,
                kind: nil
            )
        }

        switch highlight.kind {
        case .today:
            return TodaysMealResult(
                dialog: "Today you're having \(recipeName).",
                recipeName: recipeName,
                day: highlight.day,
                kind: .today
            )
        case .upNext:
            return TodaysMealResult(
                dialog: "Up next (\(highlight.day)): \(recipeName).",
                recipeName: recipeName,
                day: highlight.day,
                kind: .upNext
            )
        }
    }

    /// Spoken summary of the week, or a missing-menu message.
    static func weeklyMenuDialog(menu: Menu?) -> String {
        if let summary = weeklyMenuSummary(menu: menu) {
            return summary
        }
        return "No weekly menu yet. Generate one in ForkPlan first."
    }

    /// Day → recipe summary for Shortcuts chaining, or `nil` when there is no usable plan.
    static func weeklyMenuSummary(menu: Menu?) -> String? {
        guard let menu else { return nil }
        let recipeNames = orderedRecipeNames(for: menu)
        guard !recipeNames.isEmpty else { return nil }
        let rows = Array(zip(menu.days, recipeNames))
        return rows.map { "\($0.0): \($0.1)" }.joined(separator: ". ") + "."
    }

    /// Success dialog after ``MenuGeneration/run`` replaces the stored menu.
    static func generationSuccessDialog(menu: Menu) -> String {
        if let summary = weeklyMenuSummary(menu: menu) {
            return "New plan ready. \(summary)"
        }
        return "New plan ready."
    }

    /// Ordered names parallel to ``Menu/days``.
    ///
    /// Uses ``Menu/recipeNames`` only — SwiftData relationship order on ``Menu/recipes``
    /// is not day-parallel.
    private static func orderedRecipeNames(for menu: Menu) -> [String] {
        guard menu.recipeNames.count == menu.days.count else { return [] }
        return menu.recipeNames
    }
}
