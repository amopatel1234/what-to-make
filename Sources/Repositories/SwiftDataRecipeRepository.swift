//
//  SwiftDataRecipeRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Foundation
import SwiftData

final class SwiftDataRecipeRepository: RecipeRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(_ recipe: Recipe) async throws {
        context.insert(recipe)
        try context.save()
    }

    func update(_ recipe: Recipe) async throws {
        try context.save()
    }

    func delete(_ recipe: Recipe) async throws {
        context.delete(recipe)
        try context.save()
    }

    func fetchAll() async throws -> [Recipe] {
        let descriptor = FetchDescriptor<Recipe>(sortBy: [SortDescriptor(\.name)])
        return try context.fetch(descriptor)
    }
}
