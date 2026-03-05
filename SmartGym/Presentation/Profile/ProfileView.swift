//
//  ProfileView.swift
//  SmartGym
//
//  Profile screen - DESIGN_SYSTEM_PROFILE.md
//  Layout: avatar + name, metric cards (start weight, goal), edit profile, settings
//

import SwiftUI

struct ProfileView: View {
    @Bindable var viewModel: ProfileViewModel
    var onSignOut: () -> Void

    private func goalDisplayText(_ goal: String?) -> String {
        guard let g = goal, !g.isEmpty else { return "—" }
        if let num = Double(g.trimmingCharacters(in: .whitespaces)), num > 0 {
            return String(format: "%.1f kg", num)
        }
        return g
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                            // Native share of referral code handled via ShareLink button in Referral card below.
                                        } label: {
                                            Image(systemName: "square.and.arrow.up")
                                                .font(.body)
                                                .foregroundStyle(AppColors.textPrimary)
                                        }
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

                                // Metric cards: Start weight, Goal, Daily calories
                                HStack(spacing: AppSpacing.sm) {
                                    MetricCard(
                                        label: "Start weight",
                                        value: member.weightKg.map { String(format: "%.1f kg", $0) } ?? "—",
                                        accentColor: AppColors.accentMint
                                    )
                                    MetricCard(
                                        label: "Goal",
                                        value: goalDisplayText(member.goal),
                                        accentColor: AppColors.accentBlue
                                    )
                                    MetricCard(
                                        label: "Daily calories",
                                        value: "—",
                                        accentColor: AppColors.accentOrange
                                    )
                                }

                                // Referral & points card
                                if let overview = viewModel.referralOverview {
                                    ReferralPointsCard(overview: overview)
                                }

                                // Activity / settings list
                                PrimaryCard {
                                    VStack(spacing: 0) {
                                        NavigationLink {
                                            EditProfileView(viewModel: viewModel)
                                        } label: {
                                            ListRow(
                                                icon: "pencil",
                                                title: "Edit Profile",
                                                subtitle: "Name, image, weight, goal",
                                                action: {}
                                            )
                                        }
                                        .buttonStyle(.plain)

                                        Rectangle()
                                            .fill(AppColors.borderSubtle)
                                            .frame(height: 1)
                                            .padding(.horizontal, AppSpacing.base)

                                        NavigationLink {
                                            SettingsView()
                                        } label: {
                                            ListRow(
                                                icon: "gearshape",
                                                title: "Settings",
                                                subtitle: "Goals, preferences",
                                                action: {}
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

                                PrimaryCard {
                                    VStack(spacing: 0) {
                                        NavigationLink {
                                            SettingsView()
                                        } label: {
                                            ListRow(
                                                icon: "gearshape",
                                                title: "Settings",
                                                subtitle: "Goals, preferences",
                                                action: {}
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
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
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.canvas)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Referral & Points Card

private struct ReferralPointsCard: View {
    let overview: MemberReferralOverview

    private var pointsText: String {
        "\(overview.pointsBalance) pts"
    }

    private var subtitleText: String {
        guard overview.moneyValueMajor > 0 else {
            return "Earn points by referring friends."
        }
        return "Approx. \(overview.moneyValueDisplay) available toward your membership."
    }

    private var shareMessage: String {
        if let code = overview.referralCode, !code.isEmpty {
            return "Join me at Smart Gym! Use my referral code \(code) when signing up."
        }
        return "Join me at Smart Gym! Ask staff about the referral program."
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

                if overview.referralCode != nil {
                    HStack {
                        ShareLink(item: shareMessage) {
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
