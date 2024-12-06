//
//  RecipeService.swift
//  whattomake
//
//  Created by Amish Patel on 19/10/2023.
//

import Foundation
import SwiftData

protocol RecipeServiceable {
    var sharedModelContainer: ModelContainer { get }
    var recipes: [Recipe] { get }
    var isStoredInMemory: Bool { get }
    func addRecipe(recipe: Recipe) async throws
    func clearRecipe(recipe: Recipe) async throws
    func fetchData() async throws 
}

class RecipeService: RecipeServiceable {
    
    private(set) var recipes: [Recipe] = []
    
    let isStoredInMemory: Bool
    
    lazy var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Recipe.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemory)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init(isStoredInMemory: Bool = false) {
        self.isStoredInMemory = isStoredInMemory
    }
    
    @MainActor
    func addRecipe(recipe: Recipe) async throws {
        sharedModelContainer.mainContext.insert(recipe)
        try await fetchData()
    }
    
    @MainActor
    func clearRecipe(recipe: Recipe) async throws {
        sharedModelContainer.mainContext.delete(recipe)
        try await fetchData()
    }
    
    @MainActor
    func fetchData() async throws {
        let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.name)])
        recipes = try sharedModelContainer.mainContext.fetch(descriptor)
    }
}
