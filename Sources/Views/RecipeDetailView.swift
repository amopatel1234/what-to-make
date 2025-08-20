//
//  RecipeDetailView.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import SwiftUI

struct RecipeDetailView: View {
    @State private var viewModel: RecipeDetailViewModel
    
    init(recipe: Recipe) {
        _viewModel = State(initialValue: RecipeDetailViewModel(recipe: recipe))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: Recipe Image
                if let imageFilename = viewModel.recipe.imageFilename,
                   let originalImage = ImageStore.loadOriginal(named: imageFilename) {
                    // Show full-size original image
                    Image(uiImage: originalImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityIdentifier("recipeDetailImage")
                } else if let thumbnailBase64 = viewModel.recipe.thumbnailBase64,
                          let thumbnailImage = ImageCodec.image(fromBase64: thumbnailBase64) {
                    // Fallback to thumbnail if original not available
                    Image(uiImage: thumbnailImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityIdentifier("recipeDetailThumbnail")
                } else {
                    // Placeholder if no image
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.fpSurface)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.fpSecondaryLabel)
                                Text("No Image")
                                    .font(FpTypography.caption)
                                    .foregroundStyle(Color.fpSecondaryLabel)
                            }
                        )
                        .accessibilityIdentifier("recipeDetailNoImage")
                }
                
                // MARK: Recipe Details
                VStack(alignment: .leading, spacing: 16) {
                    // Notes section
                    if viewModel.hasNotes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(FpTypography.heading3)
                                .foregroundStyle(Color.fpLabel)
                                .accessibilityIdentifier("recipeDetailNotesLabel")
                            
                            Text(viewModel.notesText)
                                .font(FpTypography.body)
                                .foregroundStyle(Color.fpLabel)
                                .accessibilityIdentifier("recipeDetailNotesText")
                        }
                    }
                    
                    // Usage count section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Usage Count")
                            .font(FpTypography.heading3)
                            .foregroundStyle(Color.fpLabel)
                            .accessibilityIdentifier("recipeDetailUsageLabel")
                        
                        Text(viewModel.usageCountText)
                            .font(FpTypography.body)
                            .foregroundStyle(Color.fpSecondaryLabel)
                            .accessibilityIdentifier("recipeDetailUsageCount")
                    }
                }
                .padding(.horizontal, FpLayout.screenPadding)
                
                Spacer(minLength: 20)
            }
            .padding(.top, FpLayout.screenPadding)
        }
        .navigationTitle(viewModel.recipe.name)
        .navigationBarTitleDisplayMode(.large)
        .background(Color.fpBackground)
        .accessibilityIdentifier("recipeDetailView")
    }
}

#if DEBUG
#Preview("Recipe with Image") {
    let recipe = Recipe(
        name: "Pasta Carbonara",
        notes: "Classic Italian dish with eggs, cheese, pancetta, and pepper. Family favorite for Sunday dinners.",
        usageCount: 3,
        thumbnailBase64: nil
    )
    
    NavigationStack {
        RecipeDetailView(recipe: recipe)
    }
}

#Preview("Recipe without Image") {
    let recipe = Recipe(
        name: "Quick Tacos",
        notes: "Simple Tuesday night meal with ground beef, lettuce, tomatoes, and cheese.",
        usageCount: 7
    )
    
    NavigationStack {
        RecipeDetailView(recipe: recipe)
    }
}

#Preview("Recipe Minimal") {
    let recipe = Recipe(
        name: "Simple Soup",
        usageCount: 1
    )
    
    NavigationStack {
        RecipeDetailView(recipe: recipe)
    }
}
#endif