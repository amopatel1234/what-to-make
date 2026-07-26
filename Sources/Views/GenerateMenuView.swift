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
    @Environment(\.menuReferenceDate) private var menuReferenceDate
    @State private var coordinator = GenerateMenuCoordinator()
    @AppStorage(AppStorageKey.selectedDays.rawValue) private var selectedDaysRaw = DaySelectionStorage.defaultValue
    @AppStorage(AppStorageKey.dayDietConstraints.rawValue) private var dayDietConstraintsRaw = DayDietConstraintStorage.defaultValue
    @State private var showNewPlanSheet = false
    @State private var showRegenerateConfirmation = false
    @State private var recipePickerDay: MenuDayPickerItem?
    @State private var cookConfirmDay: String?
    @State private var statusMessage: String?

    private var latestMenu: Menu? { menus.first }
    private var selectedDays: Set<String> { DaySelectionStorage.decode(selectedDaysRaw) }
    private var dietConstraints: [String: DayDietConstraint] {
        DayDietConstraintStorage.decode(dayDietConstraintsRaw)
    }
    private var canGenerate: Bool {
        !selectedDays.isEmpty
            && recipes.count >= MenuGeneration.minRecipesRequired
            && !coordinator.isGenerating
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
                MenuNewPlanSheet(
                    initialDaysRaw: newPlanInitialDaysRaw,
                    initialDietConstraintsRaw: dayDietConstraintsRaw
                )
            }
            .sheet(item: $recipePickerDay) { item in
                if let menu = latestMenu {
                    MenuDayRecipePickerSheet(
                        day: item.day,
                        recipes: MenuGeneration.eligibleRecipes(
                            forDay: item.day,
                            on: menu,
                            library: recipes,
                            diet: dietConstraints[item.day] ?? .any
                        ),
                        onSelect: { recipe in
                            assignRecipe(recipe, toDay: item.day, on: menu)
                            recipePickerDay = nil
                        },
                        onCancel: { recipePickerDay = nil }
                    )
                }
            }
            .alert(
                "Mark as cooked?",
                isPresented: Binding(
                    get: { cookConfirmDay != nil },
                    set: { if !$0 { cookConfirmDay = nil } }
                )
            ) {
                Button("Cancel", role: .cancel) { cookConfirmDay = nil }
                Button("Mark Cooked") {
                    if let day = cookConfirmDay, let menu = latestMenu {
                        markCooked(day: day, on: menu)
                    }
                    cookConfirmDay = nil
                }
            } message: {
                if let day = cookConfirmDay, let menu = latestMenu {
                    let name = recipeName(for: day, on: menu) ?? "this recipe"
                    Text("Record that you cooked \(name)? This updates cook history used for future menus.")
                }
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
                dayDietConstraintsRaw: $dayDietConstraintsRaw,
                recipeCount: recipes.count,
                minRecipesRequired: MenuGeneration.minRecipesRequired,
                coordinator: coordinator,
                showsHero: showsHero,
                onGenerate: { generateMenu(from: selectedDays, dietConstraints: dietConstraints) }
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
        let highlight = MenuHighlightDay.resolve(menuDays: menu.days, on: menuReferenceDate)

        return List {
            ForEach(rows, id: \.day) { row in
                MenuDaySectionRow(
                    day: row.day,
                    recipeName: row.name,
                    highlight: highlight,
                    onReroll: { rerollDay(row.day, on: menu) },
                    onChoose: { recipePickerDay = MenuDayPickerItem(day: row.day) },
                    onMarkCooked: { cookConfirmDay = row.day }
                )
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
            Text("New recipes will be picked for the same days and diet settings. Cook history is unchanged.")
        }
        .overlay(alignment: .bottom) {
            VStack(spacing: 8) {
                if let message = statusMessage {
                    Text(message)
                        .font(FpTypography.caption)
                        .foregroundStyle(Color.fpSecondaryLabel)
                        .padding(.horizontal)
                        .accessibilityIdentifier("menuStatusMessage")
                }
                if let message = coordinator.errorMessage {
                    Text(message)
                        .font(FpTypography.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                        .accessibilityIdentifier("menuValidationMessage")
                }
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Generation & day actions

    private func regenerateMenu() {
        guard let menu = latestMenu else { return }
        generateMenu(from: Set(menu.days), dietConstraints: dietConstraints)
    }

    private func generateMenu(
        from days: Set<String>,
        dietConstraints: [String: DayDietConstraint]
    ) {
        guard !coordinator.isGenerating else { return }

        if let message = MenuGeneration.validationMessage(
            recipes: recipes,
            days: days,
            dietConstraints: dietConstraints
        ) {
            coordinator.errorMessage = message
            return
        }

        coordinator.errorMessage = nil
        statusMessage = nil
        coordinator.isGenerating = true
        selectedDaysRaw = DaySelectionStorage.encode(days)

        Task { @MainActor in
            defer { coordinator.isGenerating = false }
            await Task.yield()

            do {
                try MenuGeneration.run(
                    recipes: recipes,
                    days: days,
                    dietConstraints: dietConstraints,
                    modelContext: modelContext
                )
                coordinator.errorMessage = nil
            } catch {
                coordinator.errorMessage = error.localizedDescription
            }
        }
    }

    private func rerollDay(_ day: String, on menu: Menu) {
        do {
            if let message = try MenuGeneration.rerollDay(
                day,
                on: menu,
                recipes: recipes,
                diet: dietConstraints[day] ?? .any,
                modelContext: modelContext
            ) {
                coordinator.errorMessage = message
                statusMessage = nil
            } else {
                coordinator.errorMessage = nil
                statusMessage = "Picked a new recipe for \(day)."
            }
        } catch {
            coordinator.errorMessage = error.localizedDescription
        }
    }

    private func assignRecipe(_ recipe: Recipe, toDay day: String, on menu: Menu) {
        do {
            if let message = try MenuGeneration.assignRecipe(
                recipe,
                toDay: day,
                on: menu,
                library: recipes,
                modelContext: modelContext
            ) {
                coordinator.errorMessage = message
                statusMessage = nil
            } else {
                coordinator.errorMessage = nil
                statusMessage = "\(day) is now \(recipe.name)."
            }
        } catch {
            coordinator.errorMessage = error.localizedDescription
        }
    }

    private func markCooked(day: String, on menu: Menu) {
        guard let recipe = recipe(for: day, on: menu) else {
            coordinator.errorMessage = "Couldn’t find that recipe."
            return
        }
        do {
            try MenuGeneration.markCooked(recipe, in: modelContext)
            coordinator.errorMessage = nil
            statusMessage = "Marked \(recipe.name) as cooked."
        } catch {
            coordinator.errorMessage = error.localizedDescription
        }
    }

    private func recipeName(for day: String, on menu: Menu) -> String? {
        guard let index = menu.days.firstIndex(of: day) else { return nil }
        let names = menu.recipeNames.count == menu.days.count
            ? menu.recipeNames
            : menu.recipes.map(\.name)
        guard names.indices.contains(index) else { return nil }
        return names[index]
    }

    private func recipe(for day: String, on menu: Menu) -> Recipe? {
        guard let name = recipeName(for: day, on: menu) else { return nil }
        return MenuGeneration.orderedRecipes(for: menu, from: recipes)
            .first { $0.name == name }
            ?? recipes.first { $0.name == name }
    }
}

// MARK: - Day picker identity

private struct MenuDayPickerItem: Identifiable {
    let day: String
    var id: String { day }
}

// MARK: - Menu day row

private struct MenuDaySectionRow: View {
    let day: String
    let recipeName: String
    let highlight: MenuHighlightDay.Result?
    let onReroll: () -> Void
    let onChoose: () -> Void
    let onMarkCooked: () -> Void

    private var isHighlighted: Bool { highlight?.day == day }

    private var badgeLabel: String? {
        guard isHighlighted, let kind = highlight?.kind else { return nil }
        switch kind {
        case .today: return "Today"
        case .upNext: return "Up next"
        }
    }

    var body: some View {
        Section {
            Text(recipeName)
                .font(FpTypography.body)
                .foregroundStyle(Color.fpLabel)
                .accessibilityIdentifier("menuItem_\(day)")
                .listRowBackground(rowBackground)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Re-roll", action: onReroll)
                        .tint(Color.fpAccent)
                        .accessibilityIdentifier("rerollDay_\(day)")
                    Button("Choose", action: onChoose)
                        .tint(.indigo)
                        .accessibilityIdentifier("chooseRecipeDay_\(day)")
                    Button("Cooked", action: onMarkCooked)
                        .tint(.green)
                        .accessibilityIdentifier("markCookedDay_\(day)")
                }
                .contextMenu {
                    Button("Re-roll day", action: onReroll)
                    Button("Choose recipe…", action: onChoose)
                    Button("Mark as cooked", action: onMarkCooked)
                }
        } header: {
            HStack(spacing: 8) {
                Text(day)
                    .font(FpTypography.caption)
                    .foregroundStyle(isHighlighted ? Color.fpAccent : Color.fpSecondaryLabel)
                    .textCase(.uppercase)

                if let badgeLabel {
                    Text(badgeLabel)
                        .font(FpTypography.caption)
                        .foregroundStyle(Color.fpAccent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.fpAccent.opacity(0.15))
                        .clipShape(Capsule())
                        .accessibilityIdentifier("menuHighlight_\(day)")
                }
            }
        }
    }

    @ViewBuilder
    private var rowBackground: some View {
        if isHighlighted {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.fpAccent.opacity(0.1))
        }
    }
}

// MARK: - Recipe picker

private struct MenuDayRecipePickerSheet: View {
    let day: String
    let recipes: [Recipe]
    let onSelect: (Recipe) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    ContentUnavailableView(
                        "No Matching Recipes",
                        systemImage: "fork.knife",
                        description: Text("Nothing else fits this day’s diet filter.")
                    )
                } else {
                    List(recipes, id: \.id) { recipe in
                        Button {
                            onSelect(recipe)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.name)
                                    .font(FpTypography.body)
                                    .foregroundStyle(Color.fpLabel)
                                Text(recipe.dietaryKind.displayName)
                                    .font(FpTypography.caption)
                                    .foregroundStyle(Color.fpSecondaryLabel)
                            }
                        }
                        .accessibilityIdentifier("pickRecipe_\(recipe.id.uuidString)")
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("\(day) recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

// MARK: - Shared setup panel

private struct MenuPlanSetupPanel: View {
    @Binding var selectedDaysRaw: String
    @Binding var dayDietConstraintsRaw: String
    let recipeCount: Int
    let minRecipesRequired: Int
    @Bindable var coordinator: GenerateMenuCoordinator
    let showsHero: Bool
    let onGenerate: () -> Void

    private var selectedDays: Set<String> { DaySelectionStorage.decode(selectedDaysRaw) }
    private var canGenerate: Bool {
        !selectedDays.isEmpty
            && recipeCount >= minRecipesRequired
            && !coordinator.isGenerating
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

                Text("Turn on days for your plan, then mark any that should be veg or vegan only.")
                    .font(FpTypography.caption)
                    .foregroundStyle(Color.fpSecondaryLabel)

                MenuDayPlanList(
                    selectedDaysRaw: $selectedDaysRaw,
                    dayDietConstraintsRaw: $dayDietConstraintsRaw
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

// MARK: - Day plan list

private struct MenuDayPlanList: View {
    @Binding var selectedDaysRaw: String
    @Binding var dayDietConstraintsRaw: String

    private let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    private var selectedDays: Set<String> { DaySelectionStorage.decode(selectedDaysRaw) }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(weekDays.enumerated()), id: \.element) { index, day in
                MenuDayPlanRow(
                    day: day,
                    isSelected: selectedDays.contains(day),
                    dietConstraint: DayDietConstraintStorage.binding(
                        for: day,
                        raw: $dayDietConstraintsRaw
                    ),
                    onToggle: { isOn in
                        toggle(day, isOn: isOn)
                    }
                )
                if index < weekDays.count - 1 {
                    Divider()
                        .opacity(0.35)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color.fpSurface)
        .clipShape(RoundedRectangle(cornerRadius: FpLayout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FpLayout.cardCornerRadius)
                .stroke(Color.fpSeparator.opacity(0.25), lineWidth: 0.5)
        )
    }

    private func toggle(_ day: String, isOn: Bool) {
        var days = selectedDays
        if isOn {
            days.insert(day)
        } else {
            days.remove(day)
            dayDietConstraintsRaw = DayDietConstraintStorage.clearing(day, from: dayDietConstraintsRaw)
        }
        selectedDaysRaw = DaySelectionStorage.encode(days)
    }
}

private struct MenuDayPlanRow: View {
    let day: String
    let isSelected: Bool
    @Binding var dietConstraint: DayDietConstraint
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(day)
                .font(FpTypography.body)
                .foregroundStyle(Color.fpLabel)
                .frame(width: 36, alignment: .leading)
                .accessibilityHidden(true)

            Toggle(day, isOn: Binding(
                get: { isSelected },
                set: onToggle
            ))
            .labelsHidden()
            .tint(Color.fpAccent)
            .accessibilityIdentifier("toggleDay_\(day)")

            Picker("Diet", selection: $dietConstraint) {
                ForEach(DayDietConstraint.allCases, id: \.self) { constraint in
                    Text(constraint.shortDisplayName).tag(constraint)
                }
            }
            .pickerStyle(.segmented)
            .disabled(!isSelected)
            .opacity(isSelected ? 1 : 0.4)
            .accessibilityIdentifier("dayDiet_\(day)")
        }
        .padding(.vertical, 8)
    }
}

// MARK: - New plan sheet

private struct MenuNewPlanSheet: View {
    @Query(sort: \Recipe.name) private var recipes: [Recipe]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var coordinator = GenerateMenuCoordinator()
    @State private var selectedDaysRaw: String
    @State private var dayDietConstraintsRaw: String

    init(initialDaysRaw: String, initialDietConstraintsRaw: String) {
        _selectedDaysRaw = State(initialValue: initialDaysRaw)
        _dayDietConstraintsRaw = State(initialValue: initialDietConstraintsRaw)
    }

    private var selectedDays: Set<String> { DaySelectionStorage.decode(selectedDaysRaw) }
    private var dietConstraints: [String: DayDietConstraint] {
        DayDietConstraintStorage.decode(dayDietConstraintsRaw)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                MenuPlanSetupPanel(
                    selectedDaysRaw: $selectedDaysRaw,
                    dayDietConstraintsRaw: $dayDietConstraintsRaw,
                    recipeCount: recipes.count,
                    minRecipesRequired: MenuGeneration.minRecipesRequired,
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

        if let message = MenuGeneration.validationMessage(
            recipes: recipes,
            days: selectedDays,
            dietConstraints: dietConstraints
        ) {
            coordinator.errorMessage = message
            return
        }

        coordinator.errorMessage = nil
        coordinator.isGenerating = true

        Task { @MainActor in
            defer { coordinator.isGenerating = false }
            await Task.yield()

            do {
                try MenuGeneration.run(
                    recipes: recipes,
                    days: selectedDays,
                    dietConstraints: dietConstraints,
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
