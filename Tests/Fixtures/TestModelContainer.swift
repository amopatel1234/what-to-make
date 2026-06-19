//
//  TestModelContainer.swift
//  whattomake
//

import Foundation
import SwiftData
@testable import ForkPlan

/// Creates an in-memory SwiftData container for unit and snapshot tests.
///
/// - Throws: If `ModelContainer` initialization fails.
@MainActor
func makeTestContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: Recipe.self, Menu.self,
        configurations: configuration
    )
}

/// Seeds recipes into the context and saves.
///
/// - Parameters:
///   - context: The model context to insert into.
///   - count: Number of recipes (default 8 — satisfies the ≥ 7 product rule).
///   - namePrefix: Prefix for generated names (e.g. "Test Recipe 1").
///   - notesEvery: When set, every Nth recipe gets a note (default 2).
///   - usageCount: Initial usage count for each recipe.
/// - Returns: Inserted recipes sorted by name ascending.
@MainActor
func seedRecipes(
    in context: ModelContext,
    count: Int = 8,
    namePrefix: String = "Test Recipe",
    notesEvery: Int? = 2,
    usageCount: Int = 0
) throws -> [Recipe] {
    for index in 1...count {
        let recipe = Recipe(
            name: "\(namePrefix) \(index)",
            notes: notesEvery.map { index.isMultiple(of: $0) ? "Note \(index)" : nil } ?? nil,
            usageCount: usageCount
        )
        context.insert(recipe)
    }
    try context.save()
    return try context.fetch(FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.name)]))
}

/// Seeds a menu snapshot linking existing recipes to day IDs.
///
/// - Parameters:
///   - context: The model context to insert into.
///   - days: Ordered day identifiers (e.g. `["Mon", "Wed"]`).
///   - recipes: Recipes corresponding to days (caller supplies — does not auto-create).
///   - generatedDate: Menu generation timestamp.
/// - Returns: The inserted menu after save.
@MainActor
func seedMenu(
    in context: ModelContext,
    days: [String],
    recipes: [Recipe],
    generatedDate: Date = Date()
) throws -> Menu {
    let menu = Menu(generatedDate: generatedDate, days: days, recipes: recipes)
    context.insert(menu)
    try context.save()
    return menu
}
