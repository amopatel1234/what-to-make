//
//  MenuRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Foundation

/// Abstraction for persisting and querying ``Menu`` snapshots.
///
/// Concrete implementations (e.g., SwiftData-backed repositories) must provide
/// simple CRUD-style operations used by use cases. Implementations should define
/// their own sorting behavior for fetches when appropriate.
///
/// Example
/// ```swift
/// let repo: MenuRepository = SwiftDataMenuRepository(context: context)
/// try await repo.add(menu)
/// let all = try await repo.fetchAll()
/// try await repo.delete(menu)
/// ```
@MainActor
protocol MenuRepository {
    /// Persists a new menu.
    /// - Parameter menu: The menu to insert.
    /// - Throws: An error if persistence fails.
    func add(_ menu: Menu) async throws
    /// Returns all stored menus.
    /// - Returns: An array of menus, order defined by the implementation.
    /// - Throws: An error if fetching fails.
    func fetchAll() async throws -> [Menu]
    /// Deletes a menu.
    /// - Parameter menu: The menu to delete.
    /// - Throws: An error if deletion fails.
    func delete(_ menu: Menu) async throws
}
