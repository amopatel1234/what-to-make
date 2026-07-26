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
/// Intents resolve this container via `AppDependencyManager` (`@Dependency`) so they
/// share the same store as ``WeeklyMenuApp``. The persistent ``shared`` instance is
/// the production fallback registered at launch.
enum ForkPlanModelContainer {
    /// Persistent store used by the running app (and registered for App Intents).
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
    ///
    /// Callers must not fall back to ``shared`` on failure — that would open the
    /// on-disk store under test.
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
