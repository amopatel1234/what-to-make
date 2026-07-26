//
//  RecipePasteExtractionTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import Testing

@Suite
struct RecipePasteExtractionTests {
    @Test
    func validationRejectsEmptyName() {
        let draft = RecipePasteDraft(
            name: "   ",
            notes: "Steps",
            dietaryKind: .standard,
            ingredients: [RecipePasteIngredientDraft(name: "Salt", amountText: "", unit: "")]
        )
        // mapGenerable trims before validation; simulate trimmed empty name.
        let trimmed = RecipePasteDraft(
            name: "",
            notes: draft.notes,
            dietaryKind: draft.dietaryKind,
            ingredients: draft.ingredients
        )
        #expect(RecipePasteExtractor.validationMessage(for: trimmed) == "Couldn't find a recipe name in that text.")
    }

    @Test
    func validationAcceptsNamedRecipe() {
        let draft = RecipePasteDraft(
            name: "Pasta",
            notes: "",
            dietaryKind: .vegetarian,
            ingredients: []
        )
        #expect(RecipePasteExtractor.validationMessage(for: draft) == nil)
    }

    @Test
    func mapGenerableTrimsAndDropsBlankIngredients() {
        let generable = GenerableRecipePaste(
            name: "  Soup  ",
            notes: "  Simmer  ",
            ingredients: [
                GenerableRecipeIngredient(name: "Carrots", amountText: "2", unit: "cup"),
                GenerableRecipeIngredient(name: "  ", amountText: "1", unit: "g"),
                GenerableRecipeIngredient(name: "Salt", amountText: "  ", unit: "  ")
            ],
            dietaryKind: .vegan
        )

        let draft = RecipePasteExtractor.mapGenerable(generable)
        #expect(draft.name == "Soup")
        #expect(draft.notes == "Simmer")
        #expect(draft.dietaryKind == .vegan)
        #expect(draft.ingredients.count == 2)
        #expect(draft.ingredients[0] == RecipePasteIngredientDraft(name: "Carrots", amountText: "2", unit: "cup"))
        #expect(draft.ingredients[1] == RecipePasteIngredientDraft(name: "Salt", amountText: "", unit: ""))
    }

    @Test
    func mapGenerableMapsVegetarianDiet() {
        let generable = GenerableRecipePaste(
            name: "Omelette",
            notes: "",
            ingredients: [],
            dietaryKind: .vegetarian
        )
        #expect(RecipePasteExtractor.mapGenerable(generable).dietaryKind == .vegetarian)
    }

    @Test
    func extractThrowsOnEmptyPasteWithoutCallingModel() async {
        do {
            _ = try await RecipePasteExtractor.extract(from: "   ")
            Issue.record("Expected emptyPaste error")
        } catch let error as RecipePasteError {
            #expect(error == .emptyPaste)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

@MainActor
@Suite
struct AddRecipePasteCoordinatorTests {
    @Test
    func applyPasteDraftFillsFormFields() {
        let coordinator = AddRecipeCoordinator()
        coordinator.applyPasteDraft(
            RecipePasteDraft(
                name: "Tacos",
                notes: "Tuesday",
                dietaryKind: .vegetarian,
                ingredients: [
                    RecipePasteIngredientDraft(name: "Tortillas", amountText: "8", unit: ""),
                    RecipePasteIngredientDraft(name: "Beans", amountText: "400", unit: "g"),
                    RecipePasteIngredientDraft(name: "Chipotle", amountText: "1", unit: "bunch")
                ]
            )
        )

        #expect(coordinator.name == "Tacos")
        #expect(coordinator.notes == "Tuesday")
        #expect(coordinator.dietaryKind == .vegetarian)
        #expect(coordinator.ingredientDrafts.count == 3)
        #expect(coordinator.ingredientDrafts[0].name == "Tortillas")
        #expect(coordinator.ingredientDrafts[0].amountText == "8")
        #expect(coordinator.ingredientDrafts[1].selectedUnit == "g")
        #expect(coordinator.ingredientDrafts[1].usesCustomUnit == false)
        #expect(coordinator.ingredientDrafts[2].usesCustomUnit == true)
        #expect(coordinator.ingredientDrafts[2].customUnit == "bunch")
        #expect(coordinator.errorMessage == nil)
    }
}
