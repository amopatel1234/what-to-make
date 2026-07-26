//
//  RecipePasteExtraction.swift
//  whattomake
//
//  Created by Cursor on 26/07/2026.
//

import Foundation
import FoundationModels

// MARK: - Guided generation schema (Foundation Models)

@Generable(description: "One recipe extracted from pasted free-form text")
struct GenerableRecipePaste {
    @Guide(description: "Short recipe title")
    var name: String

    @Guide(description: "Cooking notes or instructions; empty string if none")
    var notes: String

    @Guide(description: "Ingredient lines in recipe order")
    var ingredients: [GenerableRecipeIngredient]

    @Guide(description: "Dietary classification of the recipe")
    var dietaryKind: GenerableDietaryKind

    /// Explicit memberwise init — `@Generable` may not preserve a usable one for tests.
    init(
        name: String,
        notes: String,
        ingredients: [GenerableRecipeIngredient],
        dietaryKind: GenerableDietaryKind
    ) {
        self.name = name
        self.notes = notes
        self.ingredients = ingredients
        self.dietaryKind = dietaryKind
    }
}

@Generable(description: "A single ingredient line")
struct GenerableRecipeIngredient {
    @Guide(description: "Ingredient food name only — no quantities or units")
    var name: String

    @Guide(description: "Numeric amount only such as 300 or 1.5 — never letters or units")
    var amountText: String

    @Guide(description: "Single unit such as g, kg, oz, cup, or tbsp; empty if none. Prefer metric when both metric and imperial appear")
    var unit: String

    /// Explicit memberwise init — `@Generable` may not preserve a usable one for tests.
    init(name: String, amountText: String, unit: String) {
        self.name = name
        self.amountText = amountText
        self.unit = unit
    }
}

@Generable(description: "Dietary classification")
enum GenerableDietaryKind {
    case standard
    case vegetarian
    case vegan
}

// MARK: - App-facing draft

/// Structured recipe draft produced by paste extraction (before SwiftData save).
struct RecipePasteDraft: Equatable, Sendable {
    var name: String
    var notes: String
    var dietaryKind: RecipeDietaryKind
    var ingredients: [RecipePasteIngredientDraft]
}

/// One ingredient line in a ``RecipePasteDraft``.
struct RecipePasteIngredientDraft: Equatable, Sendable {
    var name: String
    var amountText: String
    var unit: String
}

// MARK: - Errors

/// User-visible failures from paste → recipe extraction.
enum RecipePasteError: Error, Equatable, LocalizedError {
    case emptyPaste
    case modelUnavailable(String)
    case extractionFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyPaste:
            return "Paste a recipe first."
        case .modelUnavailable(let message):
            return message
        case .extractionFailed(let message):
            return message
        }
    }
}

// MARK: - Extractor

/// On-device Foundation Models extraction of a recipe from pasted text.
enum RecipePasteExtractor {
    /// Whether the system language model can run on this device right now.
    static var isModelAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    /// Explains why paste extraction is disabled, or `nil` when available.
    static var unavailableReasonMessage: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            return unavailableMessage(for: reason)
        }
    }

    /// Maps guided-generation output into an app draft (pure; unit-testable).
    static func mapGenerable(_ value: GenerableRecipePaste) -> RecipePasteDraft {
        let dietaryKind: RecipeDietaryKind
        switch value.dietaryKind {
        case .standard: dietaryKind = .standard
        case .vegetarian: dietaryKind = .vegetarian
        case .vegan: dietaryKind = .vegan
        }
        let ingredients = value.ingredients.compactMap { ingredient -> RecipePasteIngredientDraft? in
            guard let normalized = normalizeExtractedIngredient(
                name: ingredient.name,
                amountText: ingredient.amountText,
                unit: ingredient.unit
            ) else {
                return nil
            }
            return RecipePasteIngredientDraft(
                name: normalized.name,
                amountText: normalized.amountText,
                unit: normalized.unit
            )
        }
        return RecipePasteDraft(
            name: value.name.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: value.notes.trimmingCharacters(in: .whitespacesAndNewlines),
            dietaryKind: dietaryKind,
            ingredients: ingredients
        )
    }

    /// Returns a validation message when the draft is not usable, otherwise `nil`.
    static func validationMessage(for draft: RecipePasteDraft) -> String? {
        if draft.name.isEmpty {
            return "Couldn't find a recipe name in that text."
        }
        return nil
    }

    /// Runs on-device extraction. Throws ``RecipePasteError`` for user-facing failures.
    static func extract(from pastedText: String) async throws -> RecipePasteDraft {
        let trimmed = pastedText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw RecipePasteError.emptyPaste
        }
        if let unavailable = unavailableReasonMessage {
            throw RecipePasteError.modelUnavailable(unavailable)
        }

        let session = LanguageModelSession {
            """
            Extract exactly one recipe from the pasted text.
            Prefer a clear title and an ordered ingredient list.
            Put instructions into notes when present.
            Use dietaryKind vegan only when clearly plant-only, vegetarian when no meat,
            otherwise standard.
            For each ingredient: name must be food only (no quantities);
            amountText must be digits/fractions only (no unit letters);
            unit must be a single unit such as g or oz. When the source has both
            metric and imperial (300g/10oz), prefer the metric amount and unit.
            Use empty strings for unknown amountText or unit.
            """
        }

        let extracted: GenerableRecipePaste
        do {
            let response = try await session.respond(
                to: """
                Pasted recipe text:
                \(trimmed)
                """,
                generating: GenerableRecipePaste.self
            )
            extracted = response.content
        } catch {
            throw RecipePasteError.extractionFailed(
                "Couldn't extract a recipe. Try editing the text or enter it manually."
            )
        }

        let draft = mapGenerable(extracted)
        if let message = validationMessage(for: draft) {
            throw RecipePasteError.extractionFailed(message)
        }
        return draft
    }

    private static func unavailableMessage(
        for reason: SystemLanguageModel.Availability.UnavailableReason
    ) -> String {
        switch reason {
        case .deviceNotEligible:
            return "Paste extraction needs a device that supports Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "Turn on Apple Intelligence in Settings to paste recipes."
        case .modelNotReady:
            return "Apple Intelligence is still downloading. Try again in a moment."
        @unknown default:
            return "Paste extraction isn't available on this device right now."
        }
    }
}
