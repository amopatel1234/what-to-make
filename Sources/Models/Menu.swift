//
//  Menu.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//

import Foundation
import SwiftData

/// A SwiftData model representing a generated weekly menu snapshot.
///
/// The model stores the days the user selected along with the chosen recipes
/// at the time of generation. The UI should render rows from this snapshot
/// (day + recipe name) to avoid diffing against live, mutable models.
///
/// Example
/// ```swift
/// let menu = Menu(days: ["Mon", "Wed"], recipes: [r1, r2])
/// ```
@Model
final class Menu {
    /// Stable unique identifier for the menu.
    @Attribute(.unique) var id: UUID
    /// The date and time when the menu was generated.
    var generatedDate: Date
    /// The ordered list of day identifiers (e.g., "Mon", "Tue").
    var days: [String]
    /// The recipes chosen for the corresponding ``days`` entries.
    var recipes: [Recipe]

    /// Creates a new menu snapshot.
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if omitted).
    ///   - generatedDate: Generation timestamp (defaults to `Date()`).
    ///   - days: Ordered identifiers for the days included in this menu.
    ///   - recipes: Selected recipes in the order corresponding to ``days``.
    init(id: UUID = UUID(), generatedDate: Date = Date(), days: [String], recipes: [Recipe]) {
        self.id = id
        self.generatedDate = generatedDate
        self.days = days
        self.recipes = recipes
    }
}
