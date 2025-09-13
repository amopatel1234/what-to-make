//
//  WeeklyMenuApp.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//  Updated by ChatGPT on 17/08/2025.
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
    @State private var selectedTab: Int = 0
    let mode: StoreMode
    let container: ModelContainer

    @State private var didSeed = false

    var body: some View {
        let recipeRepo = SwiftDataRecipeRepository(context: container.mainContext)
        let menuRepo   = SwiftDataMenuRepository(context: container.mainContext)

        return TabView(selection: $selectedTab) {
            RecipesView(
                listVM: RecipesListViewModel(repository: recipeRepo),
                makeAddVM: { recipe in
                    AddRecipeViewModel(repository: recipeRepo, existingRecipe: recipe)
                }
            )
            .tabItem { Label("Recipes", systemImage: "book") }
            .tag(0)

            GenerateMenuView(viewModel: GenerateMenuViewModel(menuRepository: menuRepo,
                                                                recipeRepository: recipeRepo))
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
        for i in 1...8 {
            let r = Recipe(
                name: "Seeded \(i)",
                notes: i.isMultiple(of: 2) ? "Note \(i)" : nil
            )
            context.insert(r)
        }
        do { try context.save() } catch { }
    }
}
