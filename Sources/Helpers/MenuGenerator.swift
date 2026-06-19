//
//  MenuGenerator.swift
//  whattomake
//
//  Created by Amish Patel on 16/06/2026.
//

import Foundation

/// Sendable recipe snapshot for non-isolated menu selection.
struct RecipeSelectionInput: Sendable, Equatable {
    let id: UUID
    let name: String
    let usageCount: Int
}

/// Pure menu selection logic — shuffle + prefix, mirroring legacy use case semantics.
struct MenuGenerator {
    /// Selects one recipe per requested day via shuffle and prefix.
    /// - Parameters:
    ///   - recipes: Available recipe snapshots to choose from.
    ///   - days: Ordered day identifiers; count determines selection size.
    /// - Returns: Selected recipe snapshots in day order (may be fewer than `days.count` if insufficient recipes).
    static func select(from recipes: [RecipeSelectionInput], forDays days: [String]) -> [RecipeSelectionInput] {
        var shuffled = recipes
        shuffled.shuffle()
        return Array(shuffled.prefix(days.count))
    }
}
