//
//  SwiftDataMenuRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Foundation
import SwiftData

/// SwiftData-backed implementation of ``MenuRepository``.
///
/// Stores and queries ``Menu`` models using the provided ``ModelContext``.
/// Fetches are returned in reverse chronological order by ``Menu/generatedDate``.
final class SwiftDataMenuRepository: MenuRepository {
    private let context: ModelContext

    /// Creates a repository bound to a SwiftData model context.
    /// - Parameter context: The SwiftData context used for persistence.
    init(context: ModelContext) {
        self.context = context
    }

    /// Inserts a menu and saves the context.
    func add(_ menu: Menu) async throws {
        context.insert(menu)
        try context.save()
    }

    /// Fetches all menus sorted by generated date descending.
    func fetchAll() async throws -> [Menu] {
        let descriptor = FetchDescriptor<Menu>(sortBy: [SortDescriptor(\.generatedDate, order: .reverse)])
        return try context.fetch(descriptor)
    }

    /// Deletes a menu and saves the context.
    func delete(_ menu: Menu) async throws {
        context.delete(menu)
        try context.save()
    }
}
