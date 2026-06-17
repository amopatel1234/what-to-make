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
        WindowGroup {
            RootTabsView()
                .fpAppTheme()
        }
        .modelContainer(for: [Recipe.self, Menu.self])
    }
}
