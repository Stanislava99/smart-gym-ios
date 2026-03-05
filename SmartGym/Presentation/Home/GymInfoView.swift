//
//  GymInfoView.swift
//  SmartGym
//
//  Full gym profile: logo, name, location, contact, plans, trainers with packages.
//  DESIGN_SYSTEM_PROFILE.md: card-based layout, accent colors, rounded corners
//

import SwiftUI
import UIKit

struct GymInfoView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = GymInfoViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                        if let gym = viewModel.gym {
                            // Hero: logo centered, name below (no card)
                            gymHeroSection(gym: gym)
                            Divider()
                                .background(AppColors.borderSubtle.opacity(0.6))
                                .padding(.vertical, AppSpacing.sm)

                            // Contact: location, phone, website
                            contactSection(gym: gym)

                            // Plans for payment
                            if !viewModel.plans.isEmpty {
                                plansSection(plans: viewModel.plans)
                            }

                            // Personal trainers with packages
                            if !viewModel.trainers.isEmpty || !viewModel.ptPackages.isEmpty {
                                trainersSection(
                                    trainers: viewModel.trainers,
                                    packages: viewModel.ptPackages
                                )
                            }
                        } else {
                            PrimaryCard {
                                Text("No gym info available")
                                    .font(.body)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(AppSpacing.base)
                }
            }
        }
        .background(AppColors.canvas)
        .navigationTitle("Gym Profile")
        .navigationBarTitleDisplayMode(.inline)

    }

    private func gymHeroSection(gym: Gym) -> some View {
        VStack(spacing: AppSpacing.lg) {
            // Logo centered
            Group {
                let urlString = viewModel.resolvedLogoUrl ?? gym.logoUrl
                if let urlString = urlString, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            placeholderLogo
                        case .empty:
                            placeholderLogo
                        @unknown default:
                            placeholderLogo
                        }
                    }
                } else {
                    placeholderLogo
                }
            }
            .frame(width: 96, height: 96)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(AppColors.borderSubtle.opacity(0.5), lineWidth: 1)
            )

            // Gym name below
            VStack(spacing: AppSpacing.xs) {
                Text(gym.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
                if let tagline = gym.tagline, !tagline.isEmpty {
                    Text(tagline)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xxl)
    }

    private var placeholderLogo: some View {
        Image(systemName: "dumbbell.fill")
            .font(.system(size: 40))
            .foregroundStyle(AppColors.accentLavender.opacity(0.6))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func contactSection(gym: Gym) -> some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Contact")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppColors.textPrimary)

                if let address = gym.address, !address.isEmpty {
                    tappableContactRow(icon: "location.fill", text: address) {
                        let query = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "gym"
                        if let url = URL(string: "https://maps.apple.com/?q=\(query)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                if let phone = gym.phone, !phone.isEmpty {
                    tappableContactRow(icon: "phone.fill", text: phone) {
                        let cleaned = phone.filter { $0.isNumber || $0 == "+" }
                        if let url = URL(string: "tel:\(cleaned)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                if let website = gym.website, !website.isEmpty {
                    tappableContactRow(icon: "globe", text: website) {
                        var urlString = website
                        if !urlString.hasPrefix("http") { urlString = "https://\(urlString)" }
                        if let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                if (gym.address?.isEmpty ?? true) && (gym.phone?.isEmpty ?? true) && (gym.website?.isEmpty ?? true) {
                    Text("No contact info available")
                        .font(.body)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
        }
    }

    private func contactRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.accentLavender)
                .frame(width: 20, alignment: .center)
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func tappableContactRow(icon: String, text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.accentLavender)
                    .frame(width: 20, alignment: .center)
                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AppColors.accentLavender)
                    .underline()
                Spacer(minLength: 0)
            }
        }
        .buttonStyle(.plain)
    }

    private func plansSection(plans: [Plan]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Plans")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            ForEach(plans, id: \.id) { plan in
                FeatureCard(
                    title: plan.title,
                    subtitle: planSubtitle(plan),
                    accentColor: AppColors.accentBlue
                )
            }
        }
    }

    private func planSubtitle(_ plan: Plan) -> String {
        var parts: [String] = []
        if plan.durationDays > 0 {
            parts.append("\(plan.durationDays) days")
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        if let priceStr = formatter.string(from: NSNumber(value: plan.price)) {
            parts.append("\(priceStr)")
        }
        return parts.joined(separator: " • ")
    }

    private func trainersSection(trainers: [PTTrainer], packages: [PTPackage]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Personal Training")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            ForEach(trainers, id: \.id) { trainer in
                PrimaryCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(trainer.fullName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppColors.textPrimary)
                        if let phone = trainer.phone, !phone.isEmpty {
                            contactRow(icon: "phone.fill", text: phone)
                        }
                        if let email = trainer.email, !email.isEmpty {
                            contactRow(icon: "envelope.fill", text: email)
                        }
                    }
                }
            }

            if !packages.isEmpty {
                Text("PT Packages")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.textSecondary)
                    .padding(.top, AppSpacing.xs)
                ForEach(packages, id: \.id) { pkg in
                    FeatureCard(
                        title: pkg.name,
                        subtitle: "\(pkg.sessionsCount) sessions • \(formatPrice(pkg.price))",
                        accentColor: AppColors.accentOrange
                    )
                }
            }
        }
    }

    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: price)) ?? "\(price)"
    }
}
