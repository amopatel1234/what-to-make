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
///
/// Accepts plain decimals (`1.5`), ASCII fractions (`1/2`, `1 1/2`), and common
/// Unicode vulgar fractions (`½`, `1½`).
func parseIngredientAmount(_ text: String) -> Decimal? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return nil }

    // `Decimal(string:)` accepts a leading numeric prefix and ignores trailing
    // junk (`"1/2"` → `1`, `"1½"` → `1`), so fraction forms must be normalized first.
    if containsIngredientFractionMarker(trimmed) {
        let normalized = normalizeIngredientAmountText(trimmed)
        return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
    }

    if let direct = Decimal(string: trimmed, locale: Locale(identifier: "en_US_POSIX")) {
        return direct
    }
    let normalized = normalizeIngredientAmountText(trimmed)
    return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX"))
}

/// True when `text` includes an ASCII `/` fraction or a Unicode vulgar fraction glyph.
func containsIngredientFractionMarker(_ text: String) -> Bool {
    if text.contains("/") { return true }
    let vulgar: Set<Character> = [
        "¼", "½", "¾",
        "⅓", "⅔",
        "⅕", "⅖", "⅗", "⅘",
        "⅙", "⅚",
        "⅛", "⅜", "⅝", "⅞"
    ]
    return text.contains { vulgar.contains($0) }
}

/// Rewrites common fraction spellings into a decimal string suitable for ``Decimal``.
///
/// Returns the original trimmed text when no fraction pattern is recognized.
func normalizeIngredientAmountText(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return trimmed }

    let vulgar: [Character: String] = [
        "¼": "1/4", "½": "1/2", "¾": "3/4",
        "⅓": "1/3", "⅔": "2/3",
        "⅕": "1/5", "⅖": "2/5", "⅗": "3/5", "⅘": "4/5",
        "⅙": "1/6", "⅚": "5/6",
        "⅛": "1/8", "⅜": "3/8", "⅝": "5/8", "⅞": "7/8"
    ]

    var working = ""
    working.reserveCapacity(trimmed.count * 2)
    for character in trimmed {
        if let replacement = vulgar[character] {
            if !working.isEmpty, working.last?.isNumber == true {
                working.append(" ")
            }
            working.append(replacement)
        } else {
            working.append(character)
        }
    }

    let collapsed = working
        .split(whereSeparator: { $0.isWhitespace })
        .joined(separator: " ")

    if let mixed = parseMixedFraction(collapsed) {
        return mixed
    }
    if let simple = parseSimpleFraction(collapsed) {
        return simple
    }
    return collapsed
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

/// Parses `1 1/2` / `1/2` into a decimal string, or `nil` when not a fraction.
private func parseMixedFraction(_ text: String) -> String? {
    let parts = text.split(separator: " ", maxSplits: 1).map(String.init)
    guard parts.count == 2,
          let whole = Decimal(string: parts[0], locale: Locale(identifier: "en_US_POSIX")),
          let fraction = parseSimpleFractionDecimal(parts[1])
    else {
        return nil
    }
    return formatIngredientAmount(whole + fraction)
}

private func parseSimpleFraction(_ text: String) -> String? {
    guard let value = parseSimpleFractionDecimal(text) else { return nil }
    return formatIngredientAmount(value)
}

private func parseSimpleFractionDecimal(_ text: String) -> Decimal? {
    let pieces = text.split(separator: "/", maxSplits: 1).map(String.init)
    guard pieces.count == 2,
          let numerator = Decimal(string: pieces[0], locale: Locale(identifier: "en_US_POSIX")),
          let denominator = Decimal(string: pieces[1], locale: Locale(identifier: "en_US_POSIX")),
          denominator != 0
    else {
        return nil
    }
    return numerator / denominator
}
