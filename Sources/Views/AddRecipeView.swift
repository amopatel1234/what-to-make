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
    enum Field { case name, notes }

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
                    .accessibilityIdentifier("recipeNameField")

                TextField("Notes", text: $coordinator.notes, axis: .vertical)
                    .lineLimit(1...3)
                    .font(FpTypography.body)
                    .foregroundStyle(Color.fpLabel)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .notes)
                    .accessibilityIdentifier("notesField")
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
