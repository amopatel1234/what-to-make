//
//  RecipeServiceTests.swift
//  whattomakeTests
//
//  Created by Amish Patel on 19/10/2023.
//

import Testing
import SwiftData
@testable import whattomake
import Foundation

struct RecipeServiceTests {
    
    var sut: RecipeService
    
    init() async throws {
        self.sut = RecipeService(isStoredInMemory: true)
    }
    
    @Test func checkForEmptyRecipes() {
        #expect(sut.recipes.count == 0)
    }
    
    @Test func addRecipeAndCheckRecipeCount() async throws {
        #expect(sut.recipes.count == 0)
        let recipe = createMockRecipeModel(name: "Testing")
        try await sut.addRecipe(recipe: recipe)
        #expect(sut.recipes.count == 1)
        // adding same recipe does not increase count
        try await sut.addRecipe(recipe: recipe)
        #expect(sut.recipes.count == 1)
    }
    
    @Test func addRecipeThenDeleteAndCheckCount() async throws {
        #expect(sut.recipes.count == 0)
        let recipe = createMockRecipeModel(name: "Testing")
        try await sut.addRecipe(recipe: recipe)
        #expect(sut.recipes.count == 1)
        try await sut.clearRecipe(recipe: recipe)
        #expect(sut.recipes.count == 0)
    }
}

extension RecipeServiceTests {
    func createMockRecipeModel(name: String) -> Recipe {
        Recipe(name: name, timesUsed: 0, servingSize: 0, dateCreated: Date())
    }
}
