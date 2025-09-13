//
//  GenerateMenuViewModel.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//  Updated by ChatGPT on 17/08/2025.
//
import Foundation
import Observation

/// A view model that powers the "Generate Menu" screen.
///
/// It tracks the user-selected days, exposes availability based on the
/// number of stored recipes, and coordinates menu generation via
/// ``MenuRepository``.
@MainActor
@Observable
final class GenerateMenuViewModel {
    var selectedDays: [String] = []
    var generatedMenu: Menu?
    var errorMessage: String?

    private(set) var availableRecipeCount: Int = 0
    let minRecipesRequired = 7

    private let menuRepository: MenuRepository
    private let recipeRepository: RecipeRepository

    var canGenerate: Bool {
        !selectedDays.isEmpty && availableRecipeCount >= minRecipesRequired
    }

    init(menuRepository: MenuRepository, recipeRepository: RecipeRepository) {
        self.menuRepository = menuRepository
        self.recipeRepository = recipeRepository
    }

    func loadAvailability() async {
        do {
            availableRecipeCount = try await recipeRepository.countRecipes()
        } catch {
            availableRecipeCount = 0
            errorMessage = error.localizedDescription
        }
    }

    func generate() {
        guard availableRecipeCount >= minRecipesRequired else {
            errorMessage = "You need at least \(minRecipesRequired) recipes to generate a menu. You currently have \(availableRecipeCount)."
            generatedMenu = nil
            return
        }

        guard !selectedDays.isEmpty else {
            errorMessage = "Please select at least one day."
            generatedMenu = nil
            return
        }

        Task { @MainActor in
            do {
                let menu = try await menuRepository.generateMenu(for: selectedDays)
                generatedMenu = menu
                errorMessage = nil
            } catch {
                generatedMenu = nil
                errorMessage = error.localizedDescription
            }
        }
    }
}
