//  AddRecipeView.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import SwiftUI
import PhotosUI
import SwiftData

struct AddRecipeView: View {
    let existingRecipe: Recipe?
    @Bindable var coordinator: AddRecipeCoordinator
    @FocusState private var focusedField: Field?
    /// Cached on appear so body does not re-query model availability every render.
    @State private var pasteModelAvailable = RecipePasteExtractor.isModelAvailable
    @State private var pasteUnavailableReason = RecipePasteExtractor.unavailableReasonMessage
    @State private var suggestModelAvailable = RecipeIngredientSuggestor.isModelAvailable

    enum Field: Hashable {
        case name, notes
        case ingredientName(UUID)
        case ingredientAmount(UUID)
        case ingredientCustomUnit(UUID)
    }

    private var isEditing: Bool { existingRecipe != nil }

    /// Keyboard Done belongs on single-line fields only; Notes stays multiline (Return = newline).
    private var showsKeyboardDoneButton: Bool {
        switch focusedField {
        case .name, .ingredientName, .ingredientAmount, .ingredientCustomUnit:
            true
        case .notes, .none:
            false
        }
    }

    var body: some View {
        List {
            // MARK: Photo
            Section("Photo") {
                if let ui = coordinator.previewImage {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(1) // stay inside stroke
                        .accessibilityIdentifier("recipeImagePreview")
                }

                PhotosPicker(selection: $coordinator.selectedPhotoItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                        .font(FpTypography.body)
                }
                .tint(Color.fpAccent)
                .onChange(of: coordinator.selectedPhotoItem, initial: false) {
                    coordinator.loadSelectedImage()
                }
                .accessibilityIdentifier("choosePhotoButton")
            }
            .listRowSeparator(.hidden)

            // MARK: Paste recipe (Apple Intelligence) — add only; avoid overwriting an edit.
            if !isEditing {
                Section {
                    TextField("Paste recipe text…", text: $coordinator.pasteText, axis: .vertical)
                        .lineLimit(4...12)
                        .font(FpTypography.body)
                        .foregroundStyle(Color.fpLabel)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .writingToolsBehavior(.disabled)
                        .disabled(coordinator.isAIBusy)
                        .accessibilityIdentifier("pasteRecipeField")

                    Button {
                        focusedField = nil
                        coordinator.requestExtractRecipeFromPaste()
                    } label: {
                        if coordinator.isExtractingPaste {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            Label("Extract Recipe", systemImage: "wand.and.stars")
                                .font(FpTypography.body)
                        }
                    }
                    .disabled(
                        coordinator.isAIBusy
                            || coordinator.pasteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || !pasteModelAvailable
                    )
                    .accessibilityIdentifier("extractRecipeButton")

                    if let unavailable = pasteUnavailableReason {
                        Text(unavailable)
                            .font(FpTypography.caption)
                            .foregroundStyle(Color.fpSecondaryLabel)
                            .accessibilityIdentifier("pasteRecipeUnavailableMessage")
                    }
                } header: {
                    Text("Paste recipe")
                } footer: {
                    Text(RecipeIngredientSuggestor.generatedContentDisclaimer)
                }
            }

            // MARK: Recipe
            Section("Recipe") {
                TextField("Recipe Name", text: $coordinator.name)
                    .font(FpTypography.body)
                    .foregroundStyle(Color.fpLabel)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .name)
                    .onSubmit { focusedField = .notes }
                    .writingToolsBehavior(.disabled)
                    .accessibilityIdentifier("recipeNameField")

                // TextEditor (UITextView) is required for the full Writing Tools experience.
                // Invoke via select text → edit menu / Writing Tools — not by focus alone.
                // Return inserts a newline; dismiss via tap/scroll only.
                ZStack(alignment: .topLeading) {
                    if coordinator.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Notes")
                            .font(FpTypography.body)
                            .foregroundStyle(Color.fpSecondaryLabel)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $coordinator.notes)
                        .font(FpTypography.body)
                        .foregroundStyle(Color.fpLabel)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .focused($focusedField, equals: .notes)
                        .writingToolsBehavior(.complete)
                        .accessibilityIdentifier("notesField")
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }

            // MARK: Diet
            Section("Diet") {
                Picker("Diet", selection: $coordinator.dietaryKind) {
                    ForEach(RecipeDietaryKind.allCases, id: \.self) { kind in
                        Text(kind.displayName).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("recipeDietaryKindPicker")
            }

            // MARK: Ingredients
            Section {
                ForEach($coordinator.ingredientDrafts) { $draft in
                    IngredientDraftRow(
                        draft: $draft,
                        focusedField: $focusedField,
                        onDelete: { coordinator.removeIngredient(id: draft.id) }
                    )
                }

                Button {
                    coordinator.addIngredient()
                } label: {
                    Label("Add ingredient", systemImage: "plus.circle.fill")
                        .font(FpTypography.body)
                }
                .accessibilityIdentifier("addIngredientButton")

                Button {
                    focusedField = nil
                    coordinator.suggestMissingIngredients()
                } label: {
                    if coordinator.isSuggestingIngredients {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Label("Suggest Missing Ingredients", systemImage: "wand.and.stars")
                            .font(FpTypography.body)
                    }
                }
                .disabled(
                    coordinator.isAIBusy
                        || coordinator.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || !suggestModelAvailable
                )
                .accessibilityIdentifier("suggestIngredientsButton")

                if !coordinator.ingredientSuggestions.isEmpty {
                    ForEach(Array(coordinator.ingredientSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(suggestion.name)
                                    .font(FpTypography.body)
                                    .foregroundStyle(Color.fpLabel)
                                let detail = [suggestion.amountText, suggestion.unit]
                                    .filter { !$0.isEmpty }
                                    .joined(separator: " ")
                                if !detail.isEmpty {
                                    Text(detail)
                                        .font(FpTypography.caption)
                                        .foregroundStyle(Color.fpSecondaryLabel)
                                }
                            }
                            Spacer()
                            Button("Add") {
                                coordinator.acceptIngredientSuggestion(suggestion)
                            }
                            .accessibilityIdentifier("acceptIngredientSuggestion_\(index)")
                        }
                        .accessibilityIdentifier("ingredientSuggestion_\(index)")
                    }

                    Button("Dismiss Suggestions", role: .cancel) {
                        coordinator.dismissIngredientSuggestions()
                    }
                    .accessibilityIdentifier("dismissIngredientSuggestionsButton")
                }
            } header: {
                Text("Ingredients")
            } footer: {
                Text(RecipeIngredientSuggestor.generatedContentDisclaimer)
            }

            // MARK: Status / Error
            if let status = coordinator.suggestionStatusMessage {
                Section {
                    Text(status)
                        .font(FpTypography.body)
                        .foregroundStyle(Color.fpSecondaryLabel)
                        .accessibilityIdentifier("suggestionStatusMessage")
                }
            }

            if let error = coordinator.errorMessage {
                Section {
                    Text(error)
                        .font(FpTypography.body)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("errorMessage")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(isEditing ? "Edit Recipe" : "Add Recipe")
        .scrollDismissesKeyboard(.interactively)
        // Tap non-control list chrome to resign any focused field (including Notes).
        .onTapGesture { focusedField = nil }
        .onAppear(perform: refreshModelAvailability)
        .onDisappear {
            coordinator.cancelAIWork()
        }
        .confirmationDialog(
            "Replace recipe fields?",
            isPresented: $coordinator.showingPasteOverwriteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Replace", role: .destructive) {
                coordinator.extractRecipeFromPaste()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Extracting from paste will overwrite the name, notes, diet, and ingredients you already entered.")
        }
        .toolbar {
            if showsKeyboardDoneButton {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .font(FpTypography.body)
                    .accessibilityIdentifier("dismissKeyboardButton")
                }
            }
        }
    }

    private func refreshModelAvailability() {
        pasteModelAvailable = RecipePasteExtractor.isModelAvailable
        pasteUnavailableReason = RecipePasteExtractor.unavailableReasonMessage
        suggestModelAvailable = RecipeIngredientSuggestor.isModelAvailable
    }
}

private struct IngredientDraftRow: View {
    @Binding var draft: IngredientDraft
    var focusedField: FocusState<AddRecipeView.Field?>.Binding
    let onDelete: () -> Void

    private var rowID: String { draft.id.uuidString }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                TextField("Ingredient", text: $draft.name)
                    .font(FpTypography.body)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused(focusedField, equals: .ingredientName(draft.id))
                    .onSubmit { focusedField.wrappedValue = nil }
                    .writingToolsBehavior(.disabled)
                    .accessibilityIdentifier("ingredientNameField_\(rowID)")

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .accessibilityIdentifier("deleteIngredientButton_\(rowID)")
            }

            HStack(spacing: 8) {
                TextField("Amount", text: $draft.amountText)
                    .font(FpTypography.body)
                    .keyboardType(.decimalPad)
                    .focused(focusedField, equals: .ingredientAmount(draft.id))
                    .writingToolsBehavior(.disabled)
                    .accessibilityIdentifier("ingredientAmountField_\(rowID)")

                if draft.usesCustomUnit {
                    TextField("Unit", text: $draft.customUnit)
                        .font(FpTypography.body)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .submitLabel(.done)
                        .focused(focusedField, equals: .ingredientCustomUnit(draft.id))
                        .onSubmit { focusedField.wrappedValue = nil }
                        .writingToolsBehavior(.disabled)
                        .accessibilityIdentifier("ingredientUnitField_\(rowID)")
                } else {
                    Picker("Unit", selection: $draft.selectedUnit) {
                        Text("None").tag("")
                        ForEach(IngredientUnitOption.presetUnits, id: \.self) { unit in
                            Text(unit).tag(unit)
                        }
                        Text(IngredientUnitOption.custom.rawValue).tag(IngredientUnitOption.custom.rawValue)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .accessibilityIdentifier("ingredientUnitField_\(rowID)")
                    .onChange(of: draft.selectedUnit, initial: false) { _, newValue in
                        if newValue == IngredientUnitOption.custom.rawValue {
                            draft.usesCustomUnit = true
                            draft.selectedUnit = ""
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AddRecipeView(existingRecipe: nil, coordinator: AddRecipeCoordinator())
    }
}
#endif
