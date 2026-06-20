//
//  RootTabsView.swift
//  whattomake
//
//  Created by Amish Patel on 16/06/2026.
//

import SwiftUI

struct RootTabsView: View {

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            GenerateMenuView()
                .tabItem { Label("Menu", systemImage: "calendar") }
                .tag(0)

            RecipesView()
                .tabItem { Label("Recipes", systemImage: "book") }
                .tag(1)
        }
    }
}
