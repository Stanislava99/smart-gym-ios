//
//  WorkoutsViewModel.swift
//  SmartGym
//

import Foundation

@MainActor
@Observable
final class WorkoutsViewModel {
    var workouts: [MemberWorkout] = []
    var isLoading = true
    var error: String?

    private let memberRepository = MemberRepository()
    private let workoutRepository = WorkoutRepository()
    private let exerciseService = ExerciseService.shared

    struct NewWorkoutSet {
        var setNumber: Int
        var reps: Int?
        var weight: Double?
    }

    struct NewWorkoutExercise: Identifiable {
        let id = UUID()
        let externalSource: String
        let externalExerciseId: String
        let name: String
        let bodyPart: String?
        let targetMuscle: String?
        let equipment: String?
        var sets: [NewWorkoutSet]
    }

    var newWorkoutExercises: [NewWorkoutExercise] = []
    var searchResults: [Exercise] = []
    var isSearchingExercises = false

    init() {
        Task { await loadWorkouts() }
    }

    func loadWorkouts() async {
        isLoading = true
        error = nil
        do {
            guard let member = try await memberRepository.getCurrentMember() else {
                workouts = []
                isLoading = false
                return
            }
            let rows = try await workoutRepository.getWorkouts(memberId: member.id)
            workouts = rows
            isLoading = false
        } catch {
            workouts = []
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    func addWorkout(title: String, workoutDate: String, notes: String?) async {
        do {
            guard let member = try await memberRepository.getCurrentMember() else { return }
            let workout = try await workoutRepository.addWorkout(
                memberId: member.id,
                title: title,
                workoutDate: workoutDate,
                notes: notes
            )
            if !newWorkoutExercises.isEmpty {
                let mappedExercises: [WorkoutRepository.NewWorkoutExercise] = newWorkoutExercises.map { exercise in
                    let sets: [WorkoutRepository.NewWorkoutSet] = exercise.sets.map { set in
                        WorkoutRepository.NewWorkoutSet(
                            setNumber: set.setNumber,
                            reps: set.reps,
                            weight: set.weight
                        )
                    }
                    return WorkoutRepository.NewWorkoutExercise(
                        externalSource: exercise.externalSource,
                        externalExerciseId: exercise.externalExerciseId,
                        name: exercise.name,
                        bodyPart: exercise.bodyPart,
                        targetMuscle: exercise.targetMuscle,
                        equipment: exercise.equipment,
                        sets: sets
                    )
                }
                try await workoutRepository.addExercisesAndSets(
                    workoutId: workout.id,
                    exercises: mappedExercises
                )
            }
            await loadWorkouts()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func clearNewWorkoutExercises() {
        newWorkoutExercises = []
    }

    func addExerciseFromSearch(_ exercise: Exercise) {
        let new = NewWorkoutExercise(
            externalSource: "local_gym_db",
            externalExerciseId: exercise.id,
            name: exercise.name,
            bodyPart: exercise.category,
            targetMuscle: exercise.primaryMuscles.first,
            equipment: exercise.equipment,
            sets: [NewWorkoutSet(setNumber: 1, reps: nil, weight: nil)]
        )
        newWorkoutExercises.append(new)
    }

    func searchExercises(query: String) async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearchingExercises = false
            return
        }
        isSearchingExercises = true
        // ExerciseService is kept up to date at app start; search is synchronous on in-memory data.
        searchResults = exerciseService.searchByName(query)
        isSearchingExercises = false
    }
}

