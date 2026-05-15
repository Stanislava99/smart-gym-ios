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
                    HomeLoadingView()
                } else if let error = viewModel.error {
                    ErrorWithRetryView(message: error) {
                        Task { await viewModel.loadMember() }
                    }
                } else if let member = viewModel.member {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.lg) {
                            Text("Welcome back")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.textSecondary)
                            Text(member.displayName.isEmpty ? "Member" : member.displayName)
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

                            if FeatureFlags.groupTrainingsEnabled, let nextGroupTraining = viewModel.nextGroupTraining {
                                NextGroupTrainingCard(nextTraining: nextGroupTraining)
                            }

                            if FeatureFlags.weeklyStreaksEnabled {
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    Text("Weekly Strikes")
                                        .font(.headline)
                                        .foregroundStyle(AppColors.textPrimary)
                                    WeeklyStreakView(workoutDates: viewModel.weeklyWorkoutDates)
                                    Text("\(viewModel.weeklyWorkoutDates.count) workouts this week")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
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

                                    if FeatureFlags.groupTrainingsEnabled {
                                        GroupTrainingsQuickAction(
                                            groups: viewModel.groupTrainings,
                                            fillsAvailableSpace: true
                                        )
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .frame(height: 220)

                        }
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.vertical, AppSpacing.screenVertical)
                    }
                    .refreshable {
                        await viewModel.refreshMember()
                    }
                } else {
                    ErrorWithRetryView(message: "No member profile linked. Contact your gym to link your account.") {
                        Task { await viewModel.loadMember() }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.canvas)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isLoading)
        }
    }
}

private struct GroupTrainingsQuickAction: View {
    let groups: [GroupTraining]
    var fillsAvailableSpace = false

    var body: some View {
        NavigationLink {
            GroupTrainingsView(groups: groups)
        } label: {
            PrimaryCard {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Group trainings")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.textPrimary)
                    Text(groups.isEmpty ? "No group trainings available yet." : "View \(groups.count) available group trainings.")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: fillsAvailableSpace ? .infinity : nil,
                    alignment: .leading
                )
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

private struct NextGroupTrainingCard: View {
    let nextTraining: NextGroupTraining

    var body: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                HStack(alignment: .top, spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .fill(iconBackground)
                            .frame(width: 52, height: 52)

                        Image(systemName: isTrainingToday ? "figure.strengthtraining.traditional" : "moon.stars.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(iconColor)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(statusLabel)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(statusColor)
                            .textCase(.uppercase)

                        Text(headline)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    TrainingInfoPill(
                        icon: "calendar",
                        text: dateText,
                        tint: isTrainingToday ? AppColors.accentLavender : AppColors.accentBlue
                    )

                    HStack(spacing: AppSpacing.sm) {
                        TrainingInfoPill(
                            icon: "clock",
                            text: timeText,
                            tint: AppColors.accentMint
                        )

                        if let trainerName = nextTraining.trainerName {
                            TrainingInfoPill(
                                icon: "person.fill",
                                text: trainerName,
                                tint: AppColors.accentPeach
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var isTrainingToday: Bool {
        guard let date = Self.isoFormatter.date(from: nextTraining.dateIso) else {
            return false
        }

        return Calendar.current.isDateInToday(date)
    }

    private var statusLabel: String {
        isTrainingToday ? "Today" : "Rest day"
    }

    private var headline: String {
        isTrainingToday ? nextTraining.groupTitle : "Rest up today"
    }

    private var subtitle: String {
        isTrainingToday
            ? "Your group session is today at \(timeText)."
            : "No group training planned for today. Next up: \(nextTraining.groupTitle)."
    }

    private var dateText: String {
        guard let date = Self.isoFormatter.date(from: nextTraining.dateIso) else {
            return nextTraining.dateIso
        }

        if Calendar.current.isDateInToday(date) {
            return "Today"
        }

        if Calendar.current.isDateInTomorrow(date) {
            return "Tomorrow"
        }

        return Self.displayDateFormatter.string(from: date)
    }

    private var timeText: String {
        let start = String(nextTraining.startTime.prefix(5))
        guard let endTime = nextTraining.endTime else {
            return start
        }

        return "\(start)-\(String(endTime.prefix(5)))"
    }

    private var iconBackground: Color {
        isTrainingToday ? AppColors.accentLavender.opacity(0.22) : AppColors.neutralLight
    }

    private var iconColor: Color {
        isTrainingToday ? AppColors.accentLavender : AppColors.textPrimary
    }

    private var statusColor: Color {
        isTrainingToday ? AppColors.accentLavender : AppColors.textSecondary
    }

    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("EEE, MMM d")
        return formatter
    }()
}

private struct TrainingInfoPill: View {
    let icon: String
    let text: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)

            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, 7)
        .background(tint.opacity(0.16))
        .clipShape(Capsule())
    }
}

// MARK: - Home loading (skeleton matching content layout)

private struct HomeLoadingView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                SkeletonView(height: 14)
                    .frame(width: 120)
                SkeletonView(height: 24)
                    .frame(width: 180)
                PrimaryCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SkeletonView(height: 16)
                            .frame(width: 140)
                        SkeletonView(height: 12)
                            .frame(width: 200)
                    }
                }
                .frame(height: 100)
                if FeatureFlags.weeklyStreaksEnabled {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SkeletonView(height: 18)
                            .frame(width: 140)
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(0..<7, id: \.self) { _ in
                                SkeletonView(width: 44, height: 72)
                                    .clipShape(Capsule())
                            }
                        }
                        SkeletonView(height: 12)
                            .frame(width: 140)
                    }
                }
                HStack(alignment: .top, spacing: AppSpacing.cardGap) {
                    SkeletonView()
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    VStack(spacing: AppSpacing.cardGap) {
                        SkeletonView()
                            .frame(height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                        SkeletonView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 130)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 220)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.vertical, AppSpacing.screenVertical)
        }
    }
}

private struct WeeklyStreakDay: Identifiable {
    let id = UUID()
    let date: Date
    let weekdayShort: String
    let dayNumber: String
    let isToday: Bool
}

private struct WeeklyStreakView: View {
    /// ISO dates (YYYY-MM-DD) that have workouts in the current week.
    var workoutDates: Set<String> = []
    private let days: [WeeklyStreakDay] = Self.makeCurrentWeek()
    private static let isoFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(days) { day in
                let isoDate = Self.isoFormatter.string(from: day.date)
                let hasWorkout = workoutDates.contains(isoDate)
                WeeklyStreakPill(day: day, isFilled: hasWorkout)
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
                date: date,
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

    /// When the day has a workout: green (accent mint) pill with weight icon; otherwise today = dark, else = outline.
    private var pillBackground: Color {
        if isFilled { return AppColors.accentMint }
        if day.isToday { return AppColors.neutralDark }
        return Color.clear
    }

    private var pillStroke: Color {
        if isFilled || day.isToday { return Color.clear }
        return AppColors.borderSubtle
    }

    private var textColor: Color {
        if isFilled || day.isToday { return Color.white }
        return AppColors.textSecondary
    }

    private var dayNumberColor: Color {
        if isFilled || day.isToday { return Color.white }
        return AppColors.textPrimary
    }

    var body: some View {
        ZStack {
            Capsule()
                .fill(pillBackground)
                .overlay(Capsule().stroke(pillStroke, lineWidth: 1))
                .frame(width: 44, height: 72)
            VStack(spacing: 4) {
                Text(day.weekdayShort)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(textColor)
                Text(day.dayNumber)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundStyle(dayNumberColor)
            }
        }
        .overlay(
            Group {
                if isFilled {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white)
                        .offset(y: -6)
                } else {
                    Circle()
                        .fill(AppColors.borderSubtle)
                        .frame(width: 6, height: 6)
                        .offset(y: -6)
                }
            },
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
