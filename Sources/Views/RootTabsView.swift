//
//  RootTabsView.swift
//  whattomake
//
//  Created by Amish Patel on 16/06/2026.
//

// Transitional: StoreFactory.seedIfNeeded — delete with Epic 1 Story 1.6

import SwiftUI
import SwiftData

struct RootTabsView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    let storeMode: StoreMode
    @State private var didSeed = false

    var body: some View {
        TabView(selection: $selectedTab) {
            RecipesView()
                .tabItem { Label("Recipes", systemImage: "book") }
                .tag(0)

            GenerateMenuView()
                .tabItem { Label("Menu", systemImage: "calendar") }
                .tag(1)
        }
        .task {
            guard !didSeed else { return }
            StoreFactory.seedIfNeeded(mode: storeMode, context: modelContext)
            didSeed = true
        }
    }
}
