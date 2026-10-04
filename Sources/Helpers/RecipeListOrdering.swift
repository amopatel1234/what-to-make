//
//  RecipeListOrdering.swift
//  whattomake
//

import Foundation
import SwiftData

/// Pure helpers for persisting manual recipe library order.
///
/// The Recipes list stores order in ``Recipe/sortOrder``. SwiftUI reordering
/// (iOS 27 `reorderable` / `reorderContainer`, or accessibility move actions)
/// mutates an ordered array, then this type rewrites contiguous `sortOrder`
/// values and callers save via `ModelContext`.
enum RecipeListOrdering {
    /// Sort descriptors for the recipe library: manual order, then name.
    static var librarySortDescriptors: [SortDescriptor<Recipe>] {
        [
            SortDescriptor(\Recipe.sortOrder),
            SortDescriptor(\Recipe.name)
        ]
    }

    /// Next `sortOrder` for a newly inserted recipe (appends after existing rows).
    /// - Parameter context: SwiftData context to scan for the current maximum.
    /// - Returns: `0` when the library is empty; otherwise `max(sortOrder) + 1`.
    @MainActor
    static func nextSortOrder(in context: ModelContext) throws -> Int {
        var descriptor = FetchDescriptor<Recipe>(
            sortBy: [SortDescriptor(\Recipe.sortOrder, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        let highest = try context.fetch(descriptor).first?.sortOrder ?? -1
        return highest + 1
    }

    /// Moves recipes using `IndexSet` offsets (same semantics as `Array.move`).
    ///
    /// - Parameters:
    ///   - recipes: Library recipes in current display order.
    ///   - sourceIndices: Indices of recipes being moved.
    ///   - destinationIndex: Index to insert before (may be `recipes.count` for end).
    static func moveRecipes(
        _ recipes: [Recipe],
        from sourceIndices: IndexSet,
        to destinationIndex: Int
    ) {
        var ordered = recipes
        ordered.move(fromOffsets: sourceIndices, toOffset: destinationIndex)
        renumberSortOrders(ordered)
    }

    /// Moves a single recipe by UUID identity before another recipe, or to the end.
    ///
    /// Mirrors iOS 27 `ReorderDifference` destination semantics without depending
    /// on that SDK type, so unit tests can exercise the persistence model on any OS.
    ///
    /// - Parameters:
    ///   - recipes: Library recipes in current display order.
    ///   - sourceIDs: Stable recipe IDs to move, in selection order.
    ///   - beforeDestinationID: When non-`nil`, insert before this recipe; when `nil`, append.
    static func moveRecipes(
        _ recipes: [Recipe],
        moving sourceIDs: [UUID],
        before destinationID: UUID?
    ) {
        var ordered = recipes
        var moved: [Recipe] = []
        moved.reserveCapacity(sourceIDs.count)

        for sourceID in sourceIDs {
            guard let index = ordered.firstIndex(where: { $0.id == sourceID }) else {
                continue
            }
            moved.append(ordered.remove(at: index))
        }

        guard !moved.isEmpty else { return }

        let insertIndex: Int
        if let destinationID,
           let destinationIndex = ordered.firstIndex(where: { $0.id == destinationID }) {
            insertIndex = destinationIndex
        } else {
            insertIndex = ordered.count
        }

        ordered.insert(contentsOf: moved, at: insertIndex)
        renumberSortOrders(ordered)
    }

    /// Writes contiguous `sortOrder` values `0..<count` for `recipes` in order.
    static func renumberSortOrders(_ recipes: [Recipe]) {
        for (index, recipe) in recipes.enumerated() {
            recipe.sortOrder = index
        }
    }
}
