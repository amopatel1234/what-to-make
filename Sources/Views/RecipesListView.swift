//
//  RecipesListView.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import SwiftUI
import SwiftData

struct RecipesView: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false
    @State private var selectedRecipe: Recipe?
    @State private var deleteErrorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
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
                    List {
                        ForEach(recipes, id: \.id) { recipe in
                            HStack(spacing: 12) {
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
                        .onDelete(perform: deleteRecipes)
                    }
                    .accessibilityIdentifier("recipesList")
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Recipes")
            .tint(Color.fpAccent)
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
            .sheet(isPresented: $showAdd) {
                AddRecipeSheetContent(existingRecipe: nil, onDismiss: { showAdd = false })
            }
            .sheet(item: $selectedRecipe) { recipe in
                AddRecipeSheetContent(existingRecipe: recipe, onDismiss: { selectedRecipe = nil })
            }
            .alert("Could Not Delete Recipe", isPresented: deleteErrorPresented) {
                Button("OK", role: .cancel) { deleteErrorMessage = nil }
            } message: {
                if let deleteErrorMessage {
                    Text(deleteErrorMessage)
                }
            }
            .background(Color.fpBackground)
        }
    }

    private var deleteErrorPresented: Binding<Bool> {
        Binding(
            get: { deleteErrorMessage != nil },
            set: { if !$0 { deleteErrorMessage = nil } }
        )
    }

    private func deleteRecipes(at offsets: IndexSet) {
        for index in offsets {
            let recipe = recipes[index]
            if let filename = recipe.imageFilename {
                ImageStore.delete(named: filename)
            }
            modelContext.delete(recipe)
        }
        do {
            try modelContext.save()
            deleteErrorMessage = nil
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }
}

private struct AddRecipeSheetContent: View {
    let existingRecipe: Recipe?
    let onDismiss: () -> Void
    @State private var coordinator: AddRecipeCoordinator
    @Environment(\.modelContext) private var modelContext

    init(existingRecipe: Recipe?, onDismiss: @escaping () -> Void) {
        self.existingRecipe = existingRecipe
        self.onDismiss = onDismiss
        let coordinator = AddRecipeCoordinator()
        if let existingRecipe {
            coordinator.loadExistingRecipe(from: existingRecipe)
        }
        _coordinator = State(initialValue: coordinator)
    }

    var body: some View {
        NavigationStack {
            AddRecipeView(existingRecipe: existingRecipe, coordinator: coordinator)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", action: onDismiss)
                            .accessibilityIdentifier("cancelAddRecipeButton")
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task { @MainActor in
                                if await coordinator.save(existingRecipe: existingRecipe, in: modelContext) {
                                    onDismiss()
                                }
                            }
                        }
                        .disabled(coordinator.isSaving)
                        .accessibilityIdentifier("saveRecipeButton")
                    }
                }
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
#Preview("Empty") {
    RecipesView()
        .modelContainer(for: Recipe.self, inMemory: true)
}

#Preview("With Recipes") {
    let container = try! ModelContainer(for: Recipe.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    context.insert(Recipe(name: "Pasta", notes: "Family favorite"))
    context.insert(Recipe(name: "Tacos", notes: "Tuesday special"))
    return RecipesView()
        .modelContainer(container)
}
#endif
