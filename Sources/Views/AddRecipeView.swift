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
    
    var body: some View {
        Form {
            Section(header: Text("Photo")) {
                if let ui = viewModel.previewImage {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityIdentifier("recipeImagePreview")
                } else {
                    Text("No photo selected")
                        .foregroundStyle(.secondary)
                }
                
                PhotosPicker(selection: $viewModel.selectedPhotoItem, matching: .images) {
                    Label("Choose Photo", systemImage: "photo.on.rectangle")
                }
                .onChange(of: viewModel.selectedPhotoItem, initial: false) {
                    viewModel.loadSelectedImage() 
                }
                .accessibilityIdentifier("choosePhotoButton")
            }
            
            Section(header: Text("Recipe")) {
                TextField("Recipe Name", text: $viewModel.name)
                    .accessibilityIdentifier("recipeNameField")
                
                TextField("Notes", text: $viewModel.notes)
                    .accessibilityIdentifier("notesField")
            }
            
            if let error = viewModel.errorMessage {
                Section {
                    Text(error)
                        .foregroundColor(.red)
                        .accessibilityIdentifier("errorMessage")
                }
            }
        }
        .navigationTitle("Add Recipe")
    }
}
