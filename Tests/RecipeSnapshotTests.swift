//
//  RecipeSnapshotTests.swift
//  whattomake
//

@testable import ForkPlan
import SnapshotTesting
import SwiftData
import SwiftUI
import Testing

@MainActor
@Suite(.serialized)
struct RecipeSnapshotTests {
    @Test
    func emptyRecipesList() throws {
        let container = try makeTestContainer()
        let view = SnapshotTestConfiguration.applyBaselineEnvironment(
            to: SnapshotTestConfiguration.queryReady(
                RecipesView()
                    .modelContainer(container)
            )
        )
        SnapshotTestConfiguration.assertBaselineSnapshot(
            of: view,
            named: "recipes-empty"
        )
    }

    @Test
    func recipesListWithData() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        _ = try seedRecipes(in: context, count: 4)

        let view = SnapshotTestConfiguration.applyBaselineEnvironment(
            to: SnapshotTestConfiguration.queryReady(
                RecipesView()
                    .modelContainer(container)
            )
        )
        SnapshotTestConfiguration.assertBaselineSnapshot(
            of: view,
            named: "recipes-with-data"
        )
    }
}
