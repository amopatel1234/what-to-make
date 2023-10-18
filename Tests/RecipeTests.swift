//
//  RecipeTests.swift
//  whattomakeTests
//
//  Created by Amish Patel on 18/10/2023.
//

import XCTest
@testable import whattomake
import SwiftUI

final class RecipeTests: XCTestCase {

    var sut: Recipe!
    override func setUpWithError() throws {
        sut = createMockRecipe()
    }

    override func tearDownWithError() throws {
        sut = nil
    }
    
}

extension RecipeTests {
    func createMockRecipe() -> Recipe {
        Recipe(name: "Pasta",
               timesUsed: 0,
               servingSize: 4,
               dateCreated: Date(timeIntervalSince1970: 200),
               headerImage: Image(systemName: "eraser"))
    }
}
