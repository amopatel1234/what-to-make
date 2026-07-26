//
//  IngredientFormattingTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import Testing

struct IngredientFormattingTests {
    @Test
    func formatsAmountUnitAndName() {
        let line = formattedIngredientLine(name: "chicken breast", amount: 400, unit: "g")
        #expect(line == "400 g chicken breast")
    }

    @Test
    func formatsAmountWithoutUnit() {
        let line = formattedIngredientLine(name: "eggs", amount: 2, unit: nil)
        #expect(line == "2 eggs")
    }

    @Test
    func formatsNameOnlyWhenNoAmount() {
        let line = formattedIngredientLine(name: "salt", amount: nil, unit: "pinch")
        #expect(line == "salt")
    }

    @Test
    func trimsWhitespaceFromNameAndUnit() {
        let line = formattedIngredientLine(name: "  olive oil  ", amount: 1, unit: "  tbsp  ")
        #expect(line == "1 tbsp olive oil")
    }

    @Test
    func preservesMixedUnitsAsEntered() {
        let metric = formattedIngredientLine(name: "flour", amount: 200, unit: "g")
        let imperial = formattedIngredientLine(name: "milk", amount: 1, unit: "pint")
        #expect(metric == "200 g flour")
        #expect(imperial == "1 pint milk")
    }

    @Test
    func trimsTrailingZerosFromDecimalAmount() {
        let line = formattedIngredientLine(name: "butter", amount: Decimal(string: "1.50"), unit: "cup")
        #expect(line == "1.5 cup butter")
    }

    @Test
    func parseIngredientAmountAcceptsValidDecimal() {
        #expect(parseIngredientAmount("400") == 400)
        #expect(parseIngredientAmount("1.5") == Decimal(string: "1.5"))
    }

    @Test
    func parseIngredientAmountAcceptsAsciiFractions() {
        #expect(parseIngredientAmount("1/2") == Decimal(string: "0.5"))
        #expect(parseIngredientAmount("1 1/2") == Decimal(string: "1.5"))
        #expect(parseIngredientAmount("3/4") == Decimal(string: "0.75"))
    }

    @Test
    func parseIngredientAmountAcceptsUnicodeVulgarFractions() {
        #expect(parseIngredientAmount("½") == Decimal(string: "0.5"))
        #expect(parseIngredientAmount("1½") == Decimal(string: "1.5"))
        #expect(parseIngredientAmount("¼") == Decimal(string: "0.25"))
    }

    @Test
    func parseIngredientAmountReturnsNilForEmptyOrInvalid() {
        #expect(parseIngredientAmount("") == nil)
        #expect(parseIngredientAmount("   ") == nil)
        #expect(parseIngredientAmount("abc") == nil)
        #expect(parseIngredientAmount("to taste") == nil)
    }
}
