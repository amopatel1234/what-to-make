//
//  RecipesListView.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import SwiftUI
import Observation

struct RecipesView: View {
    @Bindable var listVM: RecipesListViewModel
    @State private var showAdd = false
    let makeAddVM: (Recipe?) -> AddRecipeViewModel
    @State var selectedRecipe: Recipe? = nil
    
    var body: some View {
        NavigationStack {
            Group {
                if listVM.recipes.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            "No Recipes",
                            systemImage: "fork.knife",
                            description: Text("Tap + to add your first recipe.")
                        )
                    }
                    .padding(.horizontal, FpLayout.screenPadding)
                    .accessibilityIdentifier("emptyRecipesView")
                    
                } else {
                    // List of recipes
                    List {
                        ForEach(listVM.recipes, id: \.id) { recipe in
                            HStack(spacing: 12) {
                                // Thumbnail OR placeholder
                                RecipeThumbView(base64: recipe.thumbnailBase64)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(recipe.name)
                                        .font(FpTypography.body)
                                        .foregroundStyle(Color.fpLabel)
                                        .accessibilityIdentifier("recipeName_\(recipe.name)")
                                    
                                    if let notes = recipe.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(FpTypography.caption)
                                            .foregroundStyle(Color.fpSecondaryLabel)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .frame(minHeight: 56)
                            .onTapGesture {
                                selectedRecipe = recipe
                            }
                        }
                        .onDelete(perform: listVM.delete)
                    }
                    .accessibilityIdentifier("recipesList")
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)          // show fpBackground behind the list
                }
            }
            .navigationTitle("Recipes")
            .tint(Color.fpAccent)                             // local tint (remove if you apply fpAppTheme at root)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityIdentifier("addRecipeButton")
                }
            }
            .onAppear { listVM.load() }
            .sheet(isPresented: $showAdd, onDismiss: { listVM.load() }) {
                let addVM = makeAddVM(nil)
                NavigationStack {
                    AddRecipeView(viewModel: addVM)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { showAdd = false }
                                    .accessibilityIdentifier("cancelAddRecipeButton")
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    Task {
                                        if await addVM.saveRecipe() { showAdd = false }
                                    }
                                }
                                .accessibilityIdentifier("saveRecipeButton")
                            }
                        }
                }
            }
            .sheet(item: $selectedRecipe, onDismiss: { listVM.load() }) { recipe in
                let editVM = makeAddVM(recipe)
                NavigationStack {
                    AddRecipeView(viewModel: editVM)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") { selectedRecipe = nil }
                                    .accessibilityIdentifier("cancelAddRecipeButton")
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    Task {
                                        if await editVM.saveRecipe() { selectedRecipe = nil }
                                    }
                                }
                                .accessibilityIdentifier("saveRecipeButton")
                            }
                        }
                }
            }
            .background(Color.fpBackground)
        }
    }
}

/// Unified thumbnail/placeholder that matches the design system:
/// - 44×44, 8pt radius
/// - fpSurface background + subtle stroke for dark mode
private struct RecipeThumbView: View {
    let base64: String?
    
    var body: some View {
        ZStack {
            // Surface background for both thumb and placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.fpSurface)
                .frame(width: 44, height: 44)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.fpSeparator.opacity(0.25), lineWidth: 0.5)
                )
            
            if let base64, let ui = ImageCodec.image(fromBase64: base64) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.fpSecondaryLabel)
                    .accessibilityHidden(true)
            }
        }
    }
}

#if DEBUG
@MainActor
private final class PreviewMockRecipeRepository: RecipeRepository {
    private var storage: [Recipe]
    init(initial: [Recipe] = []) { self.storage = initial }
    func add(_ recipe: Recipe) async throws { storage.append(recipe) }
    func update(_ recipe: Recipe) async throws {
        if let idx = storage.firstIndex(where: { $0.id == recipe.id }) { storage[idx] = recipe }
    }
    func delete(_ recipe: Recipe) async throws { storage.removeAll { $0.id == recipe.id } }
    func fetchAll() async throws -> [Recipe] { storage }
}

#Preview("Empty") {
    let repo = PreviewMockRecipeRepository(initial: [])
    let fetch = FetchRecipesUseCase(repository: repo)
    let delete = DeleteRecipeUseCase(repository: repo)
    let vm = RecipesListViewModel(fetchUseCase: fetch, deleteUseCase: delete)
    RecipesView(listVM: vm, makeAddVM: { _ in
        AddRecipeViewModel(addRecipeUseCase: AddRecipeUseCase(repository: repo), updateRecipeUseCase: UpdateRecipesUseCase(repository: repo))
    })
}

#Preview("With Recipes") {
    let repo = PreviewMockRecipeRepository(initial: [
        Recipe(name: "Pasta", notes: "Family favorite"),
        Recipe(name: "Tacos", notes: "Tuesday special")
    ])
    let fetch = FetchRecipesUseCase(repository: repo)
    let delete = DeleteRecipeUseCase(repository: repo)
    let vm = RecipesListViewModel(fetchUseCase: fetch, deleteUseCase: delete)
    
}
#endif
