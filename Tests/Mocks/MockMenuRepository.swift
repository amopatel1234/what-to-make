//
//  MockMenuRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//

@testable import whattomake

final class MockMenuRepository: MenuRepository {
    private(set) var menus: [Menu] = []

    func add(_ menu: Menu) async throws {
        menus.append(menu)
    }
    
    func fetchAll() async throws -> [Menu] {
        menus
    }
    
    func delete(_ menu: Menu) async throws {
        menus.removeAll { $0.id == menu.id }
    }
}
