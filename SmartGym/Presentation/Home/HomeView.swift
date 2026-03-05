//
//  HomeView.swift
//  SmartGym
//

import SwiftUI
import UIKit

struct HomeView: View {
    @Bindable var viewModel: HomeViewModel
    /// Called when user taps gym card to switch to Gym tab
    var onGymTap: (() -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let member = viewModel.member {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.lg) {
                            Text("Welcome back")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                            Text(member.fullName.isEmpty ? "Member" : member.fullName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(AppColors.textPrimary)

                            // Gym switcher (multi-gym)
                            if viewModel.memberships.count > 1 {
                                GymSwitcherView(
                                    memberships: viewModel.memberships,
                                    currentGymId: viewModel.gym?.id,
                                    onSelect: { m, g in
                                        Task { await viewModel.switchGym(member: m, gym: g) }
                                    }
                                )
                            }

                            // Membership card -> Navigate to payment history
                            NavigationLink {
                                PaymentHistoryView()
                            } label: {
                                MembershipCard(member: member, gymName: viewModel.gym?.name)
                            }

                            // Weekly strikes
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Weekly Strikes")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.textPrimary)
                                WeeklyStreakView(hasWorkoutToday: viewModel.hasWorkoutToday)
                                Text("3 workouts this week")
                                    .font(.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                            }

                            // Grid of gym info + invite friend + placeholder card
                            HStack(alignment: .top, spacing: AppSpacing.cardGap) {
                                // Gym status card: largest card on the left,
                                // same total height as the two stacked cards on the right.
                                GymStatusCard(
                                    gymName: viewModel.gym?.name ?? "Your Gym",
                                    openStatus: viewModel.gymOpenStatus,
                                    hoursText: viewModel.gymHoursText,
                                    onTap: { onGymTap?() }
                                )
                                .frame(height: 220)
                                .frame(maxWidth: .infinity)
                                
                                VStack(spacing: AppSpacing.cardGap) {
                                    // Invite a friend card (smaller, top-right)
                                    if let overview = viewModel.referralOverview {
                                        ReferralQuickActionCard(
                                            overview: overview,
                                            onInvite: {
                                                Task {
                                                    let message = await viewModel.inviteFriendShareMessage()
                                                    let activityVC = UIActivityViewController(
                                                        activityItems: [message],
                                                        applicationActivities: nil
                                                    )
                                                    if let scene = UIApplication.shared.connectedScenes
                                                        .first as? UIWindowScene,
                                                       let root = scene.keyWindow?.rootViewController
                                                    {
                                                        root.present(activityVC, animated: true)
                                                    }
                                                }
                                            }
                                        )
                                        .frame(height: 70)
                                        .frame(maxWidth: .infinity)
                                    }

                                    // Extra placeholder card for future content
                                    PrimaryCard {
                                        VStack(alignment: .leading) {
                                            Text("More coming soon")
                                                .font(.subheadline)
                                                .foregroundStyle(AppColors.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .frame(height: 220)
                        }
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.vertical, AppSpacing.screenVertical)
                    }
                } else {
                    Text(viewModel.error ?? "No member profile linked. Contact your gym to link your account.")
                        .font(.body)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.canvas)
        }
    }
}

private struct WeeklyStreakDay: Identifiable {
    let id = UUID()
    let weekdayShort: String
    let dayNumber: String
    let isToday: Bool
}

private struct WeeklyStreakView: View {
    // In the future this can accept a per-day workout map; for now we only
    // care about whether today has a workout.
    var hasWorkoutToday: Bool = false
    private let days: [WeeklyStreakDay] = Self.makeCurrentWeek()

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(days) { day in
                WeeklyStreakPill(day: day, isFilled: day.isToday && hasWorkoutToday)
            }
        }
    }

    private static func makeCurrentWeek() -> [WeeklyStreakDay] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(
            byAdding: .day,
            value: -(weekday - calendar.firstWeekday),
            to: calendar.startOfDay(for: today)
        ) ?? today

        let weekdayFormatter = DateFormatter()
        weekdayFormatter.locale = Locale.current
        weekdayFormatter.dateFormat = "EEE"

        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale.current
        dayFormatter.dateFormat = "d"

        return (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: startOfWeek) else {
                return nil
            }
            return WeeklyStreakDay(
                weekdayShort: weekdayFormatter.string(from: date),
                dayNumber: dayFormatter.string(from: date),
                isToday: calendar.isDate(date, inSameDayAs: today)
            )
        }
    }
}

private struct WeeklyStreakPill: View {
    let day: WeeklyStreakDay
    let isFilled: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(day.isToday ? AppColors.neutralDark : Color.clear)
                .overlay(
                    Capsule()
                        .stroke(day.isToday ? Color.clear : AppColors.borderSubtle, lineWidth: 1)
                )
                .frame(width: 44, height: 72)
            VStack(spacing: 4) {
                Text(day.weekdayShort)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(day.isToday ? Color.white : AppColors.textSecondary)
                Text(day.dayNumber)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(day.isToday ? Color.white : AppColors.textPrimary)
            }
        }
        .overlay(
            Circle()
                .fill(day.isToday && isFilled ? Color.white : AppColors.borderSubtle)
                .frame(width: 6, height: 6)
                .offset(y: -6),
            alignment: .top
        )
    }
}

// MARK: - Referral Quick Action

private struct ReferralQuickActionCard: View {
    let overview: MemberReferralOverview
    let onInvite: () -> Void

    var body: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack {
                    Text("Invite a friend")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Spacer()
                    Button(action: onInvite) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .tint(AppColors.accentLavender)
                }
            }
        }
    }
}
