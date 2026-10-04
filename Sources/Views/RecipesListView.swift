//
//  RecipesListView.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import SwiftUI
import SwiftData

struct RecipesView: View {
    @Query(sort: [
        SortDescriptor(\Recipe.sortOrder),
        SortDescriptor(\Recipe.name)
    ]) private var recipes: [Recipe]
    @Environment(\.modelContext) private var modelContext
    @State private var showAdd = false
    @State private var selectedRecipe: Recipe?
    @State private var actionErrorMessage: String?

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
                    recipesLibraryList
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
                AddRecipeSheetContent(
                    existingRecipe: nil,
                    modelContext: modelContext,
                    onDismiss: { showAdd = false }
                )
            }
            .sheet(item: $selectedRecipe) { recipe in
                AddRecipeSheetContent(
                    existingRecipe: recipe,
                    modelContext: modelContext,
                    onDismiss: { selectedRecipe = nil }
                )
            }
            .alert("Couldn't Update", isPresented: actionErrorPresented) {
                Button("OK", role: .cancel) { actionErrorMessage = nil }
            } message: {
                if let actionErrorMessage {
                    Text(actionErrorMessage)
                }
            }
            .background(Color.fpBackground)
        }
    }

    @ViewBuilder
    private var recipesLibraryList: some View {
        if #available(iOS 27, *) {
            List {
                ForEach(recipes) { recipe in
                    recipeRow(for: recipe)
                }
                .onDelete(perform: deleteRecipes)
                .reorderable()
            }
            .accessibilityIdentifier("recipesList")
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .reorderContainer(for: Recipe.self) { difference in
                applyNativeReorder(difference)
            }
        } else {
            List {
                ForEach(recipes) { recipe in
                    recipeRow(for: recipe)
                }
                .onDelete(perform: deleteRecipes)
            }
            .accessibilityIdentifier("recipesList")
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private func recipeRow(for recipe: Recipe) -> some View {
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
        .contentShape(Rectangle())
        .onTapGesture {
            selectedRecipe = recipe
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Cooked") {
                markCooked(recipe)
            }
            .tint(.green)
            .accessibilityIdentifier("markCookedRecipe_\(recipe.id.uuidString)")
        }
        .contextMenu {
            Button("Mark as cooked") {
                markCooked(recipe)
            }
            Button("Edit") {
                selectedRecipe = recipe
            }
        }
        .accessibilityHint("Drag to reorder")
        .accessibilityAction(named: "Move Up") {
            moveRecipeUp(recipe)
        }
        .accessibilityAction(named: "Move Down") {
            moveRecipeDown(recipe)
        }
    }

    private var actionErrorPresented: Binding<Bool> {
        Binding(
            get: { actionErrorMessage != nil },
            set: { if !$0 { actionErrorMessage = nil } }
        )
    }

    @available(iOS 27, *)
    private func applyNativeReorder(
        _ difference: ReorderDifference<Recipe.ID, ReorderableSingleCollectionIdentifier>
    ) {
        // SwiftUI provides ReorderDifference; applying it to the model is app code
        // (WWDC26 “What’s new in SwiftUI” — no Array.apply(difference:) API).
        let sourceIDs = difference.sources.compactMap { sourceID in
            recipes.first(where: { $0.id == sourceID })?.id
        }
        let beforeDestinationID: UUID?
        switch difference.destination.position {
        case .before(let beforeID):
            beforeDestinationID = recipes.first(where: { $0.id == beforeID })?.id
        case .end:
            beforeDestinationID = nil
        @unknown default:
            beforeDestinationID = nil
        }

        RecipeListOrdering.moveRecipes(
            Array(recipes),
            moving: sourceIDs,
            before: beforeDestinationID
        )
        persistOrderingChanges()
    }

    private func moveRecipeUp(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }), index > 0 else {
            return
        }
        RecipeListOrdering.moveRecipes(
            Array(recipes),
            from: IndexSet(integer: index),
            to: index - 1
        )
        persistOrderingChanges()
    }

    private func moveRecipeDown(_ recipe: Recipe) {
        guard let index = recipes.firstIndex(where: { $0.id == recipe.id }),
              index < recipes.count - 1 else {
            return
        }
        RecipeListOrdering.moveRecipes(
            Array(recipes),
            from: IndexSet(integer: index),
            to: index + 2
        )
        persistOrderingChanges()
    }

    private func persistOrderingChanges() {
        do {
            try modelContext.save()
            actionErrorMessage = nil
        } catch {
            actionErrorMessage = error.localizedDescription
        }
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
            actionErrorMessage = nil
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }

    private func markCooked(_ recipe: Recipe) {
        do {
            try MenuGeneration.markCooked(recipe, in: modelContext)
            actionErrorMessage = nil
        } catch {
            actionErrorMessage = error.localizedDescription
        }
    }
}

private struct AddRecipeSheetContent: View {
    let existingRecipe: Recipe?
    /// Parent list context — passed explicitly so sheet saves cannot land in a
    /// disconnected SwiftData environment (sheet would dismiss, list stays empty).
    let modelContext: ModelContext
    let onDismiss: () -> Void
    @State private var coordinator: AddRecipeCoordinator

    init(existingRecipe: Recipe?, modelContext: ModelContext, onDismiss: @escaping () -> Void) {
        self.existingRecipe = existingRecipe
        self.modelContext = modelContext
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
                            // Save synchronously on the parent context before dismiss so the
                            // insert is committed before the sheet tears down.
                            if coordinator.save(existingRecipe: existingRecipe, in: modelContext) {
                                onDismiss()
                            }
                        }
                        .disabled(coordinator.isSaving || coordinator.isAIBusy)
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
    context.insert(Recipe(name: "Pasta", notes: "Family favorite", sortOrder: 0))
    context.insert(Recipe(name: "Tacos", notes: "Tuesday special", sortOrder: 1))
    return RecipesView()
        .modelContainer(container)
}
#endif
