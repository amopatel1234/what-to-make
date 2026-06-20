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
    @State private var showNewPlanSheet = false
    @State private var showRegenerateConfirmation = false

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
            Group {
                if let menu = latestMenu {
                    existingMenuView(menu: menu)
                } else {
                    setupView(showsHero: true)
                }
            }
            .navigationTitle("Menu")
            .sheet(isPresented: $showNewPlanSheet) {
                MenuNewPlanSheet(initialDaysRaw: newPlanInitialDaysRaw)
            }
        }
    }

    private var newPlanInitialDaysRaw: String {
        if let menu = latestMenu {
            return DaySelectionStorage.encode(Set(menu.days))
        }
        return selectedDaysRaw
    }

    // MARK: - Setup (no menu yet)

    private func setupView(showsHero: Bool) -> some View {
        ScrollView {
            MenuPlanSetupPanel(
                selectedDaysRaw: $selectedDaysRaw,
                recipeCount: recipes.count,
                minRecipesRequired: minRecipesRequired,
                coordinator: coordinator,
                showsHero: showsHero,
                onGenerate: { generateMenu(from: selectedDays) }
            )
            .padding(FpLayout.screenPadding)
        }
        .background(Color.fpBackground)
    }

    // MARK: - Existing menu

    private func existingMenuView(menu: Menu) -> some View {
        let rowNames = menu.recipeNames.isEmpty
            ? menu.recipes.map(\.name)
            : menu.recipeNames
        let rows: [(day: String, name: String)] = Array(zip(menu.days, rowNames))

        return List {
            ForEach(rows, id: \.day) { row in
                Section {
                    Text(row.name)
                        .font(FpTypography.body)
                        .foregroundStyle(Color.fpLabel)
                        .accessibilityIdentifier("menuItem_\(row.day)")
                } header: {
                    Text(row.day)
                        .font(FpTypography.caption)
                        .foregroundStyle(Color.fpSecondaryLabel)
                        .textCase(.uppercase)
                }
            }

            Section {
                Button("New Plan") {
                    showNewPlanSheet = true
                }
                .fpSecondary()
                .accessibilityIdentifier("newPlanButton")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .id(menu.id)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showRegenerateConfirmation = true
                } label: {
                    if coordinator.isGenerating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(coordinator.isGenerating)
                .accessibilityIdentifier("regenerateMenuButton")
            }
        }
        .alert(
            "Regenerate menu?",
            isPresented: $showRegenerateConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Regenerate") {
                regenerateMenu()
            }
        } message: {
            Text("New recipes will be picked for the same days.")
        }
        .overlay(alignment: .bottom) {
            if let message = coordinator.errorMessage {
                Text(message)
                    .font(FpTypography.caption)
                    .foregroundStyle(.red)
                    .padding()
                    .accessibilityIdentifier("menuValidationMessage")
            }
        }
    }

    // MARK: - Generation

    private func regenerateMenu() {
        guard let menu = latestMenu else { return }
        generateMenu(from: Set(menu.days))
    }

    private func generateMenu(from days: Set<String>) {
        guard !coordinator.isGenerating else { return }

        guard recipes.count >= minRecipesRequired else {
            coordinator.errorMessage = "You need at least \(minRecipesRequired) recipes to generate a menu. You currently have \(recipes.count)."
            return
        }

        guard !days.isEmpty else {
            coordinator.errorMessage = "Please select at least one day."
            return
        }

        coordinator.errorMessage = nil
        coordinator.isGenerating = true
        selectedDaysRaw = DaySelectionStorage.encode(days)

        Task { @MainActor in
            defer { coordinator.isGenerating = false }
            await Task.yield()

            do {
                try MenuGenerationActions.run(
                    recipes: recipes,
                    days: days,
                    modelContext: modelContext
                )
                coordinator.errorMessage = nil
            } catch {
                coordinator.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Shared setup panel

private struct MenuPlanSetupPanel: View {
    @Binding var selectedDaysRaw: String
    let recipeCount: Int
    let minRecipesRequired: Int
    @Bindable var coordinator: GenerateMenuCoordinator
    let showsHero: Bool
    let onGenerate: () -> Void

    private var selectedDays: Set<String> { DaySelectionStorage.decode(selectedDaysRaw) }
    private var canGenerate: Bool {
        !selectedDays.isEmpty && recipeCount >= minRecipesRequired && !coordinator.isGenerating
    }

    var body: some View {
        VStack(spacing: 24) {
            if showsHero {
                ContentUnavailableView(
                    MenuEmptyStateCopy.title,
                    systemImage: "calendar",
                    description: Text(MenuEmptyStateCopy.description)
                )
                .accessibilityIdentifier("menuEmptyStateView")
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Select days")
                    .font(FpTypography.heading)
                    .foregroundStyle(Color.fpLabel)

                MenuDaySelectionGrid(
                    selectedDaysRaw: $selectedDaysRaw
                )
            }

            Text("Need at least \(minRecipesRequired) recipes to generate. You have \(recipeCount).")
                .font(FpTypography.caption)
                .foregroundStyle(recipeCount >= minRecipesRequired ? Color.fpSecondaryLabel : .red)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("menuRecipesRequirementMessage")

            if let message = coordinator.errorMessage {
                Text(message)
                    .font(FpTypography.body)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("menuValidationMessage")
            }

            Button {
                onGenerate()
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
    }
}

// MARK: - Day chips

private struct MenuDaySelectionGrid: View {
    @Binding var selectedDaysRaw: String

    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private var selectedDays: Set<String> { DaySelectionStorage.decode(selectedDaysRaw) }

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 52), spacing: 8)],
            spacing: 8
        ) {
            ForEach(weekDays, id: \.self) { day in
                Button {
                    toggle(day)
                } label: {
                    FpChip(title: day, isSelected: selectedDays.contains(day))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("toggleDay_\(day)")
            }
        }
    }

    private func toggle(_ day: String) {
        var days = selectedDays
        if days.contains(day) {
            days.remove(day)
        } else {
            days.insert(day)
        }
        selectedDaysRaw = DaySelectionStorage.encode(days)
    }
}

// MARK: - New plan sheet

private struct MenuNewPlanSheet: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var coordinator = GenerateMenuCoordinator()
    @State private var selectedDaysRaw: String

    private let minRecipesRequired = 7

    init(initialDaysRaw: String) {
        _selectedDaysRaw = State(initialValue: initialDaysRaw)
    }

    private var selectedDays: Set<String> { DaySelectionStorage.decode(selectedDaysRaw) }

    var body: some View {
        NavigationStack {
            ScrollView {
                MenuPlanSetupPanel(
                    selectedDaysRaw: $selectedDaysRaw,
                    recipeCount: recipes.count,
                    minRecipesRequired: minRecipesRequired,
                    coordinator: coordinator,
                    showsHero: false,
                    onGenerate: { generateMenu() }
                )
                .padding(FpLayout.screenPadding)
            }
            .background(Color.fpBackground)
            .navigationTitle("New Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
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

            do {
                try MenuGenerationActions.run(
                    recipes: recipes,
                    days: selectedDays,
                    modelContext: modelContext
                )
                coordinator.errorMessage = nil
                dismiss()
            } catch {
                coordinator.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Generation actions

@MainActor
private enum MenuGenerationActions {
    static func run(
        recipes: [Recipe],
        days: Set<String>,
        modelContext: ModelContext
    ) throws {
        let orderedDays = DaySelectionStorage.orderedDays(from: days)
        let inputs = recipes.map {
            RecipeSelectionInput(id: $0.id, name: $0.name, usageCount: $0.usageCount)
        }
        let selectedInputs = MenuGenerator.select(from: inputs, forDays: orderedDays)
        let selectedRecipes = selectedInputs.compactMap { input in
            recipes.first { $0.id == input.id }
        }
        let menu = Menu(days: orderedDays, recipes: selectedRecipes)

        try MenuPersistence.replaceMenu(with: menu, in: modelContext)
        for recipe in selectedRecipes {
            recipe.usageCount += 1
        }
        try modelContext.save()
        UserDefaults.standard.set(
            DaySelectionStorage.encode(Set(orderedDays)),
            forKey: AppStorageKey.selectedDays.rawValue
        )
    }
}
