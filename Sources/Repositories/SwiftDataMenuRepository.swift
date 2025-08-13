//
//  SwiftDataMenuRepository.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Foundation
import SwiftData

final class SwiftDataMenuRepository: MenuRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(_ menu: Menu) async throws {
        context.insert(menu)
        try context.save()
    }

    func fetchAll() async throws -> [Menu] {
        let descriptor = FetchDescriptor<Menu>(sortBy: [SortDescriptor(\.generatedDate, order: .reverse)])
        return try context.fetch(descriptor)
    }

    func delete(_ menu: Menu) async throws {
        context.delete(menu)
        try context.save()
    }
}
