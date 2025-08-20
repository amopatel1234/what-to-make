//
//  RecipeDetailViewModelTests.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//

import Foundation
import Testing
@testable import ForkPlan

@MainActor
struct RecipeDetailViewModelTests {
    
    @Test
    func testInitializationWithRecipe() async throws {
        let recipe = Recipe(name: "Test Recipe", notes: "Test notes", usageCount: 5)
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        #expect(viewModel.recipe.name == "Test Recipe")
        #expect(viewModel.recipe.notes == "Test notes")
        #expect(viewModel.recipe.usageCount == 5)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isLoading == false)
    }
    
    @Test
    func testUsageCountTextSingular() async throws {
        let recipe = Recipe(name: "Test Recipe", usageCount: 1)
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        #expect(viewModel.usageCountText == "Used 1 time")
    }
    
    @Test
    func testUsageCountTextPlural() async throws {
        let recipe = Recipe(name: "Test Recipe", usageCount: 3)
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        #expect(viewModel.usageCountText == "Used 3 times")
    }
    
    @Test
    func testUsageCountTextZero() async throws {
        let recipe = Recipe(name: "Test Recipe", usageCount: 0)
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        #expect(viewModel.usageCountText == "Used 0 times")
    }
    
    @Test
    func testHasNotesWithValidNotes() async throws {
        let recipe = Recipe(name: "Test Recipe", notes: "Some meaningful notes")
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        #expect(viewModel.hasNotes == true)
        #expect(viewModel.notesText == "Some meaningful notes")
    }
    
    @Test
    func testHasNotesWithEmptyNotes() async throws {
        let recipe = Recipe(name: "Test Recipe", notes: "")
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        #expect(viewModel.hasNotes == false)
        #expect(viewModel.notesText == "")
    }
    
    @Test
    func testHasNotesWithWhitespaceOnlyNotes() async throws {
        let recipe = Recipe(name: "Test Recipe", notes: "   \n\t  ")
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        #expect(viewModel.hasNotes == false)
        #expect(viewModel.notesText == "")
    }
    
    @Test
    func testHasNotesWithNilNotes() async throws {
        let recipe = Recipe(name: "Test Recipe", notes: nil)
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        #expect(viewModel.hasNotes == false)
        #expect(viewModel.notesText == "")
    }
    
    @Test
    func testNotesTextTrimming() async throws {
        let recipe = Recipe(name: "Test Recipe", notes: "  Some notes with whitespace  \n")
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        #expect(viewModel.hasNotes == true)
        #expect(viewModel.notesText == "Some notes with whitespace")
    }
    
    @Test
    func testHasImageWithNoImage() async throws {
        let recipe = Recipe(name: "Test Recipe")
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        // Since we can't easily mock ImageStore and ImageCodec in unit tests,
        // this will return false for recipes with no image data
        #expect(viewModel.hasImage == false)
    }
    
    @Test
    func testHasImageWithThumbnailBase64() async throws {
        // Create a simple base64 string (not a valid image, but testing the logic)
        let recipe = Recipe(name: "Test Recipe", thumbnailBase64: "invalid_base64")
        let viewModel = RecipeDetailViewModel(recipe: recipe)
        
        // This will return false because the base64 is invalid and ImageCodec.image will return nil
        #expect(viewModel.hasImage == false)
    }
}