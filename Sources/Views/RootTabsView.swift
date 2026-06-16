//
//  RootTabsView.swift
//  whattomake
//
//  Created by Amish Patel on 16/06/2026.
//

// Transitional: legacy use case wiring — delete with Epic 1 Story 1.4

import SwiftUI
import SwiftData

struct RootTabsView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    let storeMode: StoreMode
    @State private var didSeed = false

    var body: some View {
        let recipeRepo = SwiftDataRecipeRepository(context: modelContext)
        let menuRepo = SwiftDataMenuRepository(context: modelContext)
        let fetchUseCase = FetchRecipesUseCase(repository: recipeRepo)
        let deleteUseCase = DeleteRecipeUseCase(repository: recipeRepo)
        let generateUseCase = GenerateMenuUseCase(recipeRepository: recipeRepo, menuRepository: menuRepo)
        let countUseCase = CountRecipesUseCase(repository: recipeRepo)

        TabView(selection: $selectedTab) {
            RecipesView(
                listVM: RecipesListViewModel(fetchUseCase: fetchUseCase, deleteUseCase: deleteUseCase),
                makeAddVM: { recipe in
                    AddRecipeViewModel(
                        addRecipeUseCase: AddRecipeUseCase(repository: recipeRepo),
                        updateRecipeUseCase: UpdateRecipesUseCase(repository: recipeRepo),
                        existingRecipe: recipe
                    )
                }
            )
            .tabItem { Label("Recipes", systemImage: "book") }
            .tag(0)

            GenerateMenuView(
                viewModel: GenerateMenuViewModel(
                    generateUseCase: generateUseCase,
                    countRecipesUseCase: countUseCase
                )
            )
            .tabItem { Label("Menu", systemImage: "calendar") }
            .tag(1)
        }
        .task {
            guard !didSeed else { return }
            StoreFactory.seedIfNeeded(mode: storeMode, context: modelContext)
            didSeed = true
        }
    }
}
