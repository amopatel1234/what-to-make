//
//  Chip.swift
//  whattomake
//
//  Created by Amish Patel on 18/08/2025.
//


import SwiftUI

// MARK: - Small Tag/Chip
public struct FpChip: View {
    public let title: String
    public var isSelected: Bool

    public init(title: String, isSelected: Bool = false) {
        self.title = title
        self.isSelected = isSelected
    }

    public var body: some View {
        Text(title)
            .font(FpTypography.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.fpAccent.opacity(0.15) : Color.fpSecondary.opacity(0.15))
            .foregroundStyle(isSelected ? Color.fpAccent : Color.fpSecondary)
            .clipShape(Capsule())
    }
}
