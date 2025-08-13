//
//  RecipeRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//

import Foundation

protocol RecipeRepository {
    func add(_ recipe: Recipe) async throws
    func update(_ recipe: Recipe) async throws
    func delete(_ recipe: Recipe) async throws
    func fetchAll() async throws -> [Recipe]
}
