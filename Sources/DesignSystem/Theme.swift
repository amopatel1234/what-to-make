//
//  FpTheme.swift
//  whattomake
//
//  Created by Amish Patel on 18/08/2025.
//


import SwiftUI

/// App-wide theme (colors, default control styles, list appearance).
public struct FpTheme: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            // Global brand tint
            .tint(.fpAccent)

            // Default control styles that feel consistent across the app
            .buttonStyle(.automatic) // keep your custom .fpPrimary() where needed
            .toggleStyle(.switch)
            .scrollIndicators(.automatic)

            // Lists / Forms feel more card-like on iOS 18
            .environment(\.defaultMinListRowHeight, 48)
            .environment(\.defaultMinListHeaderHeight, 22)

            // Default backgrounds
            .background(Color.fpBackground)

            // Navigation styling (title large by default)
            .toolbarTitleDisplayMode(.automatic)
    }
}

public extension View {
    /// Apply the ForkPlan theme once at the root of your view hierarchy.
    func fpAppTheme() -> some View { self.modifier(FpTheme()) }
}
