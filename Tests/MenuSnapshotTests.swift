//
//  MenuSnapshotTests.swift
//  whattomake
//

@testable import ForkPlan
import SnapshotTesting
import SwiftData
import SwiftUI
import Testing

@MainActor
@Suite(.serialized)
struct MenuSnapshotTests {
    private let selectedDaysKey = AppStorageKey.selectedDays.rawValue

    private func resetSelectedDays() {
        UserDefaults.standard.removeObject(forKey: selectedDaysKey)
    }

    @Test
    func generatedMenuState() throws {
        defer { resetSelectedDays() }

        resetSelectedDays()
        let container = try makeTestContainer()
        let context = container.mainContext
        let recipes = try seedRecipes(in: context, count: 8)
        let menuRecipes = [recipes[0], recipes[2], recipes[4]]
        _ = try seedMenu(
            in: context,
            days: ["Mon", "Wed", "Fri"],
            recipes: menuRecipes,
            generatedDate: Date(timeIntervalSince1970: 1_700_000_000)
        )
        UserDefaults.standard.set("Mon,Wed,Fri", forKey: selectedDaysKey)

        let view = SnapshotTestConfiguration.applyBaselineEnvironment(
            to: SnapshotTestConfiguration.queryReady(
                GenerateMenuView()
                    .modelContainer(container)
            )
        )
        SnapshotTestConfiguration.assertBaselineSnapshot(
            of: view,
            named: "menu-generated"
        )
    }

    @Test
    func emptyMenuState() throws {
        defer { resetSelectedDays() }

        resetSelectedDays()
        let container = try makeTestContainer()
        let context = container.mainContext
        _ = try seedRecipes(in: context, count: 8)
        UserDefaults.standard.set(DaySelectionStorage.defaultValue, forKey: selectedDaysKey)

        let view = SnapshotTestConfiguration.applyBaselineEnvironment(
            to: SnapshotTestConfiguration.queryReady(
                GenerateMenuView()
                    .modelContainer(container)
            )
        )
        SnapshotTestConfiguration.assertBaselineSnapshot(
            of: view,
            named: "menu-empty"
        )
    }
}
