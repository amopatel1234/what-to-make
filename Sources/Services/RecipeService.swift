//
//  RecipeService.swift
//  whattomake
//
//  Created by Amish Patel on 19/10/2023.
//

import Foundation
import SwiftData

protocol RecipeServiceable {
    var config: ModelConfiguration { get }
    var container: ModelContainer { get }
    func addRecipe(recipe: Recipe) throws
    func clearRecipe(recipe: Recipe) throws
}

class RecipeService: RecipeServiceable {
    let config: ModelConfiguration
    let container: ModelContainer
    
    private(set) var recipes: [Recipe] = [Recipe]()
    
    init(config: ModelConfiguration, container: ModelContainer) {
        self.config = config
        self.container = container
    }
    
    @MainActor
    func addRecipe(recipe: Recipe) throws {
        container.mainContext.insert(recipe)
        try fetchData()
    }
    
    @MainActor
    func clearRecipe(recipe: Recipe) throws {
        container.mainContext.delete(recipe)
        try fetchData()
    }
    
    @MainActor
    private func fetchData() throws {
        let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.name)])
        recipes = try container.mainContext.fetch(descriptor)
    }
}
