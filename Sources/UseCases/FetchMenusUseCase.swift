//
//  FetchMenusUseCase.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


struct FetchMenusUseCase {
    private let repository: MenuRepository
    init(repository: MenuRepository) { self.repository = repository }
    func execute() async throws -> [Menu] { try await repository.fetchAll() }
}
