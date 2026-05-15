//
//  WorkoutsView.swift
//  SmartGym
//

import SwiftUI

struct WorkoutsView: View {
    @Bindable var viewModel: WorkoutsViewModel
    var onAddTapped: (() -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    WorkoutsLoadingView()
                } else if let error = viewModel.error {
                    ErrorWithRetryView(message: error) {
                        Task { await viewModel.loadWorkouts() }
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                            // Statistics: workouts this week, kgs this week, workouts this month
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                Text("Statistics")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.textPrimary)
                                HStack(spacing: AppSpacing.sm) {
                                    MetricCard(
                                        label: "Workouts this week",
                                        value: "\(viewModel.workoutsThisWeek)",
                                        accentColor: AppColors.accentMint
                                    )
                                    MetricCard(
                                        label: "Kgs lifted this week",
                                        value: String(format: "%.0f", viewModel.kgsLiftedThisWeek),
                                        accentColor: AppColors.accentBlue
                                    )
                                }
                                MetricCard(
                                    label: "Workouts this month",
                                    value: "\(viewModel.workoutsThisMonth)",
                                    accentColor: AppColors.accentLavender
                                )
                            }

                            // List of previous workouts -> Navigate to workout page
                            Text("Previous Workouts")
                                .font(.headline)
                                .foregroundStyle(AppColors.textPrimary)

                            if viewModel.workouts.isEmpty {
                                Text("No workouts yet. Tap + to add one.")
                                    .font(.body)
                                    .foregroundStyle(AppColors.textSecondary)
                            } else {
                                ForEach(viewModel.workouts, id: \.id) { workout in
                                    NavigationLink {
                                        WorkoutDetailView(
                                            workoutId: workout.id,
                                            onWorkoutDeleted: { viewModel.removeWorkout(id: workout.id) },
                                            onWorkoutUpdated: { viewModel.updateWorkoutInList($0) }
                                        )
                                    } label: {
                                        ListRow(
                                            icon: "figure.run",
                                            title: workout.title,
                                            subtitle: Self.formattedDate(workout.workoutDate),
                                            contentOnly: true
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(AppSpacing.base)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppColors.canvas)
            .toolbar {
                if let onAddTapped {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            onAddTapped()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Loading (skeleton matching content)

    private struct WorkoutsLoadingView: View {
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        SkeletonView(height: 18)
                            .frame(width: 100)
                        HStack(spacing: AppSpacing.sm) {
                            SkeletonView()
                                .frame(height: 72)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            SkeletonView()
                                .frame(height: 72)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                        }
                        SkeletonView()
                            .frame(height: 72)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    }
                    SkeletonView(height: 18)
                        .frame(width: 160)
                    ForEach(0..<4, id: \.self) { _ in
                        HStack(spacing: AppSpacing.base) {
                            SkeletonView(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            VStack(alignment: .leading, spacing: 4) {
                                SkeletonView(height: 14)
                                    .frame(width: 160)
                                SkeletonView(height: 12)
                                    .frame(width: 100)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, AppSpacing.md)
                        .padding(.horizontal, AppSpacing.base)
                    }
                }
                .padding(AppSpacing.base)
            }
        }
    }

    private static func formattedDate(_ isoDate: String) -> String {
        let isoFormatter = DateFormatter()
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = isoFormatter.date(from: isoDate) else { return isoDate }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        return displayFormatter.string(from: date)
    }
}
