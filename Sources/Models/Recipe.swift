//
//  Recipe.swift
//  whattomake
//
//  Created by Amish Patel on 18/10/2023.
//

import Foundation
import SwiftUI
import SwiftData

@Model
class Recipe {
    var name: String
    var timesUsed: Int
    var servingSize: Int
    var dateCreated: Date
    
    init(name: String, 
         timesUsed: Int,
         servingSize: Int,
         dateCreated: Date) {
        self.name = name
        self.timesUsed = timesUsed
        self.servingSize = servingSize
        self.dateCreated = dateCreated
    }
}
