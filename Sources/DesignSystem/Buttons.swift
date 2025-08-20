//
//  Buttons.swift
//  whattomake
//
//  Created by Amish Patel on 18/08/2025.
//


import SwiftUI

// MARK: - Primary (filled)
public struct FpPrimaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        FpPrimaryButton(configuration: configuration)
    }

    private struct FpPrimaryButton: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(FpTypography.heading)
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 12)
                .foregroundStyle(.white.opacity(isEnabled ? 1.0 : 0.7))
                .background(isEnabled ? Color.fpAccent : Color.fpAccent.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: FpLayout.controlCornerRadius))
                .contentShape(RoundedRectangle(cornerRadius: FpLayout.controlCornerRadius))
                .overlay(
                    // subtle stroke to maintain shape on dark surfaces
                    RoundedRectangle(cornerRadius: FpLayout.controlCornerRadius)
                        .stroke(Color.fpSeparator.opacity(0.2), lineWidth: 0.5)
                )
                .opacity(configuration.isPressed && isEnabled ? 0.92 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
                .allowsHitTesting(isEnabled)
        }
    }
}

// MARK: - Secondary (outlined)
public struct FpSecondaryButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        FpSecondaryButton(configuration: configuration)
    }

    private struct FpSecondaryButton: View {
        let configuration: Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(FpTypography.heading)
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 12)
                .foregroundStyle(labelColor)
                .background(
                    RoundedRectangle(cornerRadius: FpLayout.controlCornerRadius)
                        .fill(Color.clear)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FpLayout.controlCornerRadius)
                        .strokeBorder(strokeColor, lineWidth: 1.5)
                )
                .contentShape(RoundedRectangle(cornerRadius: FpLayout.controlCornerRadius))
                .opacity(configuration.isPressed && isEnabled ? 0.92 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
        }

        private var labelColor: Color {
            isEnabled ? Color.fpAccent : Color.fpSecondaryLabel
        }

        private var strokeColor: Color {
            isEnabled ? Color.fpAccent : Color.fpSeparator.opacity(0.6)
        }
    }
}

// MARK: - Convenience modifiers
public extension Button {
    @ViewBuilder func fpPrimary() -> some View { buttonStyle(FpPrimaryButtonStyle()) }
    @ViewBuilder func fpSecondary() -> some View { buttonStyle(FpSecondaryButtonStyle()) }
}

public extension Toggle {
    func fpTinted() -> some View { tint(.fpAccent) }
}
