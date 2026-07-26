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

    /// Dependency key shared with App Intents (`@Dependency(key:)`).
    static let modelContainerDependencyKey = "ModelContainer"

    private let modelContainer: ModelContainer

    init() {
        DaySelectionStorage.registerDefaults()

        if Self.isRunningUnderTests {
            do {
                modelContainer = try ForkPlanModelContainer.makeInMemory()
            } catch {
                fatalError("Failed to create in-memory ModelContainer for tests: \(error)")
            }
        } else {
            modelContainer = ForkPlanModelContainer.shared
        }

        let container = modelContainer
        let asyncDependency: @Sendable () async -> ModelContainer = { @MainActor in
            container
        }
        AppDependencyManager.shared.add(
            key: Self.modelContainerDependencyKey,
            dependency: asyncDependency
        )
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
