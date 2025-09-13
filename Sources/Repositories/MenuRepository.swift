//
//  MenuRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//  Updated by ChatGPT on 17/08/2025.
//
import Foundation

/// Abstraction for persisting and querying ``Menu`` snapshots.
///
/// Concrete implementations (e.g., SwiftData-backed repositories) must provide
/// simple CRUD-style operations used by the app’s view models.
@MainActor
protocol MenuRepository {
    func add(_ menu: Menu) async throws
    func fetchAll() async throws -> [Menu]
    func delete(_ menu: Menu) async throws

    /// Generates, persists and returns a menu for the provided days.
    func generateMenu(for days: [String]) async throws -> Menu
}
