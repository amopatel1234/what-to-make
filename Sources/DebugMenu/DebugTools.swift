//
//  DebugTools.swift
//  whattomake
//
//  Created by Amish Patel on 11/08/2025.
//


import Foundation
import SwiftData

@MainActor
enum DebugTools {
    // Clear everything
    static func clearAll(context: ModelContext) throws {
        let allRecipes = try context.fetch(FetchDescriptor<Recipe>())
        let allMenus   = try context.fetch(FetchDescriptor<Menu>())
        allRecipes.forEach { context.delete($0) }
        allMenus.forEach { context.delete($0) }
        try context.save()
    }

    // Seed N recipes
    static func seedRecipes(count: Int, context: ModelContext) throws {
        guard count > 0 else { return }
        for i in 1...count {
            let r = Recipe(
                name: "Seed \(i)",
                notes: i.isMultiple(of: 2) ? "Quick note \(i)" : nil
            )
            context.insert(r)
        }
        try context.save()
    }

    // Seed a simple weekly menu (uses existing recipes; creates if needed)
    static func seedWeeklyMenu(context: ModelContext) throws {
        var recipes = try context.fetch(FetchDescriptor<Recipe>())
        if recipes.count < 7 {
            try seedRecipes(count: 7 - recipes.count, context: context)
            recipes = try context.fetch(FetchDescriptor<Recipe>())
        }
        let days = ["Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
        let picks = Array(recipes.prefix(days.count))
        let m = Menu(days: days, recipes: picks)
        context.insert(m)
        try context.save()
    }

    // Reset usage counts
    static func resetUsageCounts(context: ModelContext) throws {
        let allRecipes = try context.fetch(FetchDescriptor<Recipe>())
        for r in allRecipes { r.usageCount = 0 }
        try context.save()
    }

    // Utility: counts
    static func counts(context: ModelContext) throws -> (recipes: Int, menus: Int) {
        let rc = try context.fetchCount(FetchDescriptor<Recipe>())
        let mc = try context.fetchCount(FetchDescriptor<Menu>())
        return (rc, mc)
    }
}
