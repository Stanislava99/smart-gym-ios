//
//  PrimaryCard.swift
//  SmartGym
//
//  Primary content card - DESIGN_SYSTEM_PROFILE.md
//  Background: #FFFFFF, radius_lg, soft shadow, padding 16–24px
//

import SwiftUI

struct PrimaryCard<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: .infinity)
            .padding(AppSpacing.base)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 4)
    }
}
