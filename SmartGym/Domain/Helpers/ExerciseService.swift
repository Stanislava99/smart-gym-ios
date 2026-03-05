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
        guard !isLoaded else { return }
        do {
            let catalog = try ExerciseJsonLoader.loadCatalog()
            exercises = catalog.exercises
            isLoaded = true
            print("ExerciseService: loaded \(exercises.count) exercises into memory")
        } catch {
            // In this first iteration we only log; callers will see empty results.
            print("ExerciseService load error:", error)
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

    func computeTrainedMuscles(forExerciseIds ids: [String]) -> [MuscleId: Int] {
        var counts: [MuscleId: Int] = [:]
        let lookup = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        for id in ids {
            guard let exercise = lookup[id] else { continue }
            for muscle in exercise.primaryMuscles {
                counts[muscle, default: 0] += 1
            }
        }
        return counts
    }
}

