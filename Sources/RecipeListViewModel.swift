//
//  RecipeListViewModel.swift
//  whattomake
//
//  Created by Patel, Amish on 06/12/2024.
//

import Foundation

final class RecipeListViewModel: ObservableObject {
    
    let recipeSerive: RecipeServiceable
    @Published var recipes: [Recipe]
    
    init(recipeSerive: RecipeServiceable) {
        self.recipeSerive = recipeSerive
        self.recipes = recipeSerive.recipes
    }
    
    @MainActor
    func fetchData() async throws {
        try await recipeSerive.fetchData()
        recipes = recipeSerive.recipes
    }
}
