//
//  WorkoutRepository.swift
//  SmartGym
//

import Foundation
import Supabase

private struct WorkoutRow: Decodable {
    let id: String
    let memberId: String
    let workoutDate: String
    let title: String
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case memberId = "member_id"
        case workoutDate = "workout_date"
        case title
        case notes
    }

    var toWorkout: MemberWorkout {
        MemberWorkout(
            id: id,
            memberId: memberId,
            workoutDate: workoutDate,
            title: title,
            notes: notes
        )
    }
}

final class WorkoutRepository {
    private let client = AppSupabase.client

    func getWorkouts(memberId: String) async throws -> [MemberWorkout] {
        let rows: [WorkoutRow] = try await client
            .from("member_workouts")
            .select()
            .eq("member_id", value: memberId)
            .order("workout_date", ascending: false)
            .execute()
            .value
        return rows.map(\.toWorkout)
    }

    func addWorkout(memberId: String, title: String, workoutDate: String, notes: String? = nil) async throws -> MemberWorkout {
        struct InsertPayload: Encodable {
            let memberId: String
            let title: String
            let workoutDate: String
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case memberId = "member_id"
                case title
                case workoutDate = "workout_date"
                case notes
            }
        }
        let payload = InsertPayload(
            memberId: memberId,
            title: title,
            workoutDate: workoutDate,
            notes: notes
        )
        let rows: [WorkoutRow] = try await client
            .from("member_workouts")
            .insert(payload)
            .select()
            .execute()
            .value
        guard let row = rows.first else {
            throw NSError(domain: "WorkoutRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create workout row"])
        }
        return row.toWorkout
    }

    struct NewWorkoutSet {
        let setNumber: Int
        let reps: Int?
        let weight: Double?
    }

    struct NewWorkoutExercise {
        let externalSource: String
        let externalExerciseId: String
        let name: String
        let bodyPart: String?
        let targetMuscle: String?
        let equipment: String?
        let sets: [NewWorkoutSet]
    }

    /// Inserts exercises and sets for a given workout.
    func addExercisesAndSets(
        workoutId: String,
        exercises: [NewWorkoutExercise]
    ) async throws {
        guard !exercises.isEmpty else { return }

        struct ExerciseInsert: Encodable {
            let memberWorkoutId: String
            let externalSource: String
            let externalExerciseId: String
            let name: String
            let bodyPart: String?
            let targetMuscle: String?
            let equipment: String?
            let position: Int

            enum CodingKeys: String, CodingKey {
                case memberWorkoutId = "member_workout_id"
                case externalSource = "external_source"
                case externalExerciseId = "external_exercise_id"
                case name
                case bodyPart = "body_part"
                case targetMuscle = "target_muscle"
                case equipment
                case position
            }
        }

        struct ExerciseRow: Decodable {
            let id: String
            let memberWorkoutId: String

            enum CodingKeys: String, CodingKey {
                case id
                case memberWorkoutId = "member_workout_id"
            }
        }

        let inserts: [ExerciseInsert] = exercises.enumerated().map { index, e in
            ExerciseInsert(
                memberWorkoutId: workoutId,
                externalSource: e.externalSource,
                externalExerciseId: e.externalExerciseId,
                name: e.name,
                bodyPart: e.bodyPart,
                targetMuscle: e.targetMuscle,
                equipment: e.equipment,
                position: index
            )
        }

        let inserted: [ExerciseRow] = try await client
            .from("member_workout_exercises")
            .insert(inserts)
            .select()
            .execute()
            .value

        struct SetInsert: Encodable {
            let memberWorkoutExerciseId: String
            let setNumber: Int
            let reps: Int?
            let weight: Double?
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case memberWorkoutExerciseId = "member_workout_exercise_id"
                case setNumber = "set_number"
                case reps
                case weight
                case notes
            }
        }

        var setInserts: [SetInsert] = []
        for (idx, row) in inserted.enumerated() {
            guard idx < exercises.count else { continue }
            let source = exercises[idx]
            for set in source.sets {
                setInserts.append(
                    SetInsert(
                        memberWorkoutExerciseId: row.id,
                        setNumber: set.setNumber,
                        reps: set.reps,
                        weight: set.weight,
                        notes: nil
                    )
                )
            }
        }

        guard !setInserts.isEmpty else { return }

        _ = try? await client
            .from("member_workout_sets")
            .insert(setInserts)
            .execute()
    }

    /// Returns true if the member has at least one workout on the given ISO date (YYYY-MM-DD).
    func hasWorkout(on isoDate: String, memberId: String) async -> Bool {
        do {
            let rows: [WorkoutRow] = try await client
                .from("member_workouts")
                .select()
                .eq("member_id", value: memberId)
                .eq("workout_date", value: isoDate)
                .limit(1)
                .execute()
                .value
            return !rows.isEmpty
        } catch {
            return false
        }
    }

    /// Fetch all workouts for a member in the given inclusive ISO date range.
    func getWorkoutsInRange(memberId: String, fromDate: String, toDate: String) async -> [MemberWorkout] {
        do {
            let rows: [WorkoutRow] = try await client
                .from("member_workouts")
                .select()
                .eq("member_id", value: memberId)
                .gte("workout_date", value: fromDate)
                .lte("workout_date", value: toDate)
                .order("workout_date", ascending: false)
                .execute()
                .value
            return rows.map(\.toWorkout)
        } catch {
            return []
        }
    }

    func getExerciseExternalIds(forWorkoutId workoutId: String) async -> [String] {
        struct Row: Decodable {
            let externalExerciseId: String

            enum CodingKeys: String, CodingKey {
                case externalExerciseId = "external_exercise_id"
            }
        }

        do {
            let rows: [Row] = try await client
                .from("member_workout_exercises")
                .select()
                .eq("member_workout_id", value: workoutId)
                .execute()
                .value
            return rows.map(\.externalExerciseId)
        } catch {
            return []
        }
    }
}
