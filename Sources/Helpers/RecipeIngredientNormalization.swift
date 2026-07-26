//
//  RecipeIngredientNormalization.swift
//  whattomake
//
//  Created by Cursor on 26/07/2026.
//

import Foundation

/// Normalized ingredient fields ready for the add-recipe form.
struct NormalizedIngredientFields: Equatable, Sendable {
    var name: String
    var amountText: String
    var unit: String
}

/// Cleans model output so amount is numeric-only, unit is separate, and name has no leading measure.
///
/// Handles common paste messes such as `300g/10½oz` in amount (prefer metric/left side)
/// and names that still start with `1kg/2lb 4oz …`.
func normalizeExtractedIngredient(
    name: String,
    amountText: String,
    unit: String
) -> NormalizedIngredientFields? {
    var cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !cleanedName.isEmpty else { return nil }

    let rawAmount = amountText.trimmingCharacters(in: .whitespacesAndNewlines)
    var cleanedAmount = primaryQuantitySegment(rawAmount)
    var cleanedUnit = unit.trimmingCharacters(in: .whitespacesAndNewlines)

    if cleanedAmount.contains(where: \.isLetter) {
        let split = splitLeadingAmountAndUnit(cleanedAmount)
        cleanedAmount = split.amount
        if cleanedUnit.isEmpty {
            cleanedUnit = split.unit
        }
    }

    cleanedUnit = canonicalizeIngredientUnit(cleanedUnit)
    cleanedName = stripLeadingMeasure(
        from: cleanedName,
        rawAmountText: rawAmount,
        normalizedAmount: cleanedAmount,
        unit: cleanedUnit
    )

    if !cleanedAmount.isEmpty, parseIngredientAmount(cleanedAmount) == nil {
        if cleanedUnit.isEmpty {
            cleanedUnit = canonicalizeIngredientUnit(cleanedAmount)
        }
        cleanedAmount = ""
    } else if let parsed = parseIngredientAmount(cleanedAmount) {
        cleanedAmount = formatIngredientAmount(parsed)
    }

    guard !cleanedName.isEmpty else { return nil }
    return NormalizedIngredientFields(
        name: cleanedName,
        amountText: cleanedAmount,
        unit: cleanedUnit
    )
}

/// When `/` separates two unit-bearing quantities, keep the left (usually metric).
func primaryQuantitySegment(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let slash = trimmed.firstIndex(of: "/") else { return trimmed }
    let left = String(trimmed[..<slash]).trimmingCharacters(in: .whitespacesAndNewlines)
    // Dual-unit forms include a unit on the left (`300g/…`, `1kg/…`).
    // Plain fractions (`1/2`) have no letters on the left — keep the full string.
    if left.contains(where: \.isLetter) {
        return left
    }
    return trimmed
}

/// Splits `300g`, `10½oz`, or `2 sprigs` into amount + unit.
func splitLeadingAmountAndUnit(_ text: String) -> (amount: String, unit: String) {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let unitStart = trimmed.firstIndex(where: \.isLetter) else {
        return (trimmed, "")
    }
    let amount = String(trimmed[..<unitStart]).trimmingCharacters(in: .whitespacesAndNewlines)
    let unit = String(trimmed[unitStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
    return (amount, unit)
}

/// Maps common spellings onto preset unit tokens when possible.
func canonicalizeIngredientUnit(_ unit: String) -> String {
    let trimmed = unit.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return "" }

    let lowered = trimmed.lowercased()
    let aliases: [String: String] = [
        "g": "g", "gram": "g", "grams": "g",
        "kg": "kg", "kilo": "kg", "kilos": "kg", "kilogram": "kg", "kilograms": "kg",
        "ml": "ml", "milliliter": "ml", "milliliters": "ml", "millilitre": "ml", "millilitres": "ml",
        "l": "l", "liter": "l", "liters": "l", "litre": "l", "litres": "l",
        "oz": "oz", "ounce": "oz", "ounces": "oz",
        "lb": "lb", "lbs": "lb", "pound": "lb", "pounds": "lb",
        "cup": "cup", "cups": "cup",
        "tbsp": "tbsp", "tablespoon": "tbsp", "tablespoons": "tbsp", "tbs": "tbsp",
        "tsp": "tsp", "teaspoon": "tsp", "teaspoons": "tsp",
        "clove": "clove(s)", "cloves": "clove(s)", "clove(s)": "clove(s)",
        "pinch": "pinch", "pinches": "pinch"
    ]
    if let mapped = aliases[lowered] {
        return mapped
    }
    return trimmed
}

/// Removes a duplicated leading measure from an ingredient name.
func stripLeadingMeasure(
    from name: String,
    rawAmountText: String,
    normalizedAmount: String,
    unit: String
) -> String {
    var result = name.trimmingCharacters(in: .whitespacesAndNewlines)

    let candidates: [String] = [
        rawAmountText,
        primaryQuantitySegment(rawAmountText),
        [normalizedAmount, unit].filter { !$0.isEmpty }.joined(separator: " "),
        [normalizedAmount, unit].filter { !$0.isEmpty }.joined(separator: ""),
        normalizedAmount
    ]
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { !$0.isEmpty }

    for candidate in candidates {
        guard result.lowercased().hasPrefix(candidate.lowercased()) else { continue }
        result = String(result.dropFirst(candidate.count))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        break
    }

    // Strip an extra leading measure token still glued on (`2lb 4oz ripe…` after
    // removing only `1kg` from `1kg/2lb 4oz ripe…`).
    result = stripLeadingMeasureTokens(from: result)
    return result
}

/// Drops leading `2lb`, `4oz`, `10½oz`-style tokens until the name starts with a word.
private func stripLeadingMeasureTokens(from name: String) -> String {
    var result = name.trimmingCharacters(in: .whitespacesAndNewlines)
    while true {
        let firstToken = String(result.split(separator: " ", maxSplits: 1).first ?? Substring())
        guard !firstToken.isEmpty else { return result }

        let primary = primaryQuantitySegment(firstToken)
        let split = splitLeadingAmountAndUnit(primary)
        let looksLikeMeasure = !split.amount.isEmpty
            && !split.unit.isEmpty
            && parseIngredientAmount(split.amount) != nil
            && split.unit.contains(where: \.isLetter)

        guard looksLikeMeasure else { return result }

        if result.lowercased().hasPrefix(firstToken.lowercased()) {
            result = String(result.dropFirst(firstToken.count))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if result.hasPrefix("/") {
                result = String(result.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            continue
        }
        return result
    }
}
