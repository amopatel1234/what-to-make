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

                // System Writing Tools (Proofread / Rewrite / Summarize) — not Foundation Models.
                TextField("Notes", text: $coordinator.notes, axis: .vertical)
                    .lineLimit(3...10)
                    .font(FpTypography.body)
                    .foregroundStyle(Color.fpLabel)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .notes)
                    .writingToolsBehavior(.complete)
                    .accessibilityIdentifier("notesField")
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
                    .focused(focusedField, equals: .ingredientName(draft.id))
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
                        .focused(focusedField, equals: .ingredientCustomUnit(draft.id))
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
