//
//  BodyMuscleView.swift
//  SmartGym
//

import SwiftUI

struct BodyMuscleView: View {
    typealias MuscleId = Exercise.MuscleId

    let trainedMuscles: [MuscleId: Int]

    private func color(for muscle: MuscleId) -> Color {
        trainedMuscles[muscle] != nil ? AppColors.accentLavender : AppColors.neutralDark.opacity(0.2)
    }

    var body: some View {
        ZStack {
            // Simple abstract body: torso and limbs composed from rounded rectangles.
            RoundedRectangle(cornerRadius: 40)
                .fill(AppColors.neutralDark.opacity(0.1))
                .frame(width: 120, height: 220)

            // Chest / upper body
            RoundedRectangle(cornerRadius: 16)
                .fill(color(for: "chest"))
                .frame(width: 80, height: 40)
                .offset(y: -40)

            // Shoulders
            HStack {
                Capsule()
                    .fill(color(for: "shoulders"))
                    .frame(width: 24, height: 32)
                Spacer().frame(width: 40)
                Capsule()
                    .fill(color(for: "shoulders"))
                    .frame(width: 24, height: 32)
            }
            .frame(width: 120)
            .offset(y: -60)

            // Arms (biceps/triceps combined)
            HStack {
                Capsule()
                    .fill(color(for: "biceps"))
                    .frame(width: 20, height: 60)
                Spacer().frame(width: 60)
                Capsule()
                    .fill(color(for: "biceps"))
                    .frame(width: 20, height: 60)
            }
            .frame(width: 120)
            .offset(y: -10)

            // Core
            RoundedRectangle(cornerRadius: 12)
                .fill(color(for: "core"))
                .frame(width: 60, height: 50)
                .offset(y: 0)

            // Quads
            HStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color(for: "quads"))
                    .frame(width: 26, height: 70)
                Spacer().frame(width: 20)
                RoundedRectangle(cornerRadius: 12)
                    .fill(color(for: "quads"))
                    .frame(width: 26, height: 70)
            }
            .frame(width: 120)
            .offset(y: 60)

            // Calves
            HStack {
                Capsule()
                    .fill(color(for: "calves"))
                    .frame(width: 18, height: 40)
                Spacer().frame(width: 40)
                Capsule()
                    .fill(color(for: "calves"))
                    .frame(width: 18, height: 40)
            }
            .frame(width: 120)
            .offset(y: 110)
        }
        .frame(width: 160, height: 260)
    }
}

