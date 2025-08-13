//
//  AppState.swift
//  whattomake
//
//  Created by Amish Patel on 11/08/2025.
//


import Observation

@Observable
final class AppState {
    // Bump this to tell views “data changed; refresh please”
    var refreshCounter: Int = 0

    func bump() {
        // wrapping add prevents overflow crash in long sessions
        refreshCounter &+= 1
    }
}
