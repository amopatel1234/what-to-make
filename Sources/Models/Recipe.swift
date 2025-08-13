//
//  Recipe.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//


import Foundation
import SwiftData

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var name: String
    var ingredients: [String]
    var notes: String?
    var usageCount: Int

    init(id: UUID = UUID(), name: String, ingredients: [String], notes: String? = nil, usageCount: Int = 0) {
        self.id = id
        self.name = name
        self.ingredients = ingredients
        self.notes = notes
        self.usageCount = usageCount
    }
}