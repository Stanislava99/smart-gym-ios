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

    /// Workouts count in the current week (calendar week).
    var workoutsThisWeek: Int = 0
    /// Total volume lifted this week (sum of reps × weight in kg).
    var kgsLiftedThisWeek: Double = 0
    /// Workouts count in the current month.
    var workoutsThisMonth: Int = 0

    private let memberRepository = MemberRepository()
    private let workoutRepository = WorkoutRepository()

    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    private let exerciseService = ExerciseService.shared

    struct NewWorkoutSet {
        var setNumber: Int
        var reps: Int?
        var weight: Double?
        var durationMinutes: Int? = nil
        var distanceKm: Double? = nil
        var stairsClimbed: Int? = nil
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
                workoutsThisWeek = 0
                kgsLiftedThisWeek = 0
                workoutsThisMonth = 0
                isLoading = false
                return
            }
            let calendar = Calendar.current
            let today = Date()
            let weekday = calendar.component(.weekday, from: today)
            let startOfWeek = calendar.date(
                byAdding: .day,
                value: -(weekday - calendar.firstWeekday),
                to: calendar.startOfDay(for: today)
            ) ?? today
            let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? today
            let fromWeek = Self.isoFormatter.string(from: startOfWeek)
            let toWeek = Self.isoFormatter.string(from: endOfWeek)

            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
            let range = calendar.range(of: .day, in: .month, for: today)
            let lastDay = range?.count ?? 30
            let endOfMonth = calendar.date(byAdding: .day, value: lastDay - 1, to: startOfMonth) ?? today
            let fromMonth = Self.isoFormatter.string(from: startOfMonth)
            let toMonth = Self.isoFormatter.string(from: endOfMonth)

            // Fetch all workout data in parallel instead of sequentially.
            async let allWorkoutsTask = try? workoutRepository.getWorkouts(memberId: member.id)
            async let weekWorkoutsTask = workoutRepository.getWorkoutsInRange(
                memberId: member.id,
                fromDate: fromWeek,
                toDate: toWeek
            )
            async let monthWorkoutsTask = workoutRepository.getWorkoutsInRange(
                memberId: member.id,
                fromDate: fromMonth,
                toDate: toMonth
            )
            async let volumeWeekTask = workoutRepository.getTotalVolumeLifted(
                memberId: member.id,
                fromDate: fromWeek,
                toDate: toWeek
            )

            let rows = await allWorkoutsTask ?? []
            let weekWorkouts = await weekWorkoutsTask
            let monthWorkouts = await monthWorkoutsTask
            let volumeWeek = await volumeWeekTask

            workouts = rows
            workoutsThisWeek = weekWorkouts.count
            kgsLiftedThisWeek = volumeWeek
            workoutsThisMonth = monthWorkouts.count
            isLoading = false
        } catch {
            workouts = []
            workoutsThisWeek = 0
            kgsLiftedThisWeek = 0
            workoutsThisMonth = 0
            isLoading = false
            self.error = error.localizedDescription
        }
    }

    func addWorkout(title: String, workoutDate: String, notes: String?) async throws -> MemberWorkout {
        guard let member = try await memberRepository.getCurrentMember() else {
            throw NSError(domain: "WorkoutsViewModel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing member"])
        }
        let workout = try await workoutRepository.addWorkout(
            memberId: member.id,
            title: title,
            workoutDate: workoutDate,
            notes: notes
        )
        do {
            if !newWorkoutExercises.isEmpty {
                let mappedExercises: [WorkoutRepository.NewWorkoutExercise] = newWorkoutExercises.map { exercise in
                    let sets: [WorkoutRepository.NewWorkoutSet] = exercise.sets.map { set in
                        WorkoutRepository.NewWorkoutSet(
                            setNumber: set.setNumber,
                            reps: set.reps,
                            weight: set.weight,
                            durationMinutes: set.durationMinutes,
                            distanceKm: set.distanceKm,
                            stairsClimbed: set.stairsClimbed
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
        return workout
    }

    /// Remove a workout from the list without refetching (e.g. after delete in detail).
    func removeWorkout(id: String) {
        workouts.removeAll { $0.id == id }
    }

    /// Update a single workout in the list without refetching (e.g. after edit in detail).
    func updateWorkoutInList(_ updated: MemberWorkout) {
        guard let index = workouts.firstIndex(where: { $0.id == updated.id }) else { return }
        workouts[index] = updated
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
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        isSearchingExercises = true
        await exerciseService.loadIfNeeded()
        if trimmed.isEmpty {
            // Before user types, show all exercises.
            searchResults = exerciseService.exercises
        } else {
            searchResults = exerciseService.searchByName(trimmed)
        }
        isSearchingExercises = false
    }
}

