//
//  GenerateMenuView.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import SwiftUI
import SwiftData

struct GenerateMenuView: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Query private var menus: [Menu]
    @Environment(\.modelContext) private var modelContext
    @State private var coordinator = GenerateMenuCoordinator()
    @AppStorage(AppStorageKey.selectedDays.rawValue) private var selectedDaysRaw = DaySelectionStorage.defaultValue

    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private let minRecipesRequired = 7

    private var latestMenu: Menu? { menus.first }
    private var selectedDays: Set<String> { DaySelectionStorage.decode(selectedDaysRaw) }
    private var canGenerate: Bool {
        !selectedDays.isEmpty && recipes.count >= minRecipesRequired && !coordinator.isGenerating
    }

    init() {
        _menus = Query(Menu.latestDescriptor())
    }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Day selection
                Section("Select days") {
                    ForEach(weekDays, id: \.self) { day in
                        Toggle(
                            day,
                            isOn: DaySelectionStorage.toggleBinding(for: day, raw: $selectedDaysRaw)
                        )
                        .fpTinted()
                        .accessibilityIdentifier("toggleDay_\(day)")
                    }
                }

                // MARK: Requirement / status
                Section {
                    Text("Need at least \(minRecipesRequired) recipes to generate. You have \(recipes.count).")
                        .font(FpTypography.caption)
                        .foregroundStyle(
                            recipes.count >= minRecipesRequired
                            ? Color.fpSecondaryLabel
                            : .red
                        )
                        .accessibilityIdentifier("menuRecipesRequirementMessage")
                }

                // MARK: Generate button (grouped inside form)
                Section {
                    Button {
                        generateMenu()
                    } label: {
                        HStack {
                            if coordinator.isGenerating {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(coordinator.isGenerating ? "Generating…" : "Generate Menu")
                        }
                    }
                    .fpPrimary()
                    .disabled(!canGenerate)
                    .opacity(coordinator.isGenerating ? 0.7 : 1)
                    .accessibilityIdentifier("generateMenuButton")
                }

                // MARK: Validation message (if any)
                if let message = coordinator.errorMessage {
                    Section {
                        Text(message)
                            .font(FpTypography.body)
                            .foregroundStyle(.red)
                            .accessibilityIdentifier("menuValidationMessage")
                    }
                }

                // MARK: Empty state
                if latestMenu == nil {
                    Section {
                        Text(MenuEmptyStateCopy.message)
                            .font(FpTypography.body)
                            .foregroundStyle(Color.fpSecondaryLabel)
                    }
                }

                // MARK: Generated menu (value snapshot for stability)
                if let menu = latestMenu {
                    let rowNames = menu.recipeNames.isEmpty
                        ? menu.recipes.map(\.name)
                        : menu.recipeNames
                    let rows: [(day: String, name: String)] = Array(zip(menu.days, rowNames))

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
                    .id(menu.id)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Generate Menu")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private func generateMenu() {
        guard !coordinator.isGenerating else { return }

        guard recipes.count >= minRecipesRequired else {
            coordinator.errorMessage = "You need at least \(minRecipesRequired) recipes to generate a menu. You currently have \(recipes.count)."
            return
        }

        guard !selectedDays.isEmpty else {
            coordinator.errorMessage = "Please select at least one day."
            return
        }

        coordinator.errorMessage = nil
        coordinator.isGenerating = true

        Task { @MainActor in
            defer { coordinator.isGenerating = false }
            await Task.yield()

            let orderedDays = DaySelectionStorage.orderedDays(from: selectedDays)
            let inputs = recipes.map {
                RecipeSelectionInput(id: $0.id, name: $0.name, usageCount: $0.usageCount)
            }
            let selectedInputs = MenuGenerator.select(from: inputs, forDays: orderedDays)
            let selectedRecipes = selectedInputs.compactMap { input in
                recipes.first { $0.id == input.id }
            }
            let menu = Menu(days: orderedDays, recipes: selectedRecipes)

            do {
                try MenuPersistence.replaceMenu(with: menu, in: modelContext)
                for recipe in selectedRecipes {
                    recipe.usageCount += 1
                }
                try modelContext.save()
                coordinator.errorMessage = nil
            } catch {
                coordinator.errorMessage = error.localizedDescription
            }
        }
    }
}
