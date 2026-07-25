//
//  RecipeDietaryKind.swift
//  whattomake
//
//  Created by Amish Patel on 25/07/2026.
//

import Foundation

/// User-set dietary classification for a recipe.
///
/// - ``standard``: No vegetarian/vegan restriction (may include meat or animal products).
/// - ``vegetarian``: No meat; dairy and eggs are allowed.
/// - ``vegan``: No animal products. Also satisfies vegetarian day constraints.
enum RecipeDietaryKind: String, Codable, CaseIterable, Sendable {
    case standard
    case vegetarian
    case vegan

    /// Short label for segmented controls and lists.
    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .vegetarian: return "Vegetarian"
        case .vegan: return "Vegan"
        }
    }

    /// Whether this recipe may be assigned to a day with the given diet constraint.
    func satisfies(_ constraint: DayDietConstraint) -> Bool {
        switch constraint {
        case .any:
            return true
        case .vegetarian:
            return self == .vegetarian || self == .vegan
        case .vegan:
            return self == .vegan
        }
    }
}

/// Per-day diet filter applied during menu generation.
///
/// - ``any``: Any recipe may be assigned.
/// - ``vegetarian``: Only vegetarian or vegan recipes.
/// - ``vegan``: Only vegan recipes.
enum DayDietConstraint: String, CaseIterable, Sendable {
    case any
    case vegetarian
    case vegan

    /// Short label for the day-plan segmented control.
    var shortDisplayName: String {
        switch self {
        case .any: return "Any"
        case .vegetarian: return "Veg"
        case .vegan: return "Vegan"
        }
    }

    /// Higher values are assigned first so stricter pools are not starved.
    var assignmentPriority: Int {
        switch self {
        case .vegan: return 2
        case .vegetarian: return 1
        case .any: return 0
        }
    }
}
