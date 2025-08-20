//
//  RecipeDetailViewModel.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//

import Foundation
import Observation

/// ViewModel for RecipeDetailView that manages recipe detail state and interactions.
/// Currently focused on presenting recipe data, with potential for future features
/// like editing, sharing, or recipe actions.
@MainActor
@Observable
final class RecipeDetailViewModel {
    /// The recipe being displayed
    let recipe: Recipe
    
    /// Any error that occurred during operations
    var errorMessage: String?
    
    /// Whether the view is currently loading data
    var isLoading: Bool = false
    
    /// Creates a view model for displaying recipe details.
    /// - Parameter recipe: The recipe to display
    init(recipe: Recipe) {
        self.recipe = recipe
    }
    
    /// Gets the display text for usage count with proper pluralization.
    var usageCountText: String {
        let count = recipe.usageCount
        return count == 1 ? "Used 1 time" : "Used \(count) times"
    }
    
    /// Determines if the recipe has any notes to display.
    var hasNotes: Bool {
        guard let notes = recipe.notes else { return false }
        return !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Gets the formatted notes text for display.
    var notesText: String {
        recipe.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    /// Determines if the recipe has an image (either original or thumbnail).
    var hasImage: Bool {
        (recipe.imageFilename != nil && ImageStore.loadOriginal(named: recipe.imageFilename!) != nil) ||
        (recipe.thumbnailBase64 != nil && ImageCodec.image(fromBase64: recipe.thumbnailBase64!) != nil)
    }
}