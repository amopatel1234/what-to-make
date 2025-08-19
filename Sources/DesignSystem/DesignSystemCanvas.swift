//
//  FpDesignSystemCanvas.swift
//  whattomake
//
//  Created by Amish Patel on 18/08/2025.
//


import SwiftUI

// iOS 18+ previews with #Preview macro
struct FpDesignSystemCanvas: View {
    @State private var toggleEnabled = true

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Branding row
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.accent)
                    Text("ForkPlan Design System")
                        .font(FpTypography.title)
                        .foregroundStyle(Color.fpLabel)
                    Spacer()
                }

                FpSectionCard(title: "Palette") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                        paletteSwatch("Accent", .fpAccent)
                        paletteSwatch("Secondary", .fpSecondary)
                        paletteSwatch("Background", .fpBackground)
                        paletteSwatch("Surface", .fpSurface)
                        paletteSwatch("Label", .fpLabel)
                        paletteSwatch("Secondary Label", .fpSecondaryLabel)
                        paletteSwatch("Success", .fpSuccess)
                        paletteSwatch("Warning", .fpWarning)
                        paletteSwatch("Error", .fpError)
                    }
                }

                FpSectionCard(title: "Controls") {
                    VStack(spacing: 12) {
                        Button("Primary Action") {}.fpPrimary()
                        Button("Secondary Action") {}.fpSecondary()

                        Toggle(isOn: $toggleEnabled) {
                            Text("Enable Weekly Menu")
                                .foregroundStyle(Color.fpLabel)
                        }
                        .fpTinted()

                        HStack(spacing: 8) {
                            FpChip(title: "Vegetarian")
                            FpChip(title: "Quick")
                            FpChip(title: "Family")
                        }
                    }
                }

                FpSectionCard(title: "Text Styles") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Title / Semibold").font(FpTypography.title).foregroundStyle(Color.fpLabel)
                        Text("Headline / Semibold").font(FpTypography.heading).foregroundStyle(Color.fpLabel)
                        Text("Body").font(FpTypography.body).foregroundStyle(Color.fpLabel)
                        Text("Caption").font(FpTypography.caption).foregroundStyle(Color.fpSecondaryLabel)
                    }
                }
            }
            .padding(FpLayout.screenPadding)
            .background(Color.fpBackground)
        }
    }

    @ViewBuilder
    private func paletteSwatch(_ title: String, _ color: Color) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(height: 56)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.fpSeparator.opacity(0.3), lineWidth: 0.5)
                )
            Text(title)
                .font(FpTypography.caption)
                .foregroundStyle(Color.fpSecondaryLabel)
        }
    }
}

#Preview("Light") {
    NavigationStack { FpDesignSystemCanvas() }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack { FpDesignSystemCanvas() }
        .preferredColorScheme(.dark)
}
