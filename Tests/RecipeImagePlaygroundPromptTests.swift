//
//  RecipeImagePlaygroundPromptTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import Testing

@Suite
struct RecipeImagePlaygroundPromptTests {
    @Test
    func canGenerateRequiresRecipeName() {
        let empty = RecipeImageGenerationRequest(
            recipeName: "  ",
            ingredientNames: ["Salt"],
            notes: "",
            dietaryKind: .standard
        )
        let named = RecipeImageGenerationRequest(
            recipeName: "Pasta",
            ingredientNames: [],
            notes: "",
            dietaryKind: .standard
        )
        #expect(RecipeImagePlaygroundPrompt.canGenerate(from: empty) == false)
        #expect(RecipeImagePlaygroundPrompt.canGenerate(from: named) == true)
    }

    @Test
    func primaryConceptIncludesRecipeName() {
        let request = RecipeImageGenerationRequest(
            recipeName: "Tomato Pasta",
            ingredientNames: ["tomatoes", "pasta"],
            notes: "",
            dietaryKind: .vegetarian
        )
        let primary = RecipeImagePlaygroundPrompt.primaryConcept(for: request)
        #expect(primary.contains("Tomato Pasta"))
    }

    @Test
    func supportingConceptsIncludeIngredientsAndDiet() {
        let request = RecipeImageGenerationRequest(
            recipeName: "Bowl",
            ingredientNames: ["tofu", "rice", "spinach"],
            notes: "Short",
            dietaryKind: .vegan
        )
        let supporting = RecipeImagePlaygroundPrompt.supportingConcepts(for: request)
        #expect(supporting.contains(where: { $0.contains("tofu") && $0.contains("rice") }))
        #expect(supporting.contains("vegan plant-based dish"))
        #expect(!supporting.contains("Short"))
    }

    @Test
    func notesExtractionRequiresLongerText() {
        let short = RecipeImageGenerationRequest(
            recipeName: "Soup",
            ingredientNames: [],
            notes: "Simmer gently.",
            dietaryKind: .standard
        )
        let longNotes = String(repeating: "Roast until golden and fragrant. ", count: 3)
        let long = RecipeImageGenerationRequest(
            recipeName: "Soup",
            ingredientNames: [],
            notes: longNotes,
            dietaryKind: .standard
        )
        #expect(RecipeImagePlaygroundPrompt.notesExtractionSource(for: short) == nil)
        let extracted = RecipeImagePlaygroundPrompt.notesExtractionSource(for: long)
        #expect(extracted == longNotes.trimmingCharacters(in: .whitespacesAndNewlines))
        #expect((extracted?.count ?? 0) >= 40)
    }

    @Test
    func conceptTextsPutsPrimaryFirst() {
        let request = RecipeImageGenerationRequest(
            recipeName: "Tacos",
            ingredientNames: ["tortillas"],
            notes: "",
            dietaryKind: .standard
        )
        let texts = RecipeImagePlaygroundPrompt.conceptTexts(for: request)
        #expect(texts.first == RecipeImagePlaygroundPrompt.primaryConcept(for: request))
        #expect(texts.count >= 2)
    }
}
