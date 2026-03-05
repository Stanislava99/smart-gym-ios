//
//  GymCard.swift
//  SmartGym
//
//  Gym info card for home - open/closed status, navigate, tap for details.
//  DESIGN_SYSTEM_PROFILE.md: Feature card style, accent background, radius_xl
//

import SwiftUI

struct GymCard: View {
    let gymName: String
    let address: String?
    let openStatus: GymOpenStatus
    let hoursText: String?
    let onNavigate: () -> Void

    private var statusColor: Color {
        switch openStatus {
        case .open: return AppColors.accentMint
        case .closed: return AppColors.accentPeach
        case .unknown: return AppColors.neutralLight
        }
    }

    private var statusLabel: String {
        switch openStatus {
        case .open: return "Open now"
        case .closed: return "Closed"
        case .unknown: return "Hours unknown"
        }
    }

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(gymName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        if let hours = hoursText {
                            Text("Today: \(hours)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    Spacer()
                    Text(statusLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(openStatus == .unknown ? AppColors.textPrimary : AppColors.neutralDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor)
                        .clipShape(Capsule())
                }

                HStack {
                    if let addr = address, !addr.isEmpty {
                        Image(systemName: "location.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                        Text(addr)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(action: onNavigate) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.system(size: 12))
                            Text("Navigate")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.white.opacity(0.25))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.base)
            .background(
                LinearGradient(
                    colors: [AppColors.accentBlue, AppColors.accentBlue.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
        }
    }
}
