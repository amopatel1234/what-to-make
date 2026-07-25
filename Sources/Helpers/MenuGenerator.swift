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
    let dietaryKind: RecipeDietaryKind
}

/// One ordered day plus its diet constraint for menu selection.
struct DayMenuRequest: Sendable, Equatable {
    let day: String
    let diet: DayDietConstraint
}

/// Pure menu selection logic — diet-aware pools with shuffle, no duplicates.
struct MenuGenerator {
    /// Selects one recipe per day, preferring stricter diet pools first.
    ///
    /// Assignment order is vegan → vegetarian → any so restricted days are not
    /// starved by unconstrained picks. Within each day, eligible remaining recipes
    /// are shuffled and one is taken. Results are returned in `requests` order.
    ///
    /// - Parameters:
    ///   - recipes: Available recipe snapshots to choose from.
    ///   - requests: Ordered day + diet pairs; count determines selection size.
    /// - Returns: Selected recipe snapshots in request order (may be fewer than
    ///   `requests.count` when a pool cannot fill a day).
    static func select(
        from recipes: [RecipeSelectionInput],
        requests: [DayMenuRequest]
    ) -> [RecipeSelectionInput] {
        guard !requests.isEmpty, !recipes.isEmpty else { return [] }

        var remaining = recipes
        var pickedByDay: [String: RecipeSelectionInput] = [:]

        let pickingOrder = requests.sorted { lhs, rhs in
            if lhs.diet.assignmentPriority != rhs.diet.assignmentPriority {
                return lhs.diet.assignmentPriority > rhs.diet.assignmentPriority
            }
            return false
        }

        for request in pickingOrder {
            var pool = remaining.filter { $0.dietaryKind.satisfies(request.diet) }
            guard !pool.isEmpty else { continue }
            pool.shuffle()
            let chosen = pool[0]
            pickedByDay[request.day] = chosen
            remaining.removeAll { $0.id == chosen.id }
        }

        return requests.compactMap { pickedByDay[$0.day] }
    }

    /// Convenience for unconstrained days (all ``DayDietConstraint/any``).
    static func select(
        from recipes: [RecipeSelectionInput],
        forDays days: [String]
    ) -> [RecipeSelectionInput] {
        select(
            from: recipes,
            requests: days.map { DayMenuRequest(day: $0, diet: .any) }
        )
    }
}
