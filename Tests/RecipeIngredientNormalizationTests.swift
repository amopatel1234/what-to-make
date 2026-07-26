//
//  RecipeIngredientNormalizationTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import Testing

@Suite
struct RecipeIngredientNormalizationTests {
    @Test
    func splitsDualMetricImperialAmountAndCleansName() {
        let normalized = normalizeExtractedIngredient(
            name: "300g/10½oz dried pasta",
            amountText: "300g/10½oz",
            unit: ""
        )
        #expect(normalized == NormalizedIngredientFields(name: "dried pasta", amountText: "300", unit: "g"))
    }

    @Test
    func prefersLeftMetricFromKilogramDualAmount() {
        let normalized = normalizeExtractedIngredient(
            name: "1kg/2lb 4oz ripe cherry tomatoes",
            amountText: "1kg/2lb 4oz",
            unit: ""
        )
        #expect(normalized?.amountText == "1")
        #expect(normalized?.unit == "kg")
        #expect(normalized?.name == "ripe cherry tomatoes")
    }

    @Test
    func splitsAttachedUnitFromAmount() {
        let normalized = normalizeExtractedIngredient(
            name: "mascarpone",
            amountText: "125g",
            unit: ""
        )
        #expect(normalized == NormalizedIngredientFields(name: "mascarpone", amountText: "125", unit: "g"))
    }

    @Test
    func stripsLeadingNumericDuplicateFromName() {
        let normalized = normalizeExtractedIngredient(
            name: "2 sprigs fresh rosemary",
            amountText: "2",
            unit: ""
        )
        #expect(normalized?.name == "sprigs fresh rosemary")
        #expect(normalized?.amountText == "2")
    }

    @Test
    func keepsPlainFractionAmounts() {
        let normalized = normalizeExtractedIngredient(
            name: "sugar",
            amountText: "1/2",
            unit: "cup"
        )
        #expect(normalized == NormalizedIngredientFields(name: "sugar", amountText: "0.5", unit: "cup"))
    }

    @Test
    func mapGenerableNormalizesMessyModelOutput() {
        let draft = RecipePasteExtractor.mapGenerable(
            GenerableRecipePaste(
                name: "Pasta",
                notes: "",
                ingredients: [
                    GenerableRecipeIngredient(
                        name: "50g/1¾oz Parmesan",
                        amountText: "50g/1¾oz",
                        unit: ""
                    )
                ],
                dietaryKind: .vegetarian
            )
        )
        #expect(draft.ingredients == [
            RecipePasteIngredientDraft(name: "Parmesan", amountText: "50", unit: "g")
        ])
    }
}
