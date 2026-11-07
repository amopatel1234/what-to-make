//
//  WebsiteRecipeParser.swift
//  ForkPlan
//

import Foundation

/// Pure Schema.org mapping. No networking, SwiftData or Foundation Models dependency.
enum WebsiteRecipeParser {
    /// Produces candidates in script/document order; malformed blocks do not hide valid blocks.
    static func parse(html: String, sourceURL: URL, resolvedURL: URL) throws -> WebsiteRecipeExtraction {
        guard html.utf8.count <= WebsiteHTMLFetcher.maximumBytes else { throw WebsiteRecipeError.responseTooLarge }
        var recipes: [WebsiteRecipeDraft] = []
        for block in WebsiteJSONLDScanner.blocks(in: html) {
            guard let data = block.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8),
                  let value = try? JSONSerialization.jsonObject(with: data) else { continue }
            collect(value, baseURL: resolvedURL, depth: 0, into: &recipes)
        }
        guard !recipes.isEmpty else { throw WebsiteRecipeError.noRecipeMetadata }
        return WebsiteRecipeExtraction(sourceURL: sourceURL, resolvedURL: resolvedURL, recipes: recipes)
    }

    private static func collect(_ value: Any, baseURL: URL, depth: Int, into recipes: inout [WebsiteRecipeDraft]) {
        guard depth < 64 else { return }
        if let values = value as? [Any] {
            for value in values { collect(value, baseURL: baseURL, depth: depth + 1, into: &recipes) }
        } else if let object = value as? [String: Any] {
            let types = strings(object["@type"])
            if types.contains(where: { schemaTerm($0) == "Recipe" }), let name = text(object["name"]) {
                let dietaryTerms = strings(object["suitableForDiet"]).map(schemaTerm)
                let diet: RecipeDietaryKind? = dietaryTerms.contains("VeganDiet") ? .vegan
                    : dietaryTerms.contains("VegetarianDiet") ? .vegetarian : nil
                let draft = WebsiteRecipeDraft(
                    name: name,
                    description: text(object["description"]),
                    ingredientLines: strings(object["recipeIngredient"]).compactMap { text($0) },
                    dietaryKind: diet,
                    imageURL: imageURL(object["image"], baseURL: baseURL)
                )
                if !recipes.contains(draft) { recipes.append(draft) }
            }
            // Dictionaries have no JSON ordering contract; stable traversal avoids flaky candidates.
            for key in object.keys.sorted() {
                if let nested = object[key] { collect(nested, baseURL: baseURL, depth: depth + 1, into: &recipes) }
            }
        }
    }

    private static func strings(_ value: Any?) -> [String] {
        if let value = value as? String { return [value] }
        return (value as? [Any])?.compactMap { $0 as? String } ?? []
    }

    private static func text(_ value: Any?) -> String? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func schemaTerm(_ value: String) -> String {
        if value.hasPrefix("https://schema.org/") { return String(value.dropFirst("https://schema.org/".count)) }
        if value.hasPrefix("http://schema.org/") { return String(value.dropFirst("http://schema.org/".count)) }
        return value
    }

    private static func imageURL(_ value: Any?, baseURL: URL) -> URL? {
        if let values = value as? [Any] {
            return values.lazy.compactMap { imageURL($0, baseURL: baseURL) }.first
        }
        if let object = value as? [String: Any] {
            return imageURL(object["contentUrl"] ?? object["url"] ?? object["@id"], baseURL: baseURL)
        }
        guard let string = text(value), let url = URL(string: string, relativeTo: baseURL)?.absoluteURL,
              (try? WebsiteURLPolicy.checkedURL(url)) != nil else { return nil }
        return url
    }
}
