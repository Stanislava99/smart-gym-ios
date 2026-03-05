//
//  GymStatusCard.swift
//  SmartGym
//
//  Home tab gym card - reference style: Plan/Activity card (DESIGN_SYSTEM_PROFILE.md).
//  Rounded accent background, capsule tag (Open/Closed), gym name, hours.
//  Tap to switch to Gym tab.
//

import SwiftUI

struct GymStatusCard: View {
    let gymName: String
    let openStatus: GymOpenStatus
    let hoursText: String?
    let onTap: () -> Void

    /// Capsule tag color (lighter than card)
    private var tagColor: Color {
        switch openStatus {
        case .open, .closed: return Color.white.opacity(0.4)
        case .unknown: return AppColors.surface
        }
    }

    private var statusLabel: String {
        switch openStatus {
        case .open: return "Open"
        case .closed: return "Closed"
        case .unknown: return "Hours unknown"
        }
    }

    /// Solid accent background - orange for open, blue for closed, neutral for unknown
    private var cardBackground: Color {
        switch openStatus {
        case .open: return AppColors.accentOrange
        case .closed: return AppColors.accentBlue
        case .unknown: return AppColors.neutralLight
        }
    }

    private var textColor: Color {
        openStatus == .unknown ? AppColors.textPrimary : .white
    }

    private var subtitleColor: Color {
        openStatus == .unknown ? AppColors.textSecondary : Color.white.opacity(0.9)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                // Capsule tag (like "Medium", "Light" in reference)
                Text(statusLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(openStatus == .unknown ? AppColors.accentLavender : AppColors.neutralDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(tagColor)
                    .clipShape(Capsule())
                

                // Gym name - bold title
                Text(gymName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(textColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Details - today's hours
                if let hours = hoursText {
                    VStack(alignment: .leading) {
                        Text("Today:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(subtitleColor)
                        Text("\(hours)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(subtitleColor)
                    }
                } else if openStatus == .unknown {
                    Text("Tap for gym details")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(subtitleColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(maxHeight: .infinity)
            .padding(AppSpacing.base)
            .background(
                LinearGradient(
                    colors: [cardBackground, cardBackground.opacity(0.9)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
