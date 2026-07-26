//
//  RecipeIngredientSuggestionTests.swift
//  whattomake
//

@testable import ForkPlan
import Foundation
import Testing

@Suite
struct RecipeIngredientSuggestionTests {
    @Test
    func mapGenerableDropsBlankAndExistingNames() {
        let generable = GenerableIngredientSuggestions(
            ingredients: [
                GenerableRecipeIngredient(name: "Garlic", amountText: "2", unit: "clove(s)"),
                GenerableRecipeIngredient(name: "  ", amountText: "1", unit: "g"),
                GenerableRecipeIngredient(name: "Salt", amountText: "", unit: ""),
                GenerableRecipeIngredient(name: "garlic", amountText: "1", unit: "")
            ]
        )

        let suggestions = RecipeIngredientSuggestor.mapGenerable(
            generable,
            excludingExistingNames: ["Salt", "Oil"]
        )

        #expect(suggestions.count == 1)
        #expect(suggestions[0] == RecipeIngredientSuggestion(name: "Garlic", amountText: "2", unit: "clove(s)"))
    }

    @Test
    func suggestThrowsWhenNameMissingWithoutCallingModel() async {
        do {
            _ = try await RecipeIngredientSuggestor.suggest(
                recipeName: "   ",
                notes: "",
                dietaryKind: .standard,
                existingIngredients: []
            )
            Issue.record("Expected missingRecipeName")
        } catch let error as RecipeIngredientSuggestionError {
            #expect(error == .missingRecipeName)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test
    func generatedContentDisclaimerIsNonEmpty() {
        #expect(RecipeIngredientSuggestor.generatedContentDisclaimer.contains("Always check"))
    }
}

@MainActor
@Suite
struct AddRecipeSuggestIngredientsCoordinatorTests {
    @Test
    func acceptIngredientSuggestionAppendsDraft() {
        let coordinator = AddRecipeCoordinator()
        coordinator.name = "Pasta"
        coordinator.ingredientSuggestions = [
            RecipeIngredientSuggestion(name: "Parmesan", amountText: "50", unit: "g"),
            RecipeIngredientSuggestion(name: "Basil", amountText: "", unit: "")
        ]

        coordinator.acceptIngredientSuggestion(
            RecipeIngredientSuggestion(name: "Parmesan", amountText: "50", unit: "g")
        )

        #expect(coordinator.ingredientDrafts.count == 1)
        #expect(coordinator.ingredientDrafts[0].name == "Parmesan")
        #expect(coordinator.ingredientDrafts[0].selectedUnit == "g")
        #expect(coordinator.ingredientSuggestions.map(\.name) == ["Basil"])
    }

    @Test
    func applyIngredientSuggestionsAppendsAllDraftsAndClearsPending() {
        let coordinator = AddRecipeCoordinator()
        coordinator.name = "Pasta"

        coordinator.applyIngredientSuggestions([
            RecipeIngredientSuggestion(name: "Parmesan", amountText: "50", unit: "g"),
            RecipeIngredientSuggestion(name: "Basil", amountText: "", unit: "")
        ])

        #expect(coordinator.ingredientDrafts.map(\.name) == ["Parmesan", "Basil"])
        #expect(coordinator.ingredientSuggestions.isEmpty)
        #expect(coordinator.suggestionStatusMessage?.contains("2 suggested ingredients") == true)
    }

    @Test
    func applyIngredientSuggestionsEmptySetsNeutralStatus() {
        let coordinator = AddRecipeCoordinator()
        coordinator.applyIngredientSuggestions([])
        #expect(coordinator.ingredientDrafts.isEmpty)
        #expect(coordinator.suggestionStatusMessage == "No additional ingredients to suggest for this recipe.")
    }

    @Test
    func saveCommitsPendingSuggestionsIntoPersistedIngredients() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let coordinator = AddRecipeCoordinator()
        coordinator.name = "Tacos"
        // Simulate leftover pending rows (e.g. older UI path) — Save must not drop them.
        coordinator.ingredientSuggestions = [
            RecipeIngredientSuggestion(name: "Tortillas", amountText: "8", unit: ""),
            RecipeIngredientSuggestion(name: "Beans", amountText: "400", unit: "g")
        ]

        let didSave = coordinator.save(existingRecipe: nil, in: context)
        #expect(didSave)
        #expect(coordinator.ingredientSuggestions.isEmpty)

        let recipe = try context.fetch(FetchDescriptor<Recipe>()).first
        let ingredients = recipe?.ingredients.sorted { $0.sortOrder < $1.sortOrder } ?? []
        #expect(ingredients.map(\.name) == ["Tortillas", "Beans"])
        #expect(ingredients[1].amount == 400)
        #expect(ingredients[1].unit == "g")
    }

    @Test
    func appliedSuggestionsSurviveSimulatedRelaunch() throws {
        let storeURL = try makePersistentTestStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent()) }

        do {
            let container = try makePersistentTestContainer(storeURL: storeURL)
            let context = container.mainContext
            let coordinator = AddRecipeCoordinator()
            coordinator.name = "Curry"
            coordinator.applyIngredientSuggestions([
                RecipeIngredientSuggestion(name: "Garlic", amountText: "2", unit: "clove(s)"),
                RecipeIngredientSuggestion(name: "Coconut milk", amountText: "400", unit: "ml")
            ])
            #expect(coordinator.save(existingRecipe: nil, in: context))
        }

        let relaunchContainer = try makePersistentTestContainer(storeURL: storeURL)
        let recipe = try #require(relaunchContainer.mainContext.fetch(FetchDescriptor<Recipe>()).first)
        let ingredients = recipe.ingredients.sorted { $0.sortOrder < $1.sortOrder }
        #expect(ingredients.map(\.name) == ["Garlic", "Coconut milk"])
        #expect(ingredients[0].amount == 2)
        #expect(ingredients[0].unit == "clove(s)")
        #expect(ingredients[1].unit == "ml")

        let reloadCoordinator = AddRecipeCoordinator()
        reloadCoordinator.loadExistingRecipe(from: recipe)
        #expect(reloadCoordinator.ingredientDrafts.map(\.name) == ["Garlic", "Coconut milk"])
    }

    @Test
    func dismissIngredientSuggestionsClearsList() {
        let coordinator = AddRecipeCoordinator()
        coordinator.ingredientSuggestions = [
            RecipeIngredientSuggestion(name: "Salt", amountText: "", unit: "")
        ]
        coordinator.dismissIngredientSuggestions()
        #expect(coordinator.ingredientSuggestions.isEmpty)
    }

    @Test
    func requestExtractConfirmsWhenFormHasContent() {
        let coordinator = AddRecipeCoordinator()
        coordinator.name = "Existing"
        coordinator.pasteText = "Some recipe"
        coordinator.requestExtractRecipeFromPaste()
        #expect(coordinator.showingPasteOverwriteConfirmation == true)
        #expect(coordinator.isExtractingPaste == false)
    }

    @Test
    func requestExtractSkipsConfirmWhenFormEmpty() {
        let coordinator = AddRecipeCoordinator()
        coordinator.pasteText = ""
        // Empty paste fails quickly without confirmation.
        coordinator.requestExtractRecipeFromPaste()
        #expect(coordinator.showingPasteOverwriteConfirmation == false)
    }

    @Test
    func cancelAIWorkClearsBusyFlags() {
        let coordinator = AddRecipeCoordinator()
        coordinator.isExtractingPaste = true
        coordinator.isSuggestingIngredients = true
        coordinator.cancelAIWork()
        #expect(coordinator.isExtractingPaste == false)
        #expect(coordinator.isSuggestingIngredients == false)
        #expect(coordinator.isAIBusy == false)
    }
}
