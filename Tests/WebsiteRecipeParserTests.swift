@testable import ForkPlan
import Foundation
import Testing

private final class WebsiteFixtureBundleToken: NSObject {}

enum WebsiteTestFixtures {
    static func html(_ name: String) throws -> String {
        let bundle = Bundle(for: WebsiteFixtureBundleToken.self)
        let url = try #require(bundle.url(forResource: name, withExtension: "html", subdirectory: "WebsiteRecipes"))
        return try String(contentsOf: url, encoding: .utf8)
    }
}

@Suite
struct WebsiteRecipeParserTests {
    private func parse(_ html: String) throws -> WebsiteRecipeExtraction {
        let source = try #require(URL(string: "https://recipes.example.com/original"))
        let resolved = try #require(URL(string: "https://recipes.example.com/final/page"))
        return try WebsiteRecipeParser.parse(html: html, sourceURL: source, resolvedURL: resolved)
    }

    @Test func mapsSupportedMetadataWithoutInstructionsOrGuessedDiet() throws {
        let result = try parse(WebsiteTestFixtures.html("single-recipe"))
        let recipe = try #require(result.recipes.first)
        #expect(recipe.name == "Chickpea stew")
        #expect(recipe.description == "A family favourite.")
        #expect(recipe.ingredientLines == ["1½ cups cooked chickpeas", "salt, to taste"])
        #expect(recipe.dietaryKind == .vegan)
        #expect(recipe.imageURL?.absoluteString == "https://recipes.example.com/photos/stew.jpg")
        #expect(result.sourceURL.path == "/original")
        #expect(result.resolvedURL.path == "/final/page")
    }

    @Test func handlesGraphsArraysNestedRecipesAndMalformedSiblingScripts() throws {
        let result = try parse(WebsiteTestFixtures.html("graph-recipes"))
        #expect(result.recipes.map(\.name) == ["First", "Second"])
        #expect(result.recipes[0].dietaryKind == nil)
        #expect(result.recipes[1].dietaryKind == .vegetarian)
    }

    @Test func scannerIgnoresMisleadingMarkupAndPreservesRawJSON() throws {
        let html = try WebsiteTestFixtures.html("scanner-traps")
        #expect(WebsiteJSONLDScanner.blocks(in: html).count == 1)
        let result = try parse(html)
        #expect(result.recipes.map(\.name) == ["Soup"])
        #expect(result.recipes[0].description == "Keep &amp; and </scripture> as raw JSON text")
    }

    @Test(arguments: [
        "<html><h1>Recipe without JSON-LD</h1></html>",
        "<script type='application/ld+json'>{bad}</script>",
        "<script type='application/ld+json'>{\"@type\":\"Article\",\"name\":\"Not a recipe\"}</script>",
        "<script type='application/ld+json'>{\"@type\":\"Recipe\",\"name\":\"  \"}</script>"
    ])
    func rejectsMissingOrUnusableMetadata(_ html: String) throws {
        #expect(throws: WebsiteRecipeError.noRecipeMetadata) { try parse(html) }
    }

    @Test func doesNotScanInsideAnUnterminatedQuotedAttribute() {
        let html = "<div title=\"<script type='application/ld+json'>{}</script>"
        #expect(WebsiteJSONLDScanner.blocks(in: html).isEmpty)
    }

    @Test func rejectsAnUnterminatedScript() {
        #expect(WebsiteJSONLDScanner.blocks(in: "<script type='application/ld+json'>{}").isEmpty)
    }

    @Test func acceptsMixedOptionalFieldsWithoutDiscardingUsableStrings() throws {
        let html = #"<script type='application/ld+json'>{"@type":[42,"Recipe"],"name":"Toast","recipeIngredient":["bread",9,"butter"," "],"image":["http://127.0.0.1/private","/toast.jpg"],"suitableForDiet":"GlutenFreeDiet"}</script>"#
        let result = try parse(html)
        #expect(result.recipes[0].ingredientLines == ["bread", "butter"])
        #expect(result.recipes[0].dietaryKind == nil)
        #expect(result.recipes[0].imageURL?.path == "/toast.jpg")
    }

    @Test func preservesUnicodeAndJSONEscapes() throws {
        let html = #"<script type='application/ld+json'>{"@type":"Recipe","name":"Cr\u00e8me br\u00fbl\u00e9e","recipeIngredient":["½ tsp vanilla"]}</script>"#
        let result = try parse(html)
        #expect(result.recipes[0].name == "Crème brûlée")
        #expect(result.recipes[0].ingredientLines == ["½ tsp vanilla"])
    }

    @Test func boundsDirectParserInput() {
        #expect(throws: WebsiteRecipeError.responseTooLarge) {
            try parse(String(repeating: "x", count: WebsiteHTMLFetcher.maximumBytes + 1))
        }
    }
}
