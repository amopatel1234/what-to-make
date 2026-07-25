//
//  Recipe.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


import Foundation
import SwiftData

/// A SwiftData model representing a single saved recipe.
///
/// Fields
/// - ``name``: Required display name.
/// - ``notes``: Optional free-form notes.
/// - ``usageCount``: Incremented when included in a generated menu.
/// - ``thumbnailBase64``: Optional Base64 JPEG thumbnail for fast list rendering.
/// - ``imageFilename``: Optional filename of the original image on disk (via ``ImageStore``).
/// - ``dietaryKindRaw``: Stored raw value for ``RecipeDietaryKind``.
/// - ``ingredients``: Ordered ingredient lines for the recipe.
///
/// Example
/// ```swift
/// let recipe = Recipe(name: "Pasta", notes: "Family favorite")
/// ```
@Model
final class Recipe {
    /// Stable unique identifier for the recipe.
    @Attribute(.unique) var id: UUID
    /// Required name of the recipe.
    var name: String
    /// Optional notes shown on detail/list.
    var notes: String?
    /// Number of times this recipe has been used in generated menus.
    var usageCount: Int

    // NEW: tiny, sync-friendly image data
    /// Base64-encoded JPEG thumbnail (~300–600 px) used for lightweight previews.
    var thumbnailBase64: String?     // ~300–600 px JPEG as Base64

    // NEW: local original file name in app container (not synced)
    /// Filename for the original full-resolution image stored in ``ImageStore``.
    var imageFilename: String?       // e.g., "img_9F3C2A.jpg"

    /// Stored raw value for ``dietaryKind`` (`standard`, `vegetarian`, or `vegan`).
    ///
    /// The inline default is required: SwiftData lightweight migration rejects a new
    /// mandatory attribute without one, which fails to load pre-existing stores.
    var dietaryKindRaw: String = RecipeDietaryKind.standard.rawValue

    /// Ingredient lines belonging to this recipe.
    @Relationship(deleteRule: .cascade, inverse: \RecipeIngredient.recipe)
    var ingredients: [RecipeIngredient] = []

    /// Typed dietary classification for menu filtering.
    var dietaryKind: RecipeDietaryKind {
        get { RecipeDietaryKind(rawValue: dietaryKindRaw) ?? .standard }
        set { dietaryKindRaw = newValue.rawValue }
    }

    /// Creates a recipe model.
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if omitted).
    ///   - name: Required recipe name.
    ///   - notes: Optional notes.
    ///   - usageCount: Initial usage count (defaults to 0).
    ///   - thumbnailBase64: Optional Base64 thumbnail.
    ///   - imageFilename: Optional original image filename in ``ImageStore``.
    ///   - dietaryKind: Dietary classification (defaults to ``RecipeDietaryKind/standard``).
    ///   - ingredients: Initial ingredient lines (defaults to empty).
    init(id: UUID = UUID(), name: String, notes: String? = nil,
         usageCount: Int = 0, thumbnailBase64: String? = nil, imageFilename: String? = nil,
         dietaryKind: RecipeDietaryKind = .standard, ingredients: [RecipeIngredient] = []) {
        self.id = id
        self.name = name
        self.notes = notes
        self.usageCount = usageCount
        self.thumbnailBase64 = thumbnailBase64
        self.imageFilename = imageFilename
        self.dietaryKindRaw = dietaryKind.rawValue
        self.ingredients = ingredients
    }
}
