//
//  ProfileView.swift
//  SmartGym
//
//  Profile screen - DESIGN_SYSTEM_PROFILE.md
//  Layout: avatar + name, metric cards (start weight, goal), edit profile, settings
//

import SwiftUI
import UIKit

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    var onSignOut: () -> Void
    @State private var shareText: ShareText?

    private func goalDisplayText(_ goal: String?) -> String {
        guard let g = goal, !g.isEmpty else { return "—" }
        if let num = Double(g.trimmingCharacters(in: .whitespaces)), num > 0 {
            return String(format: "%.1f kg", num)
        }
        return g
    }

    private func dailyCaloriesDisplay(for member: Member) -> String {
        guard let weightKg = member.weightKg, weightKg > 0 else {
            return "Set weight"
        }

        var estimate = weightKg * 30
        if let goal = member.goal?.trimmingCharacters(in: .whitespacesAndNewlines),
           let goalWeight = Double(goal),
           goalWeight > 0 {
            if goalWeight < weightKg - 0.5 {
                estimate -= 300
            } else if goalWeight > weightKg + 0.5 {
                estimate += 300
            }
        }

        let roundedEstimate = Int((estimate / 50).rounded() * 50)
        return "\(roundedEstimate) kcal"
    }

    private func currentWeightDisplay(for member: Member) -> String {
        (viewModel.weightLogs.last?.weightKg ?? member.weightKg).map { String(format: "%.1f kg", $0) } ?? "—"
    }

    private func weightProgressSubtitle(for member: Member) -> String {
        guard let start = member.weightKg, let latest = viewModel.weightLogs.last?.weightKg else {
            return "Log body weight and follow your trend"
        }

        let delta = latest - start
        if abs(delta) < 0.05 {
            return "No change from start weight yet"
        }
        return "\(delta > 0 ? "+" : "")\(String(format: "%.1f", delta)) kg from start"
    }

    private func shareInvite() {
        Task {
            let message = await viewModel.inviteFriendShareMessage()
            shareText = ShareText(text: message)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProfileLoadingView()
                } else if let error = viewModel.error {
                    ErrorWithRetryView(message: error) {
                        Task { await viewModel.loadProfile() }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                            // User info section: avatar left, name + location right, edit/share icons
                            if let member = viewModel.member {
                                HStack(alignment: .top, spacing: AppSpacing.base) {
                                    // Avatar
                                    ProfileAvatarView(avatarUrl: member.avatarUrl)
                                        .frame(width: 80, height: 80)

                                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                        Text(member.displayName.isEmpty ? "Member" : member.displayName)
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundStyle(AppColors.textPrimary)
                                        Text(member.email)
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundStyle(AppColors.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    HStack(spacing: AppSpacing.sm) {
                                        Button {
                                            shareInvite()
                                        } label: {
                                            if viewModel.isPreparingShare {
                                                ProgressView()
                                                    .controlSize(.small)
                                            } else {
                                                Image(systemName: "square.and.arrow.up")
                                                    .font(.body)
                                                    .foregroundStyle(AppColors.textPrimary)
                                            }
                                        }
                                        .disabled(viewModel.isPreparingShare)
                                        NavigationLink {
                                            EditProfileView(viewModel: viewModel)
                                        } label: {
                                            Image(systemName: "pencil")
                                                .font(.body)
                                                .foregroundStyle(AppColors.textPrimary)
                                        }
                                    }
                                }
                                .padding(.vertical, AppSpacing.base)

                                // Metric cards: Start weight, current weight, goal, daily calories
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: AppSpacing.sm),
                                        GridItem(.flexible(), spacing: AppSpacing.sm)
                                    ],
                                    spacing: AppSpacing.sm
                                ) {
                                    MetricCard(
                                        label: "Start weight",
                                        value: member.weightKg.map { String(format: "%.1f kg", $0) } ?? "—",
                                        accentColor: AppColors.accentMint
                                    )
                                    MetricCard(
                                        label: "Current",
                                        value: currentWeightDisplay(for: member),
                                        accentColor: AppColors.accentBlue
                                    )
                                    MetricCard(
                                        label: "Goal",
                                        value: goalDisplayText(member.goal),
                                        accentColor: AppColors.accentLavender
                                    )
                                    MetricCard(
                                        label: "Daily calories",
                                        value: dailyCaloriesDisplay(for: member),
                                        accentColor: AppColors.accentOrange
                                    )
                                }

                                NavigationLink {
                                    WeightProgressView(viewModel: viewModel)
                                } label: {
                                    PrimaryCard {
                                        HStack(spacing: AppSpacing.base) {
                                            Image(systemName: "chart.xyaxis.line")
                                                .font(.title3)
                                                .foregroundStyle(AppColors.accentLavender)
                                                .frame(width: 32)

                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("Weight Progress")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundStyle(AppColors.textPrimary)
                                                Text(weightProgressSubtitle(for: member))
                                                    .font(.caption)
                                                    .foregroundStyle(AppColors.textSecondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)

                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(AppColors.textTertiary)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                // Referral & points card
                                if let overview = viewModel.referralOverview {
                                    ReferralPointsCard(overview: overview, onShare: shareInvite)
                                }

                                // Quick actions
                                PrimaryCard {
                                    VStack(spacing: 0) {
                                        NavigationLink {
                                            EditProfileView(viewModel: viewModel)
                                        } label: {
                                            ListRow(
                                                icon: "pencil",
                                                title: "Edit Profile",
                                                subtitle: "Name, image, weight, goal",
                                                contentOnly: true
                                            )
                                        }
                                        .buttonStyle(.plain)

                                        Rectangle()
                                            .fill(AppColors.borderSubtle)
                                            .frame(height: 1)
                                            .padding(.horizontal, AppSpacing.base)

                                        NavigationLink {
                                            WeightProgressView(viewModel: viewModel)
                                        } label: {
                                            ListRow(
                                                icon: "chart.xyaxis.line",
                                                title: "Weight Progress",
                                                subtitle: "Log weight and view your graph",
                                                contentOnly: true
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else if let email = viewModel.userEmail {
                                // Fallback when no member linked
                                HStack(alignment: .top, spacing: AppSpacing.base) {
                                    ProfileAvatarView(avatarUrl: nil)
                                        .frame(width: 80, height: 80)
                                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                        Text("Signed in as")
                                            .font(.system(size: 14))
                                            .foregroundStyle(AppColors.textSecondary)
                                        Text(email)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundStyle(AppColors.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, AppSpacing.base)
                            }

                            Button("Sign Out") {
                                Task {
                                    await viewModel.signOut()
                                    onSignOut()
                                }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(AppColors.accentLavender)
                            .frame(maxWidth: .infinity)
                            .padding(.top, AppSpacing.lg)
                        }
                        .padding(AppSpacing.base)
                    }
                    .refreshable {
                        await viewModel.refreshProfile()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.canvas)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isLoading)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(item: $shareText) { item in
            ActivityView(activityItems: [item.text])
        }
    }
}

private struct ShareText: Identifiable {
    let id = UUID()
    let text: String
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Profile loading (skeleton matching content)

private struct ProfileLoadingView: View {
    private let metricColumns = [
        GridItem(.flexible(), spacing: AppSpacing.sm),
        GridItem(.flexible(), spacing: AppSpacing.sm)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                HStack(alignment: .top, spacing: AppSpacing.base) {
                    SkeletonView(width: 80, height: 80)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        SkeletonView(height: 20)
                            .frame(width: 160)
                        SkeletonView(height: 14)
                            .frame(width: 200)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    HStack(spacing: AppSpacing.sm) {
                        SkeletonView(width: 36, height: 36)
                            .clipShape(Circle())
                        SkeletonView(width: 36, height: 36)
                            .clipShape(Circle())
                    }
                }
                .padding(.vertical, AppSpacing.base)

                LazyVGrid(columns: metricColumns, spacing: AppSpacing.sm) {
                    ForEach(0..<4, id: \.self) { _ in
                        SkeletonView()
                            .frame(height: 72)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                }

                PrimaryCard {
                    HStack(spacing: AppSpacing.base) {
                        SkeletonView(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                        VStack(alignment: .leading, spacing: 4) {
                            SkeletonView(height: 16)
                                .frame(width: 130)
                            SkeletonView(height: 12)
                                .frame(width: 200)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        SkeletonView(width: 12, height: 14)
                    }
                }

                PrimaryCard {
                    VStack(spacing: 0) {
                        HStack(spacing: AppSpacing.base) {
                            SkeletonView(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 4) {
                                SkeletonView(height: 14)
                                    .frame(width: 100)
                                SkeletonView(height: 12)
                                    .frame(width: 160)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, AppSpacing.md)
                        Rectangle()
                            .fill(AppColors.borderSubtle)
                            .frame(height: 1)
                            .padding(.horizontal, AppSpacing.base)
                        HStack(spacing: AppSpacing.base) {
                            SkeletonView(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 4) {
                                SkeletonView(height: 14)
                                    .frame(width: 110)
                                SkeletonView(height: 12)
                                    .frame(width: 180)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, AppSpacing.md)
                    }
                }

                SkeletonView(height: 44)
                    .frame(width: 120)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
                    .padding(.top, AppSpacing.lg)
            }
            .padding(AppSpacing.base)
        }
    }
}

// MARK: - Referral & Points Card

private struct ReferralPointsCard: View {
    let overview: MemberReferralOverview
    let onShare: () -> Void

    private var pointsText: String {
        "\(overview.pointsBalance) pts"
    }

    private var subtitleText: String {
        guard overview.moneyValueMajor > 0 else {
            return "Earn points by referring friends."
        }
        return "Approx. \(overview.moneyValueDisplay) available toward your membership."
    }

    var body: some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Referral & Rewards")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                        Text(subtitleText)
                            .font(.system(size: 13))
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(pointsText)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppColors.accentLavender)
                        if let code = overview.referralCode, !code.isEmpty {
                            Text("Code: \(code)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }
                }

                HStack {
                    Button(action: onShare) {
                        Label("Invite a friend", systemImage: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .tint(AppColors.accentLavender)
                    Spacer()
                }
                .padding(.top, AppSpacing.sm)
            }
        }
    }
}

// MARK: - Profile Avatar

private struct ProfileAvatarView: View {
    let avatarUrl: String?

    var body: some View {
        Group {
            if let urlString = avatarUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure, .empty:
                        avatarPlaceholder
                    @unknown default:
                        avatarPlaceholder
                    }
                }
            } else {
                avatarPlaceholder
            }
        }
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(AppColors.borderSubtle, lineWidth: 1)
        )
    }

    private var avatarPlaceholder: some View {
        Circle()
            .fill(AppColors.accentLavender.opacity(0.3))
            .overlay {
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundStyle(AppColors.accentLavender)
            }
    }
}
