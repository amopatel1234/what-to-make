//
//  RecipeTests.swift
//  whattomakeTests
//
//  Created by Amish Patel on 18/10/2023.
//

import XCTest
@testable import whattomake
import SwiftUI
import SwiftData

final class RecipeTests: XCTestCase {

    var sut: Recipe!
    override func setUpWithError() throws {
        sut = try createMockRecipe()
    }

    override func tearDownWithError() throws {
        sut = nil
    }
    
    func test_init_recipeHasValues() {
        XCTAssertNotNil(sut)
        XCTAssertEqual(sut.name, "Pasta")
        XCTAssertEqual(sut.timesUsed, 0)
        XCTAssertEqual(sut.servingSize, 4)
        XCTAssertEqual(sut.dateCreated, Date(timeIntervalSince1970: 200))
    }
    
}

extension RecipeTests {
    func createMockRecipe() throws -> Recipe {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
//        _ = try ModelContainer(for: Recipe.self, configurations: config)
        return Recipe(name: "Pasta",
               timesUsed: 0,
               servingSize: 4,
               dateCreated: Date(timeIntervalSince1970: 200))
        
    }
}
