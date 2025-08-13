//
//  AddRecipeViewModel.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//

import Foundation
import Observation

@MainActor
@Observable
final class AddRecipeViewModel {
    var name = ""
    // Dynamic ingredients list for better entry UX
    var ingredients: [String] = []
    var newIngredient: String = ""
    var notes = ""
    var errorMessage: String?


    private let addRecipeUseCase: AddRecipeUseCase

    init(addRecipeUseCase: AddRecipeUseCase) { self.addRecipeUseCase = addRecipeUseCase }

    func saveRecipe() async -> Bool {
        let cleaned = ingredients.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                  .filter { !$0.isEmpty }
        do {
            try await addRecipeUseCase.execute(
                name: name,
                ingredients: cleaned,
                notes: notes.isEmpty ? nil : notes
            )
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }


    func reset() {
        name = ""
        ingredients = []
        newIngredient = ""
        notes = ""
        errorMessage = nil
    }
    
    func addIngredientIfValid() {
        let trimmed = newIngredient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        ingredients.append(trimmed)
        newIngredient = ""
    }

    func removeIngredient(at index: Int) {
        guard ingredients.indices.contains(index) else { return }
        ingredients.remove(at: index)
    }

    func updateIngredient(_ text: String, at index: Int) {
        guard ingredients.indices.contains(index) else { return }
        ingredients[index] = text
    }

}
