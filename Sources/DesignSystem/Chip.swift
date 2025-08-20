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
    public init(title: String) { self.title = title }
    public var body: some View {
        Text(title)
            .font(FpTypography.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.fpSecondary.opacity(0.15))
            .foregroundStyle(Color.fpSecondary)
            .clipShape(Capsule())
    }
}
