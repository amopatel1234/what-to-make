//
//  RecipesListView.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import SwiftUI
import Observation

struct RecipesView: View {
    @Environment(AppState.self) private var appState
    @Bindable var listVM: RecipesListViewModel
    @State private var showAdd = false
    let makeAddVM: () -> AddRecipeViewModel
    
#if DEBUG
    @State private var showDebugSheet = false
#endif
    
    
    var body: some View {
        NavigationStack {
            Group {
                if listVM.recipes.isEmpty {
                    VStack { // wrapper makes the identifier attach to a stable container
                        ContentUnavailableView(
                            "No Recipes",
                            systemImage: "book",
                            description: Text("Tap + to add your first recipe.")
                        )
                    }
                    .accessibilityIdentifier("emptyRecipesView")
                    
                } else {
                    VStack {
                        List {
                            ForEach(listVM.recipes, id: \.id) { recipe in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(recipe.name).font(.headline).accessibilityIdentifier("recipeName_\(recipe.name)")
                                        Text("\(recipe.ingredients.count) ingredients")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Text("Used: \(recipe.usageCount)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .accessibilityIdentifier("usageCount_\(recipe.name)")
                                }
                            }
                            .onDelete(perform: listVM.delete)
                        }
                    }
                    .accessibilityIdentifier("recipesList")
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                        .accessibilityIdentifier("addRecipeButton")
                }
#if DEBUG
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showDebugSheet = true
                    } label: {
                        Image(systemName: "ladybug") // 🐞
                    }
                    .accessibilityIdentifier("debug_button")
                }
#endif
                
            }
            .onAppear { listVM.load() }
            .task(id: appState.refreshCounter) {   // ← runs every time debug actions bump the counter
                listVM.load()
            }
            .sheet(isPresented: $showAdd, onDismiss: { listVM.load() }) {
                let addVM = makeAddVM()
                NavigationStack {
                    AddRecipeView(viewModel: addVM)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { showAdd = false }.accessibilityIdentifier("cancelAddRecipeButton") }
                            ToolbarItem(placement: .confirmationAction) { Button("Save") { Task { if await addVM.saveRecipe() { showAdd = false } } }.accessibilityIdentifier("saveRecipeButton") }
                        }
                }
                .presentationDetents([.medium, .large])
            }
#if DEBUG
                .sheet(isPresented: $showDebugSheet) {
                    DebugMenuView()
                        .presentationDetents([.medium, .large])
                }
#endif
        }
    }
}
