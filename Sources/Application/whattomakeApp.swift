//
//  whattomakeApp.swift
//  whattomake
//
//  Created by Amish Patel on 18/10/2023.
//

import SwiftUI
import SwiftData

@main
struct whattomakeApp: App {
    
    var service: RecipeServiceable = RecipeService(isStoredInMemory: true)
    
    var body: some Scene {
        WindowGroup {
            RecipeListView(viewModel: RecipeListViewModel(recipeSerive: service))
        }
    }
}
