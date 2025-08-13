//
//  MenuRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Foundation

protocol MenuRepository {
    func add(_ menu: Menu) async throws
    func fetchAll() async throws -> [Menu]
    func delete(_ menu: Menu) async throws
}
