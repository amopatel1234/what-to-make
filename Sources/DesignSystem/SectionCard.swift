//
//  SectionCard.swift
//  whattomake
//
//  Created by Amish Patel on 18/08/2025.
//


import SwiftUI

// MARK: - Card-like Section Container
public struct FpSectionCard<Content: View>: View {
    public let title: String
    @ViewBuilder public var content: Content

    public init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    public var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(title)
                    .font(FpTypography.heading)
                    .foregroundStyle(Color.fpLabel)
                Spacer()
            }
            content
        }
        .padding(16)
        .background(Color.fpSurface)
        .clipShape(RoundedRectangle(cornerRadius: FpLayout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: FpLayout.cardCornerRadius)
                .stroke(Color.fpSeparator.opacity(0.25), lineWidth: 0.5)
        )
    }
}
