//
//  BodyMuscleView.swift
//  SmartGym
//

import SwiftUI

struct BodyMuscleView: View {
    typealias MuscleId = Exercise.MuscleId

    let trainedMuscles: [MuscleId: Int]

    /// Maps app heatmap keys (chest, quads, back, …) to body-path slugs and assigns intensity 1–3.
    private static func trainedMusclesToBodyHighlighterMuscles(_ trained: [MuscleId: Int]) -> [BodyMuscleData] {
        typealias Slug = String
        let maxCount = trained.values.max() ?? 1
        func intensity(for count: Int) -> Int {
            guard maxCount > 0 else { return 1 }
            let r = Double(count) / Double(maxCount)
            if r >= 2.0 / 3.0 { return 3 }
            if r >= 1.0 / 3.0 { return 2 }
            return 1
        }
        var bySlug: [Slug: Int] = [:]
        let map: [(MuscleId, [Slug])] = [
            ("chest", ["chest"]),
            ("quads", ["quadriceps"]),
            ("back", ["upper-back", "lower-back"]),
            ("shoulders", ["deltoids", "trapezius"]),
            ("core", ["abs", "obliques"]),
            ("glutes", ["gluteal"]),
            ("hamstrings", ["hamstring"]),
            ("calves", ["calves"]),
            ("biceps", ["biceps"]),
            ("triceps", ["triceps"]),
        ]
        for (key, slugs) in map {
            guard let count = trained[key], count > 0 else { continue }
            let level = intensity(for: count)
            for slug in slugs {
                bySlug[slug] = max(bySlug[slug] ?? 0, level)
            }
        }
        return bySlug.map { BodyMuscleData(slug: $0.key, intensity: $0.value) }
    }

    /// Heatmap: no hits → gray; low→high intensity → yellow → orange → red.
    private func heatmapColor(for muscle: MuscleId) -> Color {
        guard let hits = trainedMuscles[muscle], hits > 0 else {
            return AppColors.neutralDark.opacity(0.15)
        }
        let maxHits = trainedMuscles.values.max() ?? 1
        let intensity = maxHits > 0 ? Double(hits) / Double(maxHits) : 0
        let r = 1.0
        let g = 1.0 - intensity * 0.7
        let b = 0.4 - intensity * 0.4
        return Color(red: r, green: g, blue: b)
    }

    private var bodyHighlighterMuscles: [BodyMuscleData] {
        Self.trainedMusclesToBodyHighlighterMuscles(trainedMuscles)
    }

    private var hasPathData: Bool {
        // Temporarily disable SVG-based body paths on iOS while we debug
        // workout detail freezes; always use the simple placeholder view.
        return false
    }

    var body: some View {
        HStack(spacing: 40) {
            if hasPathData {
                BodyHighlighter(muscles: bodyHighlighterMuscles, side: .front, gender: .male)
                    .frame(maxWidth: .infinity)
                BodyHighlighter(muscles: bodyHighlighterMuscles, side: .back, gender: .male)
                    .frame(maxWidth: .infinity)
            } else {
                frontBody
                backBody
            }
        }
        .frame(height: 260)
    }

    private var frontBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(AppColors.neutralDark.opacity(0.1))
                .frame(width: 120, height: 220)

            // Front shoulders
            HStack {
                Capsule()
                    .fill(heatmapColor(for: "shoulders"))
                    .frame(width: 24, height: 32)
                Spacer().frame(width: 40)
                Capsule()
                    .fill(heatmapColor(for: "shoulders"))
                    .frame(width: 24, height: 32)
            }
            .frame(width: 120)
            .offset(y: -60)

            // Chest
            RoundedRectangle(cornerRadius: 16)
                .fill(heatmapColor(for: "chest"))
                .frame(width: 80, height: 40)
                .offset(y: -40)

            // Front arms (biceps)
            HStack {
                Capsule()
                    .fill(heatmapColor(for: "biceps"))
                    .frame(width: 20, height: 60)
                Spacer().frame(width: 60)
                Capsule()
                    .fill(heatmapColor(for: "biceps"))
                    .frame(width: 20, height: 60)
            }
            .frame(width: 120)
            .offset(y: -10)

            // Core
            RoundedRectangle(cornerRadius: 12)
                .fill(heatmapColor(for: "core"))
                .frame(width: 60, height: 50)
                .offset(y: 0)

            // Quads
            HStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(heatmapColor(for: "quads"))
                    .frame(width: 26, height: 70)
                Spacer().frame(width: 20)
                RoundedRectangle(cornerRadius: 12)
                    .fill(heatmapColor(for: "quads"))
                    .frame(width: 26, height: 70)
            }
            .frame(width: 120)
            .offset(y: 60)

            // Calves
            HStack {
                Capsule()
                    .fill(heatmapColor(for: "calves"))
                    .frame(width: 18, height: 40)
                Spacer().frame(width: 40)
                Capsule()
                    .fill(heatmapColor(for: "calves"))
                    .frame(width: 18, height: 40)
            }
            .frame(width: 120)
            .offset(y: 110)
        }
        .frame(width: 160, height: 260)
    }

    private var backBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 40)
                .fill(AppColors.neutralDark.opacity(0.1))
                .frame(width: 120, height: 220)

            // Rear shoulders
            HStack {
                Capsule()
                    .fill(heatmapColor(for: "shoulders"))
                    .frame(width: 24, height: 32)
                Spacer().frame(width: 40)
                Capsule()
                    .fill(heatmapColor(for: "shoulders"))
                    .frame(width: 24, height: 32)
            }
            .frame(width: 120)
            .offset(y: -60)

            // Upper back / lats (approximate)
            RoundedRectangle(cornerRadius: 16)
                .fill(heatmapColor(for: "back"))
                .frame(width: 80, height: 40)
                .offset(y: -35)

            // Triceps (back of arms)
            HStack {
                Capsule()
                    .fill(heatmapColor(for: "triceps"))
                    .frame(width: 20, height: 60)
                Spacer().frame(width: 60)
                Capsule()
                    .fill(heatmapColor(for: "triceps"))
                    .frame(width: 20, height: 60)
            }
            .frame(width: 120)
            .offset(y: -5)

            // Glutes
            RoundedRectangle(cornerRadius: 18)
                .fill(heatmapColor(for: "glutes"))
                .frame(width: 70, height: 40)
                .offset(y: 40)

            // Hamstrings (back of thighs)
            HStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(heatmapColor(for: "hamstrings"))
                    .frame(width: 26, height: 70)
                Spacer().frame(width: 20)
                RoundedRectangle(cornerRadius: 12)
                    .fill(heatmapColor(for: "hamstrings"))
                    .frame(width: 26, height: 70)
            }
            .frame(width: 120)
            .offset(y: 65)

            // Calves (back)
            HStack {
                Capsule()
                    .fill(heatmapColor(for: "calves"))
                    .frame(width: 18, height: 40)
                Spacer().frame(width: 40)
                Capsule()
                    .fill(heatmapColor(for: "calves"))
                    .frame(width: 18, height: 40)
            }
            .frame(width: 120)
            .offset(y: 115)
        }
        .frame(width: 160, height: 260)
    }
}

