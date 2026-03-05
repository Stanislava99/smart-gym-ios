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
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                            // Monthly strike summary
                            PrimaryCard {
                                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                    Text("Monthly Strike")
                                        .font(.headline)
                                        .foregroundStyle(AppColors.textPrimary)

                                    // Simple dots for now; can be wired to real per-day data later.
                                    HStack(spacing: AppSpacing.sm) {
                                        ForEach(0..<4, id: \.self) { _ in
                                            HStack(spacing: 4) {
                                                ForEach(0..<7, id: \.self) { _ in
                                                    Circle()
                                                        .fill(AppColors.accentMint)
                                                        .frame(width: 8, height: 8)
                                                }
                                            }
                                        }
                                    }

                                    Text("\(viewModel.workouts.count) workouts this month")
                                        .font(.caption)
                                        .foregroundStyle(AppColors.textSecondary)
                                }
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
                                        WorkoutDetailView(workoutId: workout.id)
                                    } label: {
                                        ListRow(
                                            icon: "figure.run",
                                            title: workout.title,
                                            subtitle: Self.formattedDate(workout.workoutDate),
                                            action: {}
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
