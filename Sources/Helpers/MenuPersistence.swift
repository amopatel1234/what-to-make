//
//  MenuPersistence.swift
//  whattomake
//
//  Created by Amish Patel on 16/06/2026.
//

import Foundation
import SwiftData

/// Menu write helpers — delete-before-insert lifecycle for regenerate.
enum MenuPersistence {
    /// Deletes all existing menus, inserts the new snapshot, and saves.
    /// - Parameters:
    ///   - menu: The menu snapshot to persist.
    ///   - context: SwiftData model context for writes.
    /// - Throws: Fetch, delete, or save errors from SwiftData.
    @MainActor
    static func replaceMenu(with menu: Menu, in context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<Menu>())
        for existingMenu in existing {
            context.delete(existingMenu)
        }
        context.insert(menu)
        try context.save()
    }
}
