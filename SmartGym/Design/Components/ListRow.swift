//
//  ListRow.swift
//  SmartGym
//
//  List item row - DESIGN_SYSTEM_PROFILE.md
//  Icon left, title + secondary center, chevron right
//

import SwiftUI

struct ListRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: AppSpacing.base) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(AppColors.accentLavender)
                    .frame(width: 24, alignment: .center)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(AppColors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.base)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}
