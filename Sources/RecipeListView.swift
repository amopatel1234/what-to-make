//
//  RecipeListView.swift
//  whattomake
//
//  Created by Patel, Amish on 06/12/2024.
//

import SwiftUI

struct RecipeListView: View {
    
    @ObservedObject var viewModel: RecipeListViewModel
    @State var addItem: Bool = false
    
    var body: some View {
        NavigationSplitView {
                List(viewModel.recipes, id: \.id) { recipe in
                    Text(recipe.name)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            addItem.toggle()
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
        } detail: {
            
        }
        .sheet(isPresented: $addItem) {
            AddRecipeView(isPresented: $addItem, recipeService: viewModel.recipeSerive)
        }
        .onChange(of: addItem) {
            Task {
                do {
                    try await viewModel.fetchData()
                } catch {
                    
                }
            }
        }
    }
}
