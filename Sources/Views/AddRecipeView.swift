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

            // MARK: Paste recipe (Apple Intelligence)
            Section {
                TextField("Paste recipe text…", text: $coordinator.pasteText, axis: .vertical)
                    .lineLimit(4...12)
                    .font(FpTypography.body)
                    .foregroundStyle(Color.fpLabel)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .writingToolsBehavior(.disabled)
                    .disabled(coordinator.isExtractingPaste)
                    .accessibilityIdentifier("pasteRecipeField")

                Button {
                    focusedField = nil
                    coordinator.extractRecipeFromPaste()
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
                    coordinator.isExtractingPaste
                        || coordinator.pasteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || !RecipePasteExtractor.isModelAvailable
                )
                .accessibilityIdentifier("extractRecipeButton")

                if let unavailable = RecipePasteExtractor.unavailableReasonMessage {
                    Text(unavailable)
                        .font(FpTypography.caption)
                        .foregroundStyle(Color.fpSecondaryLabel)
                        .accessibilityIdentifier("pasteRecipeUnavailableMessage")
                }
            } header: {
                Text("Paste recipe")
            } footer: {
                Text("Uses on-device Apple Intelligence. Review the fields below before saving.")
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
            Section("Ingredients") {
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
            }

            // MARK: Error
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
