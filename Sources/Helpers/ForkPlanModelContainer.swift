//
//  ForkPlanModelContainer.swift
//  whattomake
//
//  Created by Cursor on 25/07/2026.
//

import Foundation
import SwiftData

/// Shared SwiftData container for the app UI and App Intents.
///
/// Intents run outside the SwiftUI view tree, so they cannot rely on
/// `@Environment(\.modelContext)`. Both surfaces use this container so reads and
/// writes hit the same persistent store.
enum ForkPlanModelContainer {
    /// Persistent store used by the running app and App Intents.
    ///
    /// Lazily created so SwiftUI previews that never touch intents avoid opening
    /// the on-disk store unless needed.
    static let shared: ModelContainer = {
        do {
            return try ModelContainer(
                for: Recipe.self,
                Menu.self,
                RecipeIngredient.self
            )
        } catch {
            fatalError("Failed to create ForkPlan ModelContainer: \(error)")
        }
    }()

    /// In-memory container for unit tests and the XCTest host path in ``WeeklyMenuApp``.
    static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Recipe.self,
            Menu.self,
            RecipeIngredient.self,
            configurations: configuration
        )
    }
}
