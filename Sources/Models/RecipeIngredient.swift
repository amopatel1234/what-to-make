//
//  RecipeIngredient.swift
//  whattomake
//
//  Created by Amish Patel on 20/06/2026.
//

import Foundation
import SwiftData

/// A single ingredient line on a recipe, stored as entered (no unit conversion).
@Model
final class RecipeIngredient {
    /// Ingredient name (e.g. "chicken breast").
    var name: String
    /// Optional numeric amount (e.g. 400).
    var amount: Decimal?
    /// Optional free-text unit (e.g. "g", "tbsp", "cup").
    var unit: String?
    /// Display order within the parent recipe.
    var sortOrder: Int
    /// Parent recipe for this ingredient line.
    var recipe: Recipe?

    /// Creates an ingredient line.
    /// - Parameters:
    ///   - name: Required ingredient name.
    ///   - amount: Optional numeric amount.
    ///   - unit: Optional unit label stored as entered.
    ///   - sortOrder: Zero-based position in the recipe ingredient list.
    init(name: String, amount: Decimal? = nil, unit: String? = nil, sortOrder: Int = 0) {
        self.name = name
        self.amount = amount
        self.unit = unit
        self.sortOrder = sortOrder
    }
}
