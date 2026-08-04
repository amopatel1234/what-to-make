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
    @State private var appleIntelligence = AppleIntelligenceAvailability.current
    @State private var showImagePlayground = false
    @Environment(\.supportsImagePlayground) private var supportsImagePlayground

    enum Field: Hashable {
        case paste, name, notes
        case ingredientName(UUID)
        case ingredientAmount(UUID)
        case ingredientCustomUnit(UUID)
    }

    private var isEditing: Bool { existingRecipe != nil }

    private var showsAppleIntelligenceFeatures: Bool {
        appleIntelligence.showsFeatures
    }

    private var appleIntelligenceActionsAllowed: Bool {
        appleIntelligence.allowsActions
    }

    private var imageGenerationRequest: RecipeImageGenerationRequest {
        RecipeImageGenerationRequest(
            recipeName: coordinator.name,
            ingredientNames: coordinator.ingredientDrafts
                .filter { !$0.isBlank }
                .map(\.name),
            notes: coordinator.notes,
            dietaryKind: coordinator.dietaryKind
        )
    }

    private var showsImagePlaygroundControls: Bool {
        supportsImagePlayground && showsAppleIntelligenceFeatures
    }

    private var canOpenImagePlayground: Bool {
        showsImagePlaygroundControls
            && appleIntelligenceActionsAllowed
            && RecipeImagePlaygroundPrompt.canGenerate(from: imageGenerationRequest)
            && !coordinator.isAIBusy
    }

    /// Done dismisses keyboard for every tracked field (including multiline paste/notes).
    private var showsKeyboardDoneButton: Bool {
        focusedField != nil
    }

    private func resignFocus() {
        focusedField = nil
    }

    var body: some View {
        List {
            // MARK: Recipe (name first — primary identity for save + AI)
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

            // MARK: Photo
            Section {
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

                if showsImagePlaygroundControls {
                    Button {
                        resignFocus()
                        showImagePlayground = true
                    } label: {
                        Label("Generate with Image Playground", systemImage: "sparkles")
                            .font(FpTypography.body)
                    }
                    .buttonStyle(.borderless)
                    .disabled(!canOpenImagePlayground)
                    .accessibilityIdentifier("generateRecipeImageButton")

                    if let hint = appleIntelligence.enablementHintMessage {
                        Text(hint)
                            .font(FpTypography.caption)
                            .foregroundStyle(Color.fpSecondaryLabel)
                            .accessibilityIdentifier("imagePlaygroundUnavailableMessage")
                    } else if !RecipeImagePlaygroundPrompt.canGenerate(from: imageGenerationRequest) {
                        Text("Add a recipe name before generating an image.")
                            .font(FpTypography.caption)
                            .foregroundStyle(Color.fpSecondaryLabel)
                            .accessibilityIdentifier("generateRecipeImageNameHint")
                    }
                }
            } header: {
                Text("Photo")
            } footer: {
                if showsImagePlaygroundControls {
                    Text("Image Playground uses Apple Intelligence. Review the image before saving.")
                }
            }
            .listRowSeparator(.hidden)

            // MARK: Paste recipe (Apple Intelligence) — add only; avoid overwriting an edit.
            if !isEditing && showsAppleIntelligenceFeatures {
                Section {
                    TextField("Paste recipe text…", text: $coordinator.pasteText, axis: .vertical)
                        .lineLimit(3...5)
                        .frame(maxHeight: 120, alignment: .topLeading)
                        .font(FpTypography.body)
                        .foregroundStyle(Color.fpLabel)
                        .textInputAutocapitalization(.sentences)
                        .autocorrectionDisabled(false)
                        .writingToolsBehavior(.disabled)
                        .focused($focusedField, equals: .paste)
                        .disabled(coordinator.isAIBusy)
                        .accessibilityIdentifier("pasteRecipeField")

                    Button {
                        resignFocus()
                        coordinator.requestExtractRecipeFromPaste()
                    } label: {
                        HStack(spacing: 8) {
                            if coordinator.isExtractingPaste {
                                ProgressView()
                                Text("Extracting…")
                                    .font(FpTypography.body)
                            } else {
                                Label("Extract Recipe", systemImage: "wand.and.stars")
                                    .font(FpTypography.body)
                            }
                            Spacer(minLength: 0)
                        }
                        .frame(minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .disabled(
                        coordinator.isAIBusy
                            || coordinator.pasteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || !appleIntelligenceActionsAllowed
                    )
                    .accessibilityIdentifier("extractRecipeButton")

                    if coordinator.isExtractingPaste {
                        Text("Apple Intelligence is reading the pasted recipe…")
                            .font(FpTypography.caption)
                            .foregroundStyle(Color.fpSecondaryLabel)
                            .accessibilityIdentifier("extractRecipeProgressMessage")
                    }

                    if let hint = appleIntelligence.enablementHintMessage {
                        Text(hint)
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

            if let error = coordinator.errorMessage {
                Section {
                    Text(error)
                        .font(FpTypography.body)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("errorMessage")
                }
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

                if showsAppleIntelligenceFeatures {
                    Button {
                        resignFocus()
                        coordinator.suggestMissingIngredients()
                    } label: {
                        HStack(spacing: 8) {
                            if coordinator.isSuggestingIngredients {
                                ProgressView()
                                Text("Suggesting…")
                                    .font(FpTypography.body)
                            } else {
                                Label("Suggest Missing Ingredients", systemImage: "wand.and.stars")
                                    .font(FpTypography.body)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                    .buttonStyle(.borderless)
                    .disabled(
                        coordinator.isAIBusy
                            || coordinator.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || !appleIntelligenceActionsAllowed
                    )
                    .accessibilityIdentifier("suggestIngredientsButton")

                    if coordinator.isSuggestingIngredients {
                        Text("Apple Intelligence is suggesting missing ingredients…")
                            .font(FpTypography.caption)
                            .foregroundStyle(Color.fpSecondaryLabel)
                            .accessibilityIdentifier("suggestIngredientsProgressMessage")
                    }

                    if let hint = appleIntelligence.enablementHintMessage {
                        Text(hint)
                            .font(FpTypography.caption)
                            .foregroundStyle(Color.fpSecondaryLabel)
                            .accessibilityIdentifier("suggestIngredientsUnavailableMessage")
                    }
                }
            } header: {
                Text("Ingredients")
            } footer: {
                if showsAppleIntelligenceFeatures {
                    Text(RecipeIngredientSuggestor.generatedContentDisclaimer)
                }
            }

            // MARK: Status
            if let status = coordinator.suggestionStatusMessage {
                Section {
                    Text(status)
                        .font(FpTypography.body)
                        .foregroundStyle(Color.fpSecondaryLabel)
                        .accessibilityIdentifier("suggestionStatusMessage")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(isEditing ? "Edit Recipe" : "Add Recipe")
        .scrollDismissesKeyboard(.interactively)
        .recipeImagePlaygroundSheet(
            isPresented: $showImagePlayground,
            request: imageGenerationRequest,
            onImageData: { data in
                Task { @MainActor in
                    await coordinator.handleLoadedImageData(data)
                }
            },
            onFailure: { message in
                coordinator.errorMessage = message
            }
        )
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
                resignFocus()
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
                        resignFocus()
                    }
                    .font(FpTypography.body)
                    .accessibilityIdentifier("dismissKeyboardButton")
                }
            }
        }
    }

    private func refreshModelAvailability() {
        appleIntelligence = AppleIntelligenceAvailability.current
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
