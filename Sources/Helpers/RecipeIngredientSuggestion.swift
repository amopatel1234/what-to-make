//
//  RecipeIngredientSuggestion.swift
//  whattomake
//
//  Created by Cursor on 26/07/2026.
//

import Foundation
import FoundationModels

// MARK: - Guided generation

@Generable(description: "Ingredients that are typically needed for a recipe but are not already listed")
struct GenerableIngredientSuggestions {
    @Guide(description: "Suggested ingredients not already in the recipe; empty if none")
    var ingredients: [GenerableRecipeIngredient]

    /// Explicit memberwise init — `@Generable` may not preserve a usable one for tests.
    init(ingredients: [GenerableRecipeIngredient]) {
        self.ingredients = ingredients
    }
}

// MARK: - App-facing draft

/// One suggested ingredient the user may add after review.
struct RecipeIngredientSuggestion: Equatable, Sendable, Identifiable {
    var id: String { "\(name.lowercased())|\(amountText)|\(unit)" }
    var name: String
    var amountText: String
    var unit: String
}

/// User-visible failures from ingredient suggestion.
enum RecipeIngredientSuggestionError: Error, Equatable, LocalizedError {
    case missingRecipeName
    case modelUnavailable(String)
    case suggestionFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingRecipeName:
            return "Add a recipe name before suggesting ingredients."
        case .modelUnavailable(let message):
            return message
        case .suggestionFailed(let message):
            return message
        }
    }
}

// MARK: - Suggestor

/// On-device Foundation Models suggestions for ingredients missing from a recipe draft.
///
/// Works from **recipe name alone**; notes and existing ingredients refine suggestions when present.
enum RecipeIngredientSuggestor {
    /// Shared disclaimer for any Apple Intelligence–generated recipe fields.
    static let generatedContentDisclaimer =
        "Always check Apple Intelligence suggestions before saving — they can be wrong or incomplete."

    /// Whether the system language model can run on this device right now.
    static var isModelAvailable: Bool {
        RecipePasteExtractor.isModelAvailable
    }

    /// Explains why suggestion is disabled, or `nil` when available.
    static var unavailableReasonMessage: String? {
        RecipePasteExtractor.unavailableReasonMessage
    }

    /// Maps guided output into app suggestions, dropping blanks and duplicates of `existingNames`.
    static func mapGenerable(
        _ value: GenerableIngredientSuggestions,
        excludingExistingNames existingNames: [String]
    ) -> [RecipeIngredientSuggestion] {
        let excluded = Set(
            existingNames
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                .filter { !$0.isEmpty }
        )
        var seen = excluded
        var result: [RecipeIngredientSuggestion] = []
        for ingredient in value.ingredients {
            let name = ingredient.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { continue }
            let key = name.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(
                RecipeIngredientSuggestion(
                    name: name,
                    amountText: ingredient.amountText.trimmingCharacters(in: .whitespacesAndNewlines),
                    unit: ingredient.unit.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            )
        }
        return result
    }

    /// Suggests ingredients for a recipe. Notes may be empty; name is required.
    static func suggest(
        recipeName: String,
        notes: String,
        dietaryKind: RecipeDietaryKind,
        existingIngredients: [RecipePasteIngredientDraft]
    ) async throws -> [RecipeIngredientSuggestion] {
        let trimmedName = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw RecipeIngredientSuggestionError.missingRecipeName
        }
        if let unavailable = unavailableReasonMessage {
            throw RecipeIngredientSuggestionError.modelUnavailable(unavailable)
        }

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingLines = existingIngredients.map { ingredient in
            let amount = ingredient.amountText.isEmpty ? "" : " \(ingredient.amountText)"
            let unit = ingredient.unit.isEmpty ? "" : " \(ingredient.unit)"
            return "- \(ingredient.name)\(amount)\(unit)"
        }
        let existingBlock = existingLines.isEmpty
            ? "(none listed yet)"
            : existingLines.joined(separator: "\n")
        let notesBlock = trimmedNotes.isEmpty ? "(none)" : trimmedNotes

        let session = LanguageModelSession {
            """
            Suggest common ingredients that are missing from this recipe draft.
            Prefer essentials for the dish named. Respect the dietary kind.
            Do not repeat ingredients already listed. Notes may be empty — then
            rely on the recipe name and diet only. Leave amountText and unit
            empty when unsure. Suggest at most 8 ingredients.
            """
        }

        let extracted: GenerableIngredientSuggestions
        do {
            let response = try await session.respond(
                to: """
                Recipe name: \(trimmedName)
                Dietary kind: \(dietaryKind.rawValue)
                Notes: \(notesBlock)
                Existing ingredients:
                \(existingBlock)
                """,
                generating: GenerableIngredientSuggestions.self
            )
            extracted = response.content
        } catch {
            throw RecipeIngredientSuggestionError.suggestionFailed(
                "Couldn't suggest ingredients. Try again or add them manually."
            )
        }

        // Empty is a valid outcome (nothing useful to add) — callers show a neutral status.
        return mapGenerable(
            extracted,
            excludingExistingNames: existingIngredients.map(\.name)
        )
    }
}
