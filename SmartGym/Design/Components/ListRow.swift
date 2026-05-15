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
    /// When true, the row is not a button so a parent (e.g. NavigationLink) can handle the tap.
    let contentOnly: Bool

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        contentOnly: Bool = false
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.contentOnly = contentOnly
    }

    private var rowContent: some View {
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

            if action != nil || contentOnly {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.vertical, AppSpacing.md)
        .padding(.horizontal, AppSpacing.base)
    }

    var body: some View {
        if contentOnly {
            rowContent
        } else {
            Button(action: { action?() }) {
                rowContent
            }
            .buttonStyle(.plain)
            .disabled(action == nil)
        }
    }
}
