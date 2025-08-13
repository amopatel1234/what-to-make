//
//  AddRecipeView.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import SwiftUI
import Observation

struct AddRecipeView: View {
    @Bindable var viewModel: AddRecipeViewModel
    var body: some View {
        Form {
            Section(header: Text("Recipe")) {
                TextField("Recipe Name", text: $viewModel.name).accessibilityIdentifier("recipeNameField")
                Section(header: Text("Ingredients")) {
                    // Existing ingredient rows
                    ForEach(Array(viewModel.ingredients.enumerated()), id: \.0) { index, _ in
                        HStack {
                            TextField("Ingredient", text: Binding(
                                get: { viewModel.ingredients[index] },
                                set: { viewModel.updateIngredient($0, at: index) }
                            ))
                            .accessibilityIdentifier("ingredientRowField_\(index)")

                            Button(role: .destructive) {
                                viewModel.removeIngredient(at: index)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .accessibilityIdentifier("deleteIngredientButton_\(index)")
                        }
                    }

                    // Add-new row
                    HStack {
                        TextField("Add ingredient", text: $viewModel.newIngredient)
                            .submitLabel(.done)
                            .onSubmit { viewModel.addIngredientIfValid() }
                            .accessibilityIdentifier("newIngredientField")

                        Button("Add") { viewModel.addIngredientIfValid() }
                            .accessibilityIdentifier("addIngredientButton")
                    }
                }

                TextField("Notes", text: $viewModel.notes).accessibilityIdentifier("notesField")
            }
            if let error = viewModel.errorMessage { Section { Text(error).foregroundColor(.red).accessibilityIdentifier("errorMessage") } }
        }
        .navigationTitle("Add Recipe")
    }
}
