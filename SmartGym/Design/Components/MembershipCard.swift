//
//  MembershipCard.swift
//  SmartGym
//
//  Digital membership card - DESIGN_SYSTEM_PROFILE.md
//  Feature card style: accent background, radius_xl, bold white text
//

import SwiftUI

struct MembershipCard: View {
    let member: Member
    /// Gym name to display (member's enrolled gym). Falls back to "Smart Gym" if nil.
    var gymName: String? = nil

    private var statusColor: Color {
        switch member.status.lowercased() {
        case "active": return AppColors.accentMint
        case "expired": return AppColors.accentPeach
        default: return AppColors.accentBlue
        }
    }

    private var validUntilText: String {
        guard let end = member.subscriptionEndDate, !end.isEmpty else {
            return "—"
        }
        if let date = ISO8601DateFormatter().date(from: end) ?? parseDate(end) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return end
    }

    private func parseDate(_ s: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: s)
    }

    private var memberIdDisplay: String {
        let id = member.id.replacingOccurrences(of: "-", with: "")
        let suffix = String(id.suffix(8)).uppercased()
        if suffix.count < 8 { return suffix }
        return "\(suffix.prefix(2)) • \(suffix.dropFirst(2).prefix(2)) • \(suffix.dropFirst(4).prefix(2)) • \(suffix.suffix(2))"
    }

    var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                // Top row: logo area + status badge
                HStack {
                    Text((gymName?.uppercased()).map { $0.isEmpty ? "SMART GYM" : $0 } ?? "SMART GYM")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(1)
                    Spacer()
                    Text(member.status.capitalized)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.neutralDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor)
                        .clipShape(Capsule())
                }
                .padding(.bottom, AppSpacing.xl)

                // Member name
                Text(member.fullName.isEmpty ? "Member" : member.fullName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.bottom, AppSpacing.sm)

                // Card number style (member ID)
                Text(memberIdDisplay)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.bottom, AppSpacing.lg)

                // Bottom row: valid until + tap hint
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("VALID UNTIL")
                            .font(.system(size: 9, weight: .medium))
                            .tracking(1.2)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(validUntilText)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("Tap for details")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(AppSpacing.base)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        AppColors.accentLavender,
                        AppColors.accentLavender.opacity(0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Subtle contactless-style arc
                GeometryReader { geo in
                    Circle()
                        .stroke(.white.opacity(0.15), lineWidth: 1)
                        .frame(width: geo.size.width * 0.5, height: geo.size.width * 0.5)
                        .offset(x: geo.size.width * 0.4, y: -geo.size.height * 0.1)
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl))
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
    