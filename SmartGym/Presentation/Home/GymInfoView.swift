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
    @State private var viewModel = GymInfoViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    GymInfoLoadingView()
                } else if let error = viewModel.error {
                    ErrorWithRetryView(message: error) {
                        Task { await viewModel.load() }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                            if let gym = viewModel.gym {
                                gymHeroSection(gym: gym)

                                gymStatsSection(
                                    plansCount: viewModel.plans.count,
                                    groupsCount: viewModel.groupTrainings.count,
                                    trainersCount: viewModel.trainers.count
                                )

                                contactSection(gym: gym)

                                membershipsSection(plans: viewModel.plans)

                                trainingOptionsSection(
                                    groups: viewModel.groupTrainings,
                                    packages: viewModel.ptPackages
                                )

                                personnelSection(trainers: viewModel.trainers)

                                workingHoursSection(hours: viewModel.workingHours)
                            } else {
                                PrimaryCard {
                                    Text("No gym info available")
                                        .font(.body)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.vertical, AppSpacing.screenVertical)
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.canvas)
            .navigationTitle("Gym")
            .navigationBarTitleDisplayMode(.inline)
            .animation(.easeInOut(duration: 0.25), value: viewModel.isLoading)
        }
    }

    // MARK: - Loading (skeleton matching content)

    private struct GymInfoLoadingView: View {
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                    heroSkeleton
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonView(height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                    }
                    PrimaryCard {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            SkeletonView(height: 18)
                                .frame(width: 80)
                            SkeletonView(height: 14)
                                .frame(maxWidth: .infinity)
                            SkeletonView(height: 14)
                                .frame(width: 220)
                            SkeletonView(height: 14)
                                .frame(width: 140)
                        }
                    }
                    ForEach(0..<2, id: \.self) { _ in
                        PrimaryCard {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                SkeletonView(height: 18)
                                    .frame(width: 150)
                                SkeletonView(height: 14)
                                    .frame(maxWidth: .infinity)
                                SkeletonView(height: 14)
                                    .frame(width: 180)
                            }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.vertical, AppSpacing.screenVertical)
            }
        }

        /// Mirrors `gymHeroSection`: lavender hero card with circular logo and title lines.
        private var heroSkeleton: some View {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .fill(AppColors.accentLavender)
                    .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)

                Circle()
                    .fill(AppColors.surface.opacity(0.22))
                    .frame(width: 120, height: 120)
                    .offset(x: 36, y: -44)

                HStack(alignment: .center, spacing: AppSpacing.base) {
                    Circle()
                        .fill(Color.white.opacity(0.38))
                        .frame(width: 76, height: 76)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 200, height: 26)
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(Color.white.opacity(0.38))
                            .frame(width: 160, height: 15)
                    }

                    Spacer(minLength: 0)
                }
                .padding(AppSpacing.lg)
            }
            .frame(minHeight: 148)
        }
    }

    private func gymHeroSection(gym: Gym) -> some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(AppColors.accentLavender)
                .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)

            Circle()
                .fill(AppColors.surface.opacity(0.22))
                .frame(width: 120, height: 120)
                .offset(x: 36, y: -44)

            HStack(alignment: .center, spacing: AppSpacing.base) {
                Group {
                    let urlString = viewModel.resolvedLogoUrl ?? gym.logoUrl
                    if let urlString = urlString, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                placeholderLogo
                            }
                        }
                    } else {
                        placeholderLogo
                    }
                }
                .frame(width: 76, height: 76)
                .background(AppColors.surface.opacity(0.9))
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(gym.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppColors.surface)
                    Text(gym.tagline?.isEmpty == false ? gym.tagline! : "Your fitness space")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppColors.surface.opacity(0.86))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .padding(AppSpacing.lg)
        }
        .frame(minHeight: 148)
    }

    private var placeholderLogo: some View {
        Image(systemName: "dumbbell.fill")
            .font(.system(size: 40))
            .foregroundStyle(AppColors.accentLavender.opacity(0.6))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func gymStatsSection(plansCount: Int, groupsCount: Int, trainersCount: Int) -> some View {
        HStack(spacing: AppSpacing.sm) {
            gymStatCard(value: "\(plansCount)", label: "Plans", color: AppColors.accentBlue)
            gymStatCard(value: "\(groupsCount)", label: "Groups", color: AppColors.accentMint)
            gymStatCard(value: "\(trainersCount)", label: "Trainers", color: AppColors.accentOrange)
        }
    }

    private func gymStatCard(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppColors.surface)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(AppColors.surface.opacity(0.9))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.base)
        .background(color)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
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

    private func membershipsSection(plans: [Plan]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader(title: "Memberships", subtitle: "Monthly and recurring access plans")

            if plans.isEmpty {
                emptyInfoCard("No subscription plans are available yet.")
            } else {
                ForEach(plans, id: \.id) { plan in
                    PrimaryCard {
                        HStack(alignment: .center, spacing: AppSpacing.base) {
                            iconBadge(systemName: "creditcard.fill", color: AppColors.accentBlue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plan.title)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(AppColors.textPrimary)
                                Text(planSubtitle(plan))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            Spacer(minLength: 0)
                            Text(formatPrice(plan.price))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }
                }
            }
        }
    }

    private func trainingOptionsSection(groups: [GroupTraining], packages: [PTPackage]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader(title: "Training options", subtitle: "Choose classes or personal coaching")

            if groups.isEmpty && packages.isEmpty {
                emptyInfoCard("No group or personal training options are available yet.")
            } else {
                if !groups.isEmpty {
                    optionGroupCard(
                        title: "Group training",
                        subtitle: "\(groups.count) recurring option\(groups.count == 1 ? "" : "s")",
                        color: AppColors.accentMint,
                        icon: "person.3.fill"
                    ) {
                        ForEach(groups) { group in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(group.title)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(AppColors.textPrimary)
                                    Spacer()
                                    Text(formatPrice(group.price))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                Text(group.trainerName.map { "Trainer: \($0)" } ?? "Trainer: TBA")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(AppColors.textSecondary)
                                if !group.slots.isEmpty {
                                    Text(group.slots.map(formatGroupSlot).joined(separator: " • "))
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundStyle(AppColors.textTertiary)
                                        .lineLimit(2)
                                }
                            }
                            if group.id != groups.last?.id {
                                Divider().background(AppColors.borderSubtle)
                            }
                        }
                    }
                }

                if !packages.isEmpty {
                    optionGroupCard(
                        title: "Personal training",
                        subtitle: "\(packages.count) package\(packages.count == 1 ? "" : "s")",
                        color: AppColors.accentOrange,
                        icon: "figure.strengthtraining.traditional"
                    ) {
                        ForEach(packages, id: \.id) { package in
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(package.name)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(AppColors.textPrimary)
                                    Text("\(package.sessionsCount) sessions")
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                Spacer()
                                Text(formatPrice(package.price))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            if package.id != packages.last?.id {
                                Divider().background(AppColors.borderSubtle)
                            }
                        }
                    }
                }
            }
        }
    }

    private func personnelSection(trainers: [PTTrainer]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader(title: "Personnel", subtitle: "Trainers available at this gym")

            if trainers.isEmpty {
                emptyInfoCard("No trainers are listed yet.")
            } else {
                PrimaryCard {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(trainers, id: \.id) { trainer in
                            HStack(spacing: AppSpacing.sm) {
                                iconBadge(systemName: "person.fill", color: AppColors.accentLavender)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(trainer.fullName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(AppColors.textPrimary)
                                    Text([trainer.phone, trainer.email].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " • "))
                                        .font(.system(size: 12, weight: .regular))
                                        .foregroundStyle(AppColors.textSecondary)
                                }
                                Spacer(minLength: 0)
                            }
                            if trainer.id != trainers.last?.id {
                                Divider().background(AppColors.borderSubtle)
                            }
                        }
                    }
                }
            }
        }
    }

    private func workingHoursSection(hours: [GymWorkingHours]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            sectionHeader(title: "Working hours", subtitle: "When the gym is open")

            if hours.isEmpty {
                emptyInfoCard("Working hours have not been added yet.")
            } else {
                PrimaryCard {
                    VStack(spacing: AppSpacing.sm) {
                        ForEach(sortedWorkingHours(hours), id: \.dayOfWeek) { item in
                            HStack {
                                Text(workingDayName(item.dayOfWeek))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                Text(workingHoursText(item))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(item.isClosed ? AppColors.textTertiary : AppColors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            Text(subtitle)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    private func optionGroupCard<Content: View>(
        title: String,
        subtitle: String,
        color: Color,
        icon: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        PrimaryCard {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                HStack(spacing: AppSpacing.sm) {
                    iconBadge(systemName: icon, color: color)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppColors.textPrimary)
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                VStack(alignment: .leading, spacing: AppSpacing.sm, content: content)
            }
        }
    }

    private func iconBadge(systemName: String, color: Color) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AppColors.textPrimary)
            .frame(width: 40, height: 40)
            .background(color.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
    }

    private func emptyInfoCard(_ message: String) -> some View {
        PrimaryCard {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func plansSection(plans: [Plan]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Plans")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            if plans.isEmpty {
                PrimaryCard {
                    Text("No plans are available at this gym yet.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(plans, id: \.id) { plan in
                    FeatureCard(
                        title: plan.title,
                        subtitle: planSubtitle(plan),
                        accentColor: AppColors.accentBlue
                    )
                }
            }
        }
    }

    private func groupTrainingsSection(groups: [GroupTraining]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Group Trainings")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)

            if groups.isEmpty {
                PrimaryCard {
                    Text("No group trainings are available at this gym yet.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ForEach(groups) { group in
                    PrimaryCard {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            HStack(alignment: .firstTextBaseline) {
                                Text(group.title)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(AppColors.textPrimary)
                                Spacer()
                                Text(formatPrice(group.price))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.accentLavender)
                            }
                            Text("Trainer: \(group.trainerName ?? "TBA")")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppColors.textSecondary)
                            if !group.slots.isEmpty {
                                Text(group.slots.map(formatGroupSlot).joined(separator: "\n"))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func formatGroupSlot(_ slot: GroupTrainingSlot) -> String {
        let start = String(slot.startTime.prefix(5))
        let end = slot.endTime.map { " - \(String($0.prefix(5)))" } ?? ""
        return "\(weekdayName(slot.weekday)) \(start)\(end)"
    }

    private func weekdayName(_ weekday: Int) -> String {
        switch weekday {
        case 0: return "Sunday"
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        case 5: return "Friday"
        case 6: return "Saturday"
        default: return "Day \(weekday)"
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

    private func sortedWorkingHours(_ hours: [GymWorkingHours]) -> [GymWorkingHours] {
        hours.sorted { $0.dayOfWeek < $1.dayOfWeek }
    }

    private func workingDayName(_ day: Int) -> String {
        switch day {
        case 1: return "Monday"
        case 2: return "Tuesday"
        case 3: return "Wednesday"
        case 4: return "Thursday"
        case 5: return "Friday"
        case 6: return "Saturday"
        case 7: return "Sunday"
        default: return "Day \(day)"
        }
    }

    private func workingHoursText(_ hours: GymWorkingHours) -> String {
        if hours.isClosed {
            return "Closed"
        }
        let open = hours.openTime.map { String($0.prefix(5)) } ?? "--:--"
        let close = hours.closeTime.map { String($0.prefix(5)) } ?? "--:--"
        return "\(open) - \(close)"
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
