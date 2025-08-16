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
                                    if let base64 = recipe.thumbnailBase64, let thumb = ImageCodec.image(fromBase64: base64) {
                                        Image(uiImage: thumb).resizable().scaledToFill()
                                            .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else if let fn = recipe.imageFilename, let full = ImageStore.loadOriginal(named: fn) {
                                        Image(uiImage: full).resizable().scaledToFill()
                                            .frame(width: 44, height: 44).clipShape(RoundedRectangle(cornerRadius: 8))
                                    } else {
                                        Image(systemName: "photo").frame(width: 44, height: 44).foregroundStyle(.secondary)
                                    }
                                    Text(recipe.name).accessibilityIdentifier("recipeName_\(recipe.name)")
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
//                .presentationDetents([.medium, .large])
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
