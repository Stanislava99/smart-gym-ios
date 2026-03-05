//
//  GymSwitcherView.swift
//  SmartGym
//
//  Gym switcher for members with multiple gym memberships.
//

import SwiftUI

struct GymSwitcherView: View {
    let memberships: [(Member, Gym)]
    let currentGymId: String?
    let onSelect: (Member, Gym) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Your gyms")
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(memberships, id: \.1.id) { item in
                        GymSwitcherChip(
                            gym: item.1,
                            isSelected: item.1.id == currentGymId,
                            onTap: { onSelect(item.0, item.1) }
                        )
                    }
                }
            }
        }
    }
}

private struct GymSwitcherChip: View {
    let gym: Gym
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(gym.name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, AppSpacing.base)
                .padding(.vertical, AppSpacing.sm)
                .background(
                    isSelected
                        ? AppColors.accentLavender
                        : AppColors.neutralLight
                )
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
