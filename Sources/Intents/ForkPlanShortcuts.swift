//
//  ForkPlanShortcuts.swift
//  whattomake
//
//  Created by Cursor on 25/07/2026.
//

import AppIntents

/// Registers Siri / Shortcuts phrases for ForkPlan menu intents.
struct ForkPlanShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetTodaysMealIntent(),
            phrases: [
                "What's for dinner in \(.applicationName)",
                "What's for dinner today in \(.applicationName)",
                "What am I cooking today in \(.applicationName)"
            ],
            shortTitle: "Today's meal",
            systemImageName: "fork.knife"
        )
        AppShortcut(
            intent: GetWeeklyMenuIntent(),
            phrases: [
                "What's my menu this week in \(.applicationName)",
                "Show my meal plan in \(.applicationName)",
                "What's on the menu in \(.applicationName)"
            ],
            shortTitle: "Weekly menu",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: GenerateWeeklyMenuIntent(),
            phrases: [
                "Generate my menu in \(.applicationName)",
                "Make a new meal plan in \(.applicationName)",
                "Plan my week in \(.applicationName)"
            ],
            shortTitle: "Generate menu",
            systemImageName: "arrow.triangle.2.circlepath"
        )
    }
}
