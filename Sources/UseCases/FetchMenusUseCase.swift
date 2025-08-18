//
//  FetchMenusUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


/// A use case that fetches all persisted ``Menu`` items.
///
/// Delegates to the injected ``MenuRepository``.
///
/// Example
/// ```swift
/// let menus = try await FetchMenusUseCase(repository: repo).execute()
/// ```
@MainActor
struct FetchMenusUseCase {
    private let repository: MenuRepository
    init(repository: MenuRepository) { self.repository = repository }
    
    /// Fetches all menus currently stored.
    /// - Returns: An array of menus.
    /// - Throws: Repository errors if fetching fails.
    func execute() async throws -> [Menu] { try await repository.fetchAll() }
}
