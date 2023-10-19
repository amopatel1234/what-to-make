//
//  RecipeServiceTests.swift
//  whattomakeTests
//
//  Created by Amish Patel on 19/10/2023.
//

import XCTest
import SwiftData
@testable import whattomake

final class RecipeServiceTests: XCTestCase {

    var sut: RecipeService!
    
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Recipe.self, configurations: config)
        sut = RecipeService(config: config, container: container)
    }

    override func tearDownWithError() throws {
        sut = nil
    }
    
    func test_init_hasEmptyList() {
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.recipes.count, 0)
    }
    
    @MainActor 
    func test_addRecipe_increasesRecipeCount() throws {
        let recipe = createMockRecipeModel(name: "Testing")
        try sut.addRecipe(recipe: recipe)
        XCTAssertEqual(sut.recipes.count, 1)
    }
    
    @MainActor
    func test_clearRecipe_hasEmptyList() throws {
        let recipe = createMockRecipeModel(name: "Testing")
        try sut.addRecipe(recipe: recipe)
        XCTAssertEqual(sut.recipes.count, 1)
        try sut.clearRecipe(recipe: recipe)
        XCTAssertEqual(sut.recipes.count, 0)
    }
}

extension RecipeServiceTests {
    func createMockRecipeModel(name: String) -> Recipe {
        Recipe(name: name, timesUsed: 0, servingSize: 0, dateCreated: Date(timeIntervalSince1970: 200))
    }
}
