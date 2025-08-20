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
///
/// Example
/// ```swift
/// let recipe = Recipe(name: "Pasta", notes: "Family favorite")
/// ```
@Model
final class Recipe: Hashable {
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

    /// Creates a recipe model.
    /// - Parameters:
    ///   - id: Unique identifier (auto-generated if omitted).
    ///   - name: Required recipe name.
    ///   - notes: Optional notes.
    ///   - usageCount: Initial usage count (defaults to 0).
    ///   - thumbnailBase64: Optional Base64 thumbnail.
    ///   - imageFilename: Optional original image filename in ``ImageStore``.
    init(id: UUID = UUID(), name: String, notes: String? = nil,
         usageCount: Int = 0, thumbnailBase64: String? = nil, imageFilename: String? = nil) {
        self.id = id
        self.name = name
        self.notes = notes
        self.usageCount = usageCount
        self.thumbnailBase64 = thumbnailBase64
        self.imageFilename = imageFilename
    }
    
    // MARK: - Hashable Conformance
    static func == (lhs: Recipe, rhs: Recipe) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
