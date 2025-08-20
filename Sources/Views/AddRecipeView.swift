//  AddRecipeView.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import SwiftUI
import Observation
import PhotosUI

struct AddRecipeView: View {
    @Bindable var viewModel: AddRecipeViewModel
    @FocusState private var focusedField: Field?
    enum Field { case name, notes }
    
    var body: some View {
        List {
            // MARK: Photo
            Section("Photo") {
                if let ui = viewModel.previewImage {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(1) // stay inside stroke
                        .accessibilityIdentifier("recipeImagePreview")
                }
                
                
                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                        .font(FpTypography.body)
                }
                .tint(Color.fpAccent)
                .onChange(of: viewModel.selectedPhotoItem, initial: false) {
                    viewModel.loadSelectedImage()
                }
                .accessibilityIdentifier("choosePhotoButton")
            }
            .listRowSeparator(.hidden)
            
            // MARK: Recipe
            Section("Recipe") {
                TextField("Recipe Name", text: $viewModel.name)
                    .font(FpTypography.body)
                    .foregroundStyle(Color.fpLabel)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .name)
                    .onSubmit { focusedField = .notes }
                    .accessibilityIdentifier("recipeNameField")
                
                // Multiline notes feels better for real usage
                TextField("Notes", text: $viewModel.notes, axis: .vertical)
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
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .font(FpTypography.body)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("errorMessage")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Add Recipe")
        .scrollDismissesKeyboard(.interactively)
    }
}
