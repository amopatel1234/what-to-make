//
//  MenuGenerator.swift
//  whattomake
//
//  Created by Amish Patel on 16/06/2026.
//

import Foundation

/// Pure menu selection logic — shuffle + prefix, mirroring legacy use case semantics.
struct MenuGenerator {
    /// Selects one recipe per requested day via shuffle and prefix.
    /// - Parameters:
    ///   - recipes: Available recipes to choose from.
    ///   - days: Ordered day identifiers; count determines selection size.
    /// - Returns: Selected recipes in day order (may be fewer than `days.count` if insufficient recipes).
    static func select(from recipes: [Recipe], forDays days: [String]) -> [Recipe] {
        var shuffled = recipes
        shuffled.shuffle()
        return Array(shuffled.prefix(days.count))
    }
}
