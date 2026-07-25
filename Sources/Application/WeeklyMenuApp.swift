//
//  WeeklyMenuApp.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


import AppIntents
import SwiftUI
import SwiftData

@main
struct WeeklyMenuApp: App {
    private static let isRunningUnderTests = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil

    private let modelContainer: ModelContainer

    init() {
        DaySelectionStorage.registerDefaults()

        if Self.isRunningUnderTests {
            modelContainer = (try? ForkPlanModelContainer.makeInMemory())
                ?? ForkPlanModelContainer.shared
        } else {
            modelContainer = ForkPlanModelContainer.shared
        }

        let container = modelContainer
        let asyncDependency: @Sendable () async -> ModelContainer = { @MainActor in
            container
        }
        AppDependencyManager.shared.add(key: "ModelContainer", dependency: asyncDependency)
        ForkPlanShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            RootTabsView()
                .fpAppTheme()
        }
        .modelContainer(modelContainer)
    }
}
