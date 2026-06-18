//
//  GenerateMenuCoordinator.swift
//  whattomake
//
//  Created by Amish Patel on 10/08/2025.
//
import Observation

@MainActor
@Observable
final class GenerateMenuCoordinator {
    var errorMessage: String?
    var isGenerating = false
}
