//
//  GenerateMenuViewModel.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Foundation
import Observation

/// A view model that powers the "Generate Menu" screen.
///
/// It tracks the user-selected days (Mon–Sun), exposes availability based on the
/// number of stored recipes, and coordinates menu generation via
/// ``GenerateMenuUseCase``. UI state is updated on the main actor.
///
/// Validation rules
/// - The Generate button is disabled until there are at least ``minRecipesRequired`` recipes.
/// - At least one day must be selected before generating.
///
/// Example
/// ```swift
/// let vm = GenerateMenuViewModel(generateUseCase: generate, countRecipesUseCase: count)
/// await vm.loadAvailability()
/// vm.selectedDays = ["Mon", "Wed", "Fri"]
/// vm.generate()
/// ```
@MainActor
@Observable
final class GenerateMenuViewModel {
    /// The set of user-selected day identifiers (e.g., "Mon", "Tue").
    var selectedDays: [String] = []
    /// The most recently generated menu snapshot, if any.
    var generatedMenu: Menu?
    /// A user-presentable message for validation and use-case errors.
    var errorMessage: String?        // reused for validation AND use-case errors
    
    // Availability
    /// The current number of available recipes in persistence.
    private(set) var availableRecipeCount: Int = 0
    /// The minimum number of recipes required to enable generation.
    let minRecipesRequired = 7
    
    private let generateUseCase: GenerateMenuUseCase
    private let countRecipesUseCase: CountRecipesUseCase
    
    // Button state
    /// Indicates whether the Generate button should be enabled.
    ///
    /// This becomes `true` only when there is at least one selected day and the
    /// repository reports ``availableRecipeCount`` that meets or exceeds
    /// ``minRecipesRequired``.
    var canGenerate: Bool {
        !selectedDays.isEmpty && availableRecipeCount >= minRecipesRequired
    }
    
    /// Creates a new instance with its dependencies.
    /// - Parameters:
    ///   - generateUseCase: Use case responsible for generating and persisting a menu.
    ///   - countRecipesUseCase: Use case that reports how many recipes are available.
    init(generateUseCase: GenerateMenuUseCase, countRecipesUseCase: CountRecipesUseCase) {
        self.generateUseCase = generateUseCase
        self.countRecipesUseCase = countRecipesUseCase
    }
    
    /// Loads the current recipe availability and updates UI state.
    ///
    /// On failure, sets ``availableRecipeCount`` to `0` (keeping generation disabled)
    /// and publishes a user-visible ``errorMessage``.
    func loadAvailability() async {
        do {
            availableRecipeCount = try await countRecipesUseCase.execute()
        } catch {
            // If counting fails, keep 0 so the button remains disabled
            availableRecipeCount = 0
            errorMessage = error.localizedDescription
        }
    }
    
    /// Attempts to generate a menu for the currently selected days.
    ///
    /// Performs local validation first; if invalid, clears ``generatedMenu`` and sets
    /// ``errorMessage``. Otherwise, calls the use case to generate and persist a menu.
    /// On success, clears errors and updates ``generatedMenu``; on failure, sets
    /// ``errorMessage`` and clears the menu.
    func generate() {
        // Validation: enforce minimum recipe count first
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
                let menu = try await generateUseCase.execute(for: selectedDays)
                generatedMenu = menu
                errorMessage = nil
            } catch {
                generatedMenu = nil
                errorMessage = error.localizedDescription
            }
        }
    }
}
