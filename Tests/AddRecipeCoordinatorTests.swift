//
//  AddRecipeCoordinatorTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import SwiftData
import Testing

@MainActor
@Suite
struct AddRecipeCoordinatorTests {
    @Test
    func saveInsertsRecipeThatIsFetchableAfterSave() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let coordinator = AddRecipeCoordinator()
        coordinator.name = "  Shakshuka  "
        coordinator.notes = "Weekend brunch"
        coordinator.dietaryKind = .vegetarian
        coordinator.ingredientDrafts = [
            IngredientDraft(name: "eggs", amountText: "4", selectedUnit: ""),
            IngredientDraft(name: "tomatoes", amountText: "400", selectedUnit: "g")
        ]

        let didSave = coordinator.save(existingRecipe: nil, in: context)
        #expect(didSave)

        let fetched = try context.fetch(FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.name)]))
        #expect(fetched.count == 1)
        #expect(fetched[0].name == "Shakshuka")
        #expect(fetched[0].notes == "Weekend brunch")
        #expect(fetched[0].dietaryKind == .vegetarian)

        let ingredients = fetched[0].ingredients.sorted { $0.sortOrder < $1.sortOrder }
        #expect(ingredients.count == 2)
        #expect(ingredients[0].name == "eggs")
        #expect(ingredients[0].amount == 4)
        #expect(ingredients[1].name == "tomatoes")
        #expect(ingredients[1].unit == "g")
    }

    @Test
    func saveRequiresNameForNewRecipe() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let coordinator = AddRecipeCoordinator()
        coordinator.name = "   "

        let didSave = coordinator.save(existingRecipe: nil, in: context)
        #expect(!didSave)
        #expect(coordinator.errorMessage == "Recipe name is required.")
        #expect(try context.fetch(FetchDescriptor<Recipe>()).isEmpty)
    }

    @Test
    func saveRequiresIngredientNameWhenAmountProvided() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let coordinator = AddRecipeCoordinator()
        coordinator.name = "Soup"
        coordinator.ingredientDrafts = [
            IngredientDraft(name: "  ", amountText: "2", selectedUnit: "cups")
        ]

        let didSave = coordinator.save(existingRecipe: nil, in: context)
        #expect(!didSave)
        #expect(coordinator.errorMessage == "Each ingredient needs a name.")
        #expect(try context.fetch(FetchDescriptor<Recipe>()).isEmpty)
    }

    @Test
    func savePersistsDietaryKind() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let coordinator = AddRecipeCoordinator()
        coordinator.name = "Steak"
        coordinator.dietaryKind = .standard

        let didSave = coordinator.save(existingRecipe: nil, in: context)
        #expect(didSave)

        let fetched = try context.fetch(FetchDescriptor<Recipe>()).first
        #expect(fetched?.dietaryKind == .standard)
    }

    @Test
    func handleLoadedImageDataRejectsInvalidBytes() async {
        let coordinator = AddRecipeCoordinator()
        await coordinator.handleLoadedImageData(Data([0x00, 0x01, 0x02]))
        #expect(coordinator.errorMessage == "Could not load photo.")
        #expect(coordinator.previewImage == nil)
        #expect(coordinator.thumbnailBase64 == nil)
        #expect(coordinator.imageFilename == nil)
    }

    @Test
    func saveUpdatesExistingRecipeIngredients() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let existing = Recipe(name: "Pasta", notes: "Old", dietaryKind: .vegetarian)
        let oldIngredient = RecipeIngredient(name: "spaghetti", amount: 200, unit: "g", sortOrder: 0)
        oldIngredient.recipe = existing
        existing.ingredients = [oldIngredient]
        context.insert(existing)
        try context.save()

        let coordinator = AddRecipeCoordinator()
        coordinator.loadExistingRecipe(from: existing)
        coordinator.name = "Pasta Primavera"
        coordinator.notes = "Updated"
        coordinator.dietaryKind = .vegan
        coordinator.ingredientDrafts = [
            IngredientDraft(name: "penne", amountText: "300", selectedUnit: "g")
        ]

        let didSave = coordinator.save(existingRecipe: existing, in: context)
        #expect(didSave)

        let fetched = try context.fetch(FetchDescriptor<Recipe>()).first
        #expect(fetched?.name == "Pasta Primavera")
        #expect(fetched?.notes == "Updated")
        #expect(fetched?.dietaryKind == .vegan)
        let ingredients = fetched?.ingredients.sorted { $0.sortOrder < $1.sortOrder } ?? []
        #expect(ingredients.count == 1)
        #expect(ingredients[0].name == "penne")
        #expect(ingredients[0].amount == 300)
        #expect(try context.fetch(FetchDescriptor<RecipeIngredient>()).count == 1)
    }

    @Test
    func recipeNamesHasSchemaDefaultForMigration() {
        let schema = Schema([Recipe.self, Menu.self, RecipeIngredient.self])
        let menuEntity = schema.entities.first { $0.name == "Menu" }
        let recipeNamesAttribute = menuEntity?.attributes.first { $0.name == "recipeNames" }
        #expect(recipeNamesAttribute != nil)
        #expect(recipeNamesAttribute?.defaultValue != nil)
    }
}
