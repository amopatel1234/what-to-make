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
    private let weekDays = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Day selection
                Section("Select days") {
                    ForEach(weekDays, id: \.self) { day in
                        Toggle(day, isOn: Binding(
                            get: { viewModel.selectedDays.contains(day) },
                            set: { isOn in
                                if isOn { viewModel.selectedDays.append(day) }
                                else { viewModel.selectedDays.removeAll { $0 == day } }
                            }
                        ))
                        .fpTinted() // DS accent tint
                        .accessibilityIdentifier("toggleDay_\(day)")
                    }
                }

                // MARK: Requirement / status
                Section {
                    Text("Need at least \(viewModel.minRecipesRequired) recipes to generate. You have \(viewModel.availableRecipeCount).")
                        .font(FpTypography.caption)
                        .foregroundStyle(
                            viewModel.availableRecipeCount >= viewModel.minRecipesRequired
                            ? Color.fpSecondaryLabel
                            : .red
                        )
                        .accessibilityIdentifier("menuRecipesRequirementMessage")
                }

                // MARK: Generate button (grouped inside form)
                Section {
                    Button("Generate Menu") {
                        viewModel.generate()
                    }
                    .fpPrimary()
                    .disabled(!viewModel.canGenerate)
                    .accessibilityIdentifier("generateMenuButton")
                    // Note: disabled state will appear system-grey inside Form; acceptable per HIG
                }

                // MARK: Validation message (if any)
                if let message = viewModel.errorMessage {
                    Section {
                        Text(message)
                            .font(FpTypography.body)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("menuValidationMessage")
                    }
                }

                // MARK: Generated menu (value snapshot for stability)
                if let menu = viewModel.generatedMenu {
                    let rows: [(day: String, name: String)] = {
                        let names = menu.recipes.map { $0.name }
                        return Array(zip(menu.days, names))
                    }()

                    Section("Generated Menu") {
                        ForEach(rows, id: \.day) { row in
                            HStack {
                                Text(row.day)
                                Spacer()
                                Text(row.name)
                                    .foregroundStyle(Color.fpLabel)
                            }
                            .accessibilityIdentifier("menuItem_\(row.day)")
                        }
                    }
                    .id(menu.id) // keep subtree stable when regenerating
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Generate Menu")
            .toolbarTitleDisplayMode(.inline)
        }
        .task {
            await viewModel.loadAvailability()
        }
    }
}
