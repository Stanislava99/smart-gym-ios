//
//  ExerciseService.swift
//  SmartGym
//

import Foundation

@MainActor
final class ExerciseService {
    typealias MuscleId = Exercise.MuscleId

    static let shared = ExerciseService()

    private(set) var exercises: [Exercise] = []
    private var isLoaded = false

    private init() {}

    func loadIfNeeded() async {
        guard !isLoaded else {
            return
        }
        do {
            let catalog = try ExerciseJsonLoader.loadCatalog()
            exercises = catalog.exercises
            isLoaded = true
        } catch {
            exercises = []
            isLoaded = true
        }
    }

    func searchByName(_ query: String) -> [Exercise] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("ExerciseService: empty search query, returning []")
            return []
        }
        let lowered = trimmed.lowercased()
        let results = exercises.filter { $0.name.lowercased().contains(lowered) }
        print("ExerciseService: searchByName(\"\(trimmed)\") -> \(results.count) results")
        return results
    }

    func getExercises(byPrimaryMuscle muscleId: MuscleId) -> [Exercise] {
        exercises.filter { $0.primaryMuscles.contains(muscleId) }
    }

    func getExercise(byId id: String) -> Exercise? {
        exercises.first { $0.id == id }
    }

    /// Maps exercise-DB muscle IDs to the body heatmap view's region IDs so all
    /// primary and secondary muscles show on the heatmap.
    private static func normalizedMuscleIdForHeatmap(_ raw: MuscleId) -> MuscleId {
        let map: [MuscleId: MuscleId] = [
            "upper_chest": "chest",
            "quadriceps": "quads",
            "lower_back": "back",
            "middle_back": "back",
            "lats": "back",
            "traps": "shoulders",
            "rear_shoulders": "shoulders",
            "forearms": "biceps",
        ]
        return map[raw] ?? raw
    }

    /// Counts primary and secondary muscles for the given exercise IDs. Primary muscles
    /// get weight 2 so they appear hotter on the heatmap; secondary get weight 1.
    /// Exercise-DB muscle IDs are normalized to the body view's regions (e.g. quadriceps → quads).
    func computeTrainedMuscles(forExerciseIds ids: [String]) -> [MuscleId: Int] {
        var counts: [MuscleId: Int] = [:]
        let lookup = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        for id in ids {
            guard let exercise = lookup[id] else { continue }
            for muscle in exercise.primaryMuscles {
                let key = Self.normalizedMuscleIdForHeatmap(muscle)
                counts[key, default: 0] += 2
            }
            for muscle in exercise.secondaryMuscles {
                let key = Self.normalizedMuscleIdForHeatmap(muscle)
                counts[key, default: 0] += 1
            }
        }
        return counts
    }
}

