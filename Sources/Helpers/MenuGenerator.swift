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
    /// Times the user has marked this recipe as cooked.
    let timesCooked: Int
    /// When the user last marked this recipe as cooked, if ever.
    let lastCookedAt: Date?
    let dietaryKind: RecipeDietaryKind
}

/// One ordered day plus its diet constraint for menu selection.
struct DayMenuRequest: Sendable, Equatable {
    let day: String
    let diet: DayDietConstraint
}

/// Pure menu selection logic — diet-aware pools with cook-recency weighting, no duplicates.
struct MenuGenerator {
    /// Weight for recipes never marked cooked (high → more likely to be picked).
    static let neverCookedWeight: Double = 3_650

    /// Selects one recipe per day, preferring stricter diet pools first.
    ///
    /// Assignment order is vegan → vegetarian → any so restricted days are not
    /// starved by unconstrained picks. Within each day, eligible remaining recipes
    /// are weighted by cook recency (never / longer-ago cooked preferred) and one
    /// is taken. Results are returned in `requests` order.
    ///
    /// - Parameters:
    ///   - recipes: Available recipe snapshots to choose from.
    ///   - requests: Ordered day + diet pairs; count determines selection size.
    ///   - now: Reference time for recency weights (defaults to `Date()`).
    ///   - randomValue: Supplies values in `0..<1` for weighted picks; defaults to
    ///     `Double.random(in: 0..<1)`. Inject in tests for determinism.
    /// - Returns: Selected recipe snapshots in request order (may be fewer than
    ///   `requests.count` when a pool cannot fill a day).
    static func select(
        from recipes: [RecipeSelectionInput],
        requests: [DayMenuRequest],
        now: Date = Date(),
        randomValue: () -> Double = { Double.random(in: 0..<1) }
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
            let pool = remaining.filter { $0.dietaryKind.satisfies(request.diet) }
            guard let chosen = pickWeighted(from: pool, now: now, randomValue: randomValue) else {
                continue
            }
            pickedByDay[request.day] = chosen
            remaining.removeAll { $0.id == chosen.id }
        }

        return requests.compactMap { pickedByDay[$0.day] }
    }

    /// Convenience for unconstrained days (all ``DayDietConstraint/any``).
    static func select(
        from recipes: [RecipeSelectionInput],
        forDays days: [String],
        now: Date = Date(),
        randomValue: () -> Double = { Double.random(in: 0..<1) }
    ) -> [RecipeSelectionInput] {
        select(
            from: recipes,
            requests: days.map { DayMenuRequest(day: $0, diet: .any) },
            now: now,
            randomValue: randomValue
        )
    }

    /// Picks a single recipe for one day, excluding IDs already used elsewhere.
    static func selectOne(
        from recipes: [RecipeSelectionInput],
        diet: DayDietConstraint,
        excluding excludedIDs: Set<UUID>,
        now: Date = Date(),
        randomValue: () -> Double = { Double.random(in: 0..<1) }
    ) -> RecipeSelectionInput? {
        let pool = recipes.filter { recipe in
            !excludedIDs.contains(recipe.id) && recipe.dietaryKind.satisfies(diet)
        }
        return pickWeighted(from: pool, now: now, randomValue: randomValue)
    }

    /// Higher weight → more likely. Never-cooked recipes get ``neverCookedWeight``;
    /// otherwise weight is days since last cooked (minimum 1).
    static func cookRecencyWeight(lastCookedAt: Date?, now: Date) -> Double {
        guard let lastCookedAt else { return neverCookedWeight }
        let days = now.timeIntervalSince(lastCookedAt) / 86_400
        return max(1, days)
    }

    /// Weighted pick from `pool`. `randomValue` must be in `0..<1` (values outside are clamped).
    static func pickWeighted(
        from pool: [RecipeSelectionInput],
        now: Date,
        randomValue: () -> Double
    ) -> RecipeSelectionInput? {
        guard !pool.isEmpty else { return nil }
        if pool.count == 1 { return pool[0] }

        let weights = pool.map { cookRecencyWeight(lastCookedAt: $0.lastCookedAt, now: now) }
        let total = weights.reduce(0, +)
        guard total > 0 else { return pool[0] }

        let clamped = min(max(randomValue(), 0), 0.999_999_999)
        var cursor = clamped * total
        for (index, weight) in weights.enumerated() {
            cursor -= weight
            if cursor < 0 {
                return pool[index]
            }
        }
        return pool.last
    }
}
