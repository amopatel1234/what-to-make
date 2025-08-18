//
//  GenerateMenuView.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import SwiftUI
import Observation

struct GenerateMenuView: View {
    @Bindable var viewModel: GenerateMenuViewModel
    let weekDays = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Select days")) {
                    ForEach(weekDays, id: \.self) { day in
                        Toggle(day, isOn: Binding(
                            get: { viewModel.selectedDays.contains(day) },
                            set: { isOn in
                                if isOn { viewModel.selectedDays.append(day) }
                                else { viewModel.selectedDays.removeAll { $0 == day } }
                            }
                        ))
                        .accessibilityIdentifier("toggleDay_\(day)")
                    }
                }
                
                // Requirement text
                Section {
                    Text("Need at least \(viewModel.minRecipesRequired) recipes to generate. You have \(viewModel.availableRecipeCount).")
                        .foregroundColor(viewModel.availableRecipeCount >= viewModel.minRecipesRequired ? .secondary : .red)
                        .accessibilityIdentifier("menuRecipesRequirementMessage")
                }
                
                Button("Generate Menu") { viewModel.generate() }
                    .disabled(!viewModel.canGenerate)
                    .accessibilityIdentifier("generateMenuButton")
                
                if let message = viewModel.errorMessage {
                    Section {
                        Text(message)
                            .foregroundColor(.red)
                            .accessibilityIdentifier("menuValidationMessage")
                    }
                }
                
                if let menu = viewModel.generatedMenu {
                    // Take a VALUE snapshot so UI isn't reading SwiftData models during refresh
                    let rows: [(day: String, name: String)] = {
                        let names = menu.recipes.map { $0.name }
                        return Array(zip(menu.days, names))
                    }()

                    Section(header: Text("Generated Menu")) {
                        ForEach(rows, id: \.day) { row in
                            HStack {
                                Text(row.day)
                                Spacer()
                                Text(row.name)
                            }
                            .accessibilityIdentifier("menuItem_\(row.day)")
                        }
                    }
                    // Stabilize the subtree if a new Menu is assigned
                    .id(menu.id)
                }
            }
            .navigationTitle("Generate Menu")
        }
        // Initial load
            .task {
                await viewModel.loadAvailability()
            }
    }
}
