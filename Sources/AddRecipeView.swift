//
//  AddRecipeView.swift
//  whattomake
//
//  Created by Patel, Amish on 06/12/2024.
//

import SwiftUI

struct AddRecipeView: View {
    
    @State var name: String = ""
    @Binding var isPresented: Bool
    var recipeService: RecipeServiceable
    
    var body: some View {
        Form {
            TextField(text: $name) {
                Text("Enter name")
            }
            
            Button {
                Task {
                    await addRecipe()
                }
            } label: {
                Text("Add Recipe")
            }
        }
    }
    
    func addRecipe() async {
        do {
            try await recipeService.addRecipe(recipe: Recipe(name: name, timesUsed: 0, servingSize: 0, dateCreated: Date()))
            isPresented.toggle()
        } catch {
            isPresented.toggle()
        }
        
        
    }
}
