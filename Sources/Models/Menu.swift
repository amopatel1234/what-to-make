//
//  Menu.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//

import Foundation
import SwiftData

@Model
final class Menu {
    @Attribute(.unique) var id: UUID
    var generatedDate: Date
    var days: [String]
    var recipes: [Recipe]

    init(id: UUID = UUID(), generatedDate: Date = Date(), days: [String], recipes: [Recipe]) {
        self.id = id
        self.generatedDate = generatedDate
        self.days = days
        self.recipes = recipes
    }
}
