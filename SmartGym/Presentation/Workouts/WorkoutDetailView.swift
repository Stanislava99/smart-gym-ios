//
//  WorkoutDetailView.swift
//  SmartGym
//

import SwiftUI

struct WorkoutDetailView: View {
    let workoutId: String
    @Environment(\.dismiss) private var dismiss
    @State private var trainedMuscles: [Exercise.MuscleId: Int] = [:]
    private let workoutRepository = WorkoutRepository()
    private let exerciseService = ExerciseService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.cardGap) {
                if !trainedMuscles.isEmpty {
                    PrimaryCard {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("Muscles trained")
                                .font(.headline)
                                .foregroundStyle(AppColors.textPrimary)
                            BodyMuscleView(trainedMuscles: trainedMuscles)
                        }
                    }
                }

                PrimaryCard {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Workout Details")
                            .font(.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("Workout \(workoutId) – coming soon")
                            .font(.body)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .padding(AppSpacing.base)
        }
        .background(AppColors.canvas)
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back") { dismiss() }
                    .foregroundStyle(AppColors.accentLavender)
            }
        }
        .task {
            await ExerciseService.shared.loadIfNeeded()
            let ids = await workoutRepository.getExerciseExternalIds(forWorkoutId: workoutId)
            let muscles = exerciseService.computeTrainedMuscles(forExerciseIds: ids)
            trainedMuscles = muscles
        }
    }
}
