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
                    highlight: highlight
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
            Text("New recipes will be picked for the same days and diet settings.")
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
}

// MARK: - Menu day row

private struct MenuDaySectionRow: View {
    let day: String
    let recipeName: String
    let highlight: MenuHighlightDay.Result?

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
