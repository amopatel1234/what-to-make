//
//  GenerateMenuViewModel.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Foundation
import Observation

@MainActor
@Observable
final class GenerateMenuViewModel {
    var selectedDays: [String] = []
    var generatedMenu: Menu?
    var errorMessage: String?        // reused for validation AND use-case errors
    
    // Availability
    private(set) var availableRecipeCount: Int = 0
    let minRecipesRequired = 7
    
    private let generateUseCase: GenerateMenuUseCase
    private let countRecipesUseCase: CountRecipesUseCase
    
    // Button state
    var canGenerate: Bool {
        !selectedDays.isEmpty && availableRecipeCount >= minRecipesRequired
    }
    
    init(generateUseCase: GenerateMenuUseCase, countRecipesUseCase: CountRecipesUseCase) {
        self.generateUseCase = generateUseCase
        self.countRecipesUseCase = countRecipesUseCase
    }
    
    func loadAvailability() async {
        do {
            availableRecipeCount = try await countRecipesUseCase.execute()
        } catch {
            // If counting fails, keep 0 so the button remains disabled
            availableRecipeCount = 0
            errorMessage = error.localizedDescription
        }
    }
    
    
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
