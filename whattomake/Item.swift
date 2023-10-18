//
//  Item.swift
//  whattomake
//
//  Created by Amish Patel on 18/10/2023.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
