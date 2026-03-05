//
//  SettingsView.swift
//  SmartGym
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weeklyGoal: Int = 3
    @State private var workoutDaysGoal: Int = 4

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)

                PrimaryCard {
                    VStack(alignment: .leading, spacing: AppSpacing.base) {
                        Text("Weekly Workout Goal")
                            .font(.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        Stepper("\(weeklyGoal) days per week", value: $weeklyGoal, in: 1...7)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }

                PrimaryCard {
                    VStack(alignment: .leading, spacing: AppSpacing.base) {
                        Text("Weekly Workout Days Goal")
                            .font(.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        Stepper("\(workoutDaysGoal) days", value: $workoutDaysGoal, in: 1...7)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                }

                PrimaryCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Working Goal")
                            .font(.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("Set your fitness goals – coming soon")
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .padding(AppSpacing.base)
        }
        .background(AppColors.canvas)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
