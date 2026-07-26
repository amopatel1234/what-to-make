//
//  RecipeImagePlaygroundPrompt.swift
//  whattomake
//
//  Created by Cursor on 26/07/2026.
//

import Foundation

/// Version-agnostic inputs for generating a recipe photo via Image Playground.
///
/// Keep this struct stable across OS versions so the iOS 26 sheet presenter and any
/// iOS 27 successor share the same seeding logic.
struct RecipeImageGenerationRequest: Equatable, Sendable {
    var recipeName: String
    var ingredientNames: [String]
    var notes: String
    var dietaryKind: RecipeDietaryKind
}

/// Builds short text concepts for Image Playground from recipe fields.
///
/// Pure and unit-testable — no ImagePlayground framework dependency — so the same
/// prompts can feed `.imagePlaygroundSheet` today and a future iOS 27 API.
enum RecipeImagePlaygroundPrompt {
    /// Maximum ingredient names included in the supporting concept (keeps prompts short).
    static let maxIngredientNames = 6

    /// Whether the request has enough identity to seed Image Playground usefully.
    static func canGenerate(from request: RecipeImageGenerationRequest) -> Bool {
        !request.recipeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Primary short concept (recipe title + food photo framing).
    static func primaryConcept(for request: RecipeImageGenerationRequest) -> String {
        let name = request.recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "homemade meal plated for a cookbook photo" }
        return "\(name), appetizing homemade food photography, plated dish"
    }

    /// Short supporting concepts (ingredients + diet). Notes use extraction separately.
    static func supportingConcepts(for request: RecipeImageGenerationRequest) -> [String] {
        var concepts: [String] = []

        let ingredients = request.ingredientNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !ingredients.isEmpty {
            let limited = Array(ingredients.prefix(maxIngredientNames))
            concepts.append("key ingredients: " + limited.joined(separator: ", "))
        }

        switch request.dietaryKind {
        case .standard:
            break
        case .vegetarian:
            concepts.append("vegetarian dish")
        case .vegan:
            concepts.append("vegan plant-based dish")
        }

        return concepts
    }

    /// Ordered short concept strings for seeding (primary first). Notes excluded.
    static func conceptTexts(for request: RecipeImageGenerationRequest) -> [String] {
        [primaryConcept(for: request)] + supportingConcepts(for: request)
    }

    /// Longer notes body for ``ImagePlaygroundConcept/extracted(from:title:)`` when present.
    static func notesExtractionSource(for request: RecipeImageGenerationRequest) -> String? {
        let notes = request.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard notes.count >= 40 else { return nil }
        return notes
    }
}
