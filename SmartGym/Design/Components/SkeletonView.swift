//
//  SkeletonView.swift
//  SmartGym
//
//  Reusable skeleton placeholder that mirrors content layout during loading.
//  DESIGN_SYSTEM_PROFILE.md: same shape/size as the content that will appear.
//

import SwiftUI

struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var cornerRadius: CGFloat = AppRadius.sm

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(AppColors.borderSubtle.opacity(0.6))
            .frame(width: width, height: height)
    }
}

