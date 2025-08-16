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
    var notes: String?
    var usageCount: Int

    // NEW: tiny, sync-friendly image data
    var thumbnailBase64: String?     // ~300–600 px JPEG as Base64

    // NEW: local original file name in app container (not synced)
    var imageFilename: String?       // e.g., "img_9F3C2A.jpg"

    init(id: UUID = UUID(), name: String, notes: String? = nil,
         usageCount: Int = 0, thumbnailBase64: String? = nil, imageFilename: String? = nil) {
        self.id = id
        self.name = name
        self.notes = notes
        self.usageCount = usageCount
        self.thumbnailBase64 = thumbnailBase64
        self.imageFilename = imageFilename
    }
}

