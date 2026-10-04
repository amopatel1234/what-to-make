//
//  RecipeListOrderingTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import SwiftData
import Testing

@MainActor
@Suite
struct RecipeListOrderingTests {
    @Test
    func moveRecipesByIndexSetUpdatesSortOrder() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let alpha = Recipe(name: "Alpha", sortOrder: 0)
        let beta = Recipe(name: "Beta", sortOrder: 1)
        let gamma = Recipe(name: "Gamma", sortOrder: 2)
        context.insert(alpha)
        context.insert(beta)
        context.insert(gamma)
        try context.save()

        RecipeListOrdering.moveRecipes(
            [alpha, beta, gamma],
            from: IndexSet(integer: 0),
            to: 3
        )
        try context.save()

        #expect(alpha.sortOrder == 2)
        #expect(beta.sortOrder == 0)
        #expect(gamma.sortOrder == 1)
    }

    @Test
    func moveRecipesByIdentityBeforeDestination() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let alpha = Recipe(name: "Alpha", sortOrder: 0)
        let beta = Recipe(name: "Beta", sortOrder: 1)
        let gamma = Recipe(name: "Gamma", sortOrder: 2)
        context.insert(alpha)
        context.insert(beta)
        context.insert(gamma)
        try context.save()

        RecipeListOrdering.moveRecipes(
            [alpha, beta, gamma],
            moving: [gamma.id],
            before: alpha.id
        )
        try context.save()

        #expect(gamma.sortOrder == 0)
        #expect(alpha.sortOrder == 1)
        #expect(beta.sortOrder == 2)
    }

    @Test
    func moveRecipesByIdentityToEnd() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let alpha = Recipe(name: "Alpha", sortOrder: 0)
        let beta = Recipe(name: "Beta", sortOrder: 1)
        context.insert(alpha)
        context.insert(beta)
        try context.save()

        RecipeListOrdering.moveRecipes(
            [alpha, beta],
            moving: [alpha.id],
            before: nil
        )
        try context.save()

        #expect(beta.sortOrder == 0)
        #expect(alpha.sortOrder == 1)
    }

    @Test
    func nextSortOrderAppendsAfterExisting() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        #expect(try RecipeListOrdering.nextSortOrder(in: context) == 0)

        context.insert(Recipe(name: "First", sortOrder: 0))
        context.insert(Recipe(name: "Second", sortOrder: 4))
        try context.save()

        #expect(try RecipeListOrdering.nextSortOrder(in: context) == 5)
    }

    @Test
    func reorderedLibrarySurvivesSimulatedRelaunch() throws {
        let storeURL = try makePersistentTestStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent()) }

        let alphaID: UUID
        let betaID: UUID
        let gammaID: UUID

        do {
            let container = try makePersistentTestContainer(storeURL: storeURL)
            let context = container.mainContext
            let alpha = Recipe(name: "Alpha", sortOrder: 0)
            let beta = Recipe(name: "Beta", sortOrder: 1)
            let gamma = Recipe(name: "Gamma", sortOrder: 2)
            alphaID = alpha.id
            betaID = beta.id
            gammaID = gamma.id
            context.insert(alpha)
            context.insert(beta)
            context.insert(gamma)
            try context.save()

            RecipeListOrdering.moveRecipes(
                [alpha, beta, gamma],
                moving: [gamma.id, alpha.id],
                before: beta.id
            )
            try context.save()
        }

        let relaunchContainer = try makePersistentTestContainer(storeURL: storeURL)
        let relaunchContext = relaunchContainer.mainContext
        let fetched = try relaunchContext.fetch(
            FetchDescriptor<Recipe>(sortBy: RecipeListOrdering.librarySortDescriptors)
        )

        #expect(fetched.map(\.id) == [gammaID, alphaID, betaID])
        #expect(fetched.map(\.sortOrder) == [0, 1, 2])
    }

    @Test
    func saveAssignsSortOrderForNewRecipe() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        context.insert(Recipe(name: "Existing", sortOrder: 2))
        try context.save()

        let coordinator = AddRecipeCoordinator()
        coordinator.name = "New Recipe"
        #expect(coordinator.save(existingRecipe: nil, in: context))

        let fetched = try context.fetch(
            FetchDescriptor<Recipe>(sortBy: RecipeListOrdering.librarySortDescriptors)
        )
        let created = fetched.first { $0.name == "New Recipe" }
        #expect(created?.sortOrder == 3)
    }
}
