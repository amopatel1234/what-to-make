//
//  WeeklyMenuApp.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


import SwiftUI
import SwiftData

@main
struct WeeklyMenuApp: App {
    var body: some Scene {
        WindowGroup {
            let mode = StoreMode.current()
            if let container = StoreFactory.makeContainer(mode: mode) {
                RootTabsView(mode: mode, container: container)
                    .fpAppTheme()
                    .modelContainer(container)
            } else {
                Text("Failed to initialise data store.")
            }
        }
    }
}

private struct RootTabsView: View {
    
    @State private var selectedTab: Int = 0 // 0 = Recipes, 1 = Menu
    let mode: StoreMode
    let container: ModelContainer

    @State private var didSeed = false

    var body: some View {
        // Build repos & use cases from the provided container
        let recipeRepo   = SwiftDataRecipeRepository(context: container.mainContext)
        let menuRepo     = SwiftDataMenuRepository(context: container.mainContext)
        let fetchUseCase = FetchRecipesUseCase(repository: recipeRepo)
        let deleteUseCase = DeleteRecipeUseCase(repository: recipeRepo)
        let generateUseCase = GenerateMenuUseCase(recipeRepository: recipeRepo, menuRepository: menuRepo)
        let countUseCase = CountRecipesUseCase(repository: recipeRepo)

        return TabView(selection: $selectedTab) {
            RecipesView(
                listVM: RecipesListViewModel(fetchUseCase: fetchUseCase, deleteUseCase: deleteUseCase),
                makeAddVM: { recipe in
                    AddRecipeViewModel(addRecipeUseCase: AddRecipeUseCase(repository: recipeRepo), updateRecipeUseCase: UpdateRecipesUseCase(repository: recipeRepo), existingRecipe: recipe) }
            )
            .tabItem { Label("Recipes", systemImage: "book") }
            .tag(0)

            GenerateMenuView(viewModel: GenerateMenuViewModel(generateUseCase: generateUseCase,
                                                             countRecipesUseCase: countUseCase))
                .tabItem { Label("Menu", systemImage: "calendar") }
                .tag(1)
        }
        .task {
            guard !didSeed else { return }
            StoreFactory.seedIfNeeded(mode: mode, context: container.mainContext)
            didSeed = true
        }
    }
}

// MARK: - Test/Prod Store Configuration Helper
private enum StoreMode {
    case persistent
    case inMemoryBlank
    case inMemorySeeded

    static func current(from processInfo: ProcessInfo = .processInfo) -> StoreMode {
        let args = Set(processInfo.arguments)
        if args.contains("-ui-tests-seeded") { return .inMemorySeeded }
        if args.contains("-ui-tests-blank")  { return .inMemoryBlank }
        return .persistent
    }
}

private struct StoreFactory {
    static func makeContainer(mode: StoreMode) -> ModelContainer? {
        switch mode {
        case .persistent:
            return try? ModelContainer(for: Recipe.self, Menu.self)
        case .inMemoryBlank, .inMemorySeeded:
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try? ModelContainer(for: Recipe.self, Menu.self, configurations: config)
        }
    }

    static func seedIfNeeded(mode: StoreMode, context: ModelContext) {
        guard mode == .inMemorySeeded else { return }

            // Seed at least 8 recipes to satisfy the menu rule
            for i in 1...8 {
                let r = Recipe(
                    name: "Seeded \(i)",
                    notes: i.isMultiple(of: 2) ? "Note \(i)" : nil
                )
                context.insert(r)
            }

            do { try context.save() } catch { /* ignore seed errors in tests */ }
    }
}
