//  AddRecipeView.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import SwiftUI
import Observation
import PhotosUI
import SwiftData
import UIKit

@MainActor
@Observable
final class AddRecipeCoordinator {
    var name = ""
    var notes = ""
    var selectedPhotoItem: PhotosPickerItem?
    var previewImage: UIImage?
    var thumbnailBase64: String?
    var imageFilename: String?
    var errorMessage: String?
    var isSaving = false
    private var pendingRecipe: Recipe?

    func load(from recipe: Recipe) {
        name = recipe.name
        notes = recipe.notes ?? ""
        thumbnailBase64 = recipe.thumbnailBase64
        imageFilename = recipe.imageFilename
        if let thumbnailBase64 = recipe.thumbnailBase64 {
            previewImage = ImageCodec.image(fromBase64: thumbnailBase64)
        }
    }

    func loadSelectedImage() {
        guard let item = selectedPhotoItem else { return }
        Task { @MainActor in
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    await handleLoadedImageData(data)
                } else {
                    errorMessage = "Could not load photo."
                }
            } catch {
                errorMessage = "Failed to load photo."
            }
        }
    }

    func handleLoadedImageData(_ data: Data) async {
        if let uiImage = UIImage(data: data) {
            let thumbnail = ImageCodec.base64JPEGThumbnail(from: uiImage)
            let filename = try? ImageStore.saveOriginal(uiImage)
            previewImage = uiImage
            thumbnailBase64 = thumbnail
            imageFilename = filename
            errorMessage = nil
        } else {
            errorMessage = "Could not load photo."
        }
    }

    func save(existingRecipe: Recipe?, in context: ModelContext) async -> Bool {
        guard !isSaving else { return false }
        isSaving = true
        defer { isSaving = false }

        if existingRecipe == nil {
            guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
                errorMessage = "Recipe name is required."
                return false
            }
        }

        do {
            if let existingRecipe {
                existingRecipe.name = name
                existingRecipe.notes = notes
                existingRecipe.thumbnailBase64 = thumbnailBase64
                existingRecipe.imageFilename = imageFilename
            } else if let pendingRecipe {
                pendingRecipe.name = name.trimmingCharacters(in: .whitespaces)
                pendingRecipe.notes = notes.isEmpty ? nil : notes
                pendingRecipe.thumbnailBase64 = thumbnailBase64
                pendingRecipe.imageFilename = imageFilename
            } else {
                let recipe = Recipe(
                    name: name.trimmingCharacters(in: .whitespaces),
                    notes: notes.isEmpty ? nil : notes,
                    thumbnailBase64: thumbnailBase64,
                    imageFilename: imageFilename
                )
                context.insert(recipe)
                pendingRecipe = recipe
            }
            try context.save()
            pendingRecipe = nil
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

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
