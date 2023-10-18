//
//  Recipe.swift
//  whattomake
//
//  Created by Amish Patel on 18/10/2023.
//

import Foundation
import SwiftUI

class Recipe {
    var name: String
    var timesUsed: Int
    var servingSize: Int
    var dateCreated: Date
    var headerImage: Image
    
    init(name: String, 
         timesUsed: Int,
         servingSize: Int,
         dateCreated: Date,
         headerImage: Image) {
        self.name = name
        self.timesUsed = timesUsed
        self.servingSize = servingSize
        self.dateCreated = dateCreated
        self.headerImage = headerImage
    }
}
