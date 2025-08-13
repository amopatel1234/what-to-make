//
//  DebugMenuView.swift
//  whattomake
//
//  Created by Amish Patel on 11/08/2025.
//


import SwiftUI
import SwiftData

#if DEBUG
struct DebugMenuView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var appState
    @State private var infoMessage: String = ""
    @State private var showConfirmClear = false
    @State private var seedCount: Int = 10

    var body: some View {
        NavigationStack {
            Form {
                Section("Database") {
                    Button("Clear All Data", role: .destructive) { showConfirmClear = true }
                        .accessibilityIdentifier("debug_clearAll")

                    Stepper("Seed Recipes: \(seedCount)", value: $seedCount, in: 1...100)
                    Button("Seed Recipes Now") { perform { try DebugTools.seedRecipes(count: seedCount, context: context) } }
                        .accessibilityIdentifier("debug_seedRecipes")

                    Button("Seed Weekly Menu") { perform { try DebugTools.seedWeeklyMenu(context: context) } }
                        .accessibilityIdentifier("debug_seedMenu")

                    Button("Reset Usage Counts") { perform { try DebugTools.resetUsageCounts(context: context) } }
                        .accessibilityIdentifier("debug_resetUsage")
                }

                Section("Info") {
                    Text(infoMessage).font(.footnote).foregroundStyle(.secondary)
                        .accessibilityIdentifier("debug_info")
                }
            }
            .navigationTitle("Debug Menu")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Refresh") { refreshCounts() }.accessibilityIdentifier("debug_refresh")
                }
            }
            .onAppear { refreshCounts() }
            .alert("Clear all data?", isPresented: $showConfirmClear) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { perform { try DebugTools.clearAll(context: context) } }
            } message: {
                Text("This will remove all recipes and menus.")
            }
        }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            refreshCounts()
            appState.bump()
        } catch {
            infoMessage = "Error: \(error.localizedDescription)"
        }
    }

    private func refreshCounts() {
        do {
            let (r, m) = try DebugTools.counts(context: context)
            infoMessage = "Recipes: \(r) • Menus: \(m)"
        } catch {
            infoMessage = "Error: \(error.localizedDescription)"
        }
    }
}
#endif
