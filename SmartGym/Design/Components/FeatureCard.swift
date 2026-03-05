//
//  FeatureCard.swift
//  SmartGym
//
//  Feature / Highlight card - DESIGN_SYSTEM_PROFILE.md
//  Accent background, radius_xl, bold white heading
//

import SwiftUI

struct FeatureCard: View {
    let title: String
    let subtitle: String?
    let accentColor: Color
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        accentColor: Color = AppColors.accentLavender,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
        self.action = action
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.base)
        .background(accentColor)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
    }
}
