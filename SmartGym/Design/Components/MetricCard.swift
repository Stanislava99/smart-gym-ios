//
//  MetricCard.swift
//  SmartGym
//
//  Metric badge card - DESIGN_SYSTEM_PROFILE.md
//  Background: solid accent (mint, blue, orange), radius_md, bold white value + label
//

import SwiftUI

struct MetricCard: View {
    let label: String
    let value: String
    let accentColor: Color

    init(label: String, value: String, accentColor: Color) {
        self.label = label
        self.value = value
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.base)
        .background(accentColor)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }
}
