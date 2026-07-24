//
//  IngredientFormatting.swift
//  whattomake
//
//  Created by Amish Patel on 20/06/2026.
//

import Foundation

/// Common unit suggestions for the add-recipe picker.
enum IngredientUnitOption: String, CaseIterable, Identifiable {
    case grams = "g"
    case kilograms = "kg"
    case milliliters = "ml"
    case liters = "l"
    case ounces = "oz"
    case pounds = "lb"
    case cups = "cup"
    case tablespoons = "tbsp"
    case teaspoons = "tsp"
    case cloves = "clove(s)"
    case pinch = "pinch"
    case custom = "Custom…"

    var id: String { rawValue }

    /// Units shown in the picker excluding the custom entry.
    static let presetUnits: [String] = allCases
        .filter { $0 != .custom }
        .map(\.rawValue)
}

/// Formats an ingredient line for display: amount, unit, and name as entered.
/// - Parameters:
///   - name: Ingredient name.
///   - amount: Optional numeric amount.
///   - unit: Optional unit label.
/// - Returns: A display string such as `400 g chicken breast` or `salt` when no amount is set.
func formattedIngredientLine(name: String, amount: Decimal?, unit: String?) -> String {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let amount else {
        return trimmedName
    }

    let amountString = formatIngredientAmount(amount)
    let trimmedUnit = unit?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if trimmedUnit.isEmpty {
        return "\(amountString) \(trimmedName)"
    }
    return "\(amountString) \(trimmedUnit) \(trimmedName)"
}

/// Parses a user-entered amount string into a decimal, or `nil` when empty or invalid.
func parseIngredientAmount(_ text: String) -> Decimal? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }
    return Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX"))
}

/// Formats a decimal amount for display, trimming insignificant trailing zeros.
func formatIngredientAmount(_ amount: Decimal) -> String {
    let number = amount as NSDecimalNumber
    let formatted = number.stringValue
    if formatted.contains(".") {
        var trimmed = formatted
        while trimmed.hasSuffix("0") {
            trimmed.removeLast()
        }
        if trimmed.hasSuffix(".") {
            trimmed.removeLast()
        }
        return trimmed
    }
    return formatted
}
