//
//  FpPrimaryButtonStyle.swift
//  whattomake
//
//  Created by Amish Patel on 18/08/2025.
//


import SwiftUI

// MARK: - Primary Button (filled)
public struct FpPrimaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FpTypography.heading)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.fpAccent)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: FpLayout.controlCornerRadius))
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Secondary Button (outlined)
public struct FpSecondaryButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FpTypography.heading)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: FpLayout.controlCornerRadius)
                    .stroke(Color.fpAccent, lineWidth: 1.5)
            )
            .foregroundStyle(Color.fpAccent)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Conveniences
public extension Button {
    func fpPrimary() -> some View { buttonStyle(FpPrimaryButtonStyle()) }
    func fpSecondary() -> some View { buttonStyle(FpSecondaryButtonStyle()) }
}

public extension Toggle {
    func fpTinted() -> some View { tint(.fpAccent) }
}
