//
//  WeeklyMenuApp.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


import SwiftUI
import SwiftData

@main
struct WeeklyMenuApp: App {
    init() {
        DaySelectionStorage.registerDefaults()
    }

    var body: some Scene {
        let mode = StoreMode.current()
        WindowGroup {
            Group {
                // TODO(Epic 1 Story 1.6): Remove StoreMode, StoreFactory, -ui-tests-* launch args, and in-memory seeding
                if mode == .inMemoryBlank || mode == .inMemorySeeded {
                    if let container = StoreFactory.makeContainer(mode: mode) {
                        RootTabsView(storeMode: mode)
                            .fpAppTheme()
                            .modelContainer(container)
                    } else {
                        Text("Failed to initialise data store.")
                    }
                } else {
                    RootTabsView(storeMode: mode)
                        .fpAppTheme()
                }
            }
        }
        .modelContainer(for: [Recipe.self, Menu.self])
    }
}

// TODO(Epic 1 Story 1.6): Remove StoreMode, StoreFactory, -ui-tests-* launch args, and in-memory seeding
enum StoreMode {
    case persistent
    case inMemoryBlank
    case inMemorySeeded

    static func current(from processInfo: ProcessInfo = .processInfo) -> StoreMode {
        let args = Set(processInfo.arguments)
        if args.contains("-ui-tests-seeded") { return .inMemorySeeded }
        if args.contains("-ui-tests-blank")  { return .inMemoryBlank }
        return .persistent
    }
}

// TODO(Epic 1 Story 1.6): Remove StoreMode, StoreFactory, -ui-tests-* launch args, and in-memory seeding
struct StoreFactory {
    static func makeContainer(mode: StoreMode) -> ModelContainer? {
        switch mode {
        case .persistent:
            return try? ModelContainer(for: Recipe.self, Menu.self)
        case .inMemoryBlank, .inMemorySeeded:
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            return try? ModelContainer(for: Recipe.self, Menu.self, configurations: config)
        }
    }

    static func seedIfNeeded(mode: StoreMode, context: ModelContext) {
        guard mode == .inMemorySeeded else { return }

        for i in 1...8 {
            let r = Recipe(
                name: "Seeded \(i)",
                notes: i.isMultiple(of: 2) ? "Note \(i)" : nil
            )
            context.insert(r)
        }

        do { try context.save() } catch { /* ignore seed errors in tests */ }
    }
}
