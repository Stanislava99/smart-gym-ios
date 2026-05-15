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

    func getWorkout(id: String) async throws -> MemberWorkout? {
        let rows: [WorkoutRow] = try await client
            .from("member_workouts")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value
        return rows.first?.toWorkout
    }

    func updateWorkout(
        id: String,
        title: String,
        workoutDate: String,
        notes: String?
    ) async throws -> MemberWorkout {
        struct UpdatePayload: Encodable {
            let title: String
            let workoutDate: String
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case title
                case workoutDate = "workout_date"
                case notes
            }
        }

        let payload = UpdatePayload(
            title: title,
            workoutDate: workoutDate,
            notes: notes
        )

        let rows: [WorkoutRow] = try await client
            .from("member_workouts")
            .update(payload)
            .eq("id", value: id)
            .select()
            .execute()
            .value

        guard let row = rows.first else {
            throw NSError(
                domain: "WorkoutRepository",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to update workout row"]
            )
        }
        return row.toWorkout
    }

    func deleteWorkout(id: String) async throws {
        _ = try await client
            .from("member_workouts")
            .delete()
            .eq("id", value: id)
            .execute()
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
        let durationMinutes: Int?
        let distanceKm: Double?
        let stairsClimbed: Int?
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
            let durationMinutes: Int?
            let distanceKm: Double?
            let stairsClimbed: Int?
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case memberWorkoutExerciseId = "member_workout_exercise_id"
                case setNumber = "set_number"
                case reps
                case weight
                case durationMinutes = "duration_minutes"
                case distanceKm = "distance_km"
                case stairsClimbed = "stairs_climbed"
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
                        durationMinutes: set.durationMinutes,
                        distanceKm: set.distanceKm,
                        stairsClimbed: set.stairsClimbed,
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

    /// Total volume lifted (sum of reps × weight in kg) for all sets in workouts within the date range.
    /// Uses a single RPC when available; falls back to per-workout fetches if RPC is not deployed.
    func getTotalVolumeLifted(memberId: String, fromDate: String, toDate: String) async -> Double {
        if let volume = await getTotalVolumeLiftedViaRpc(memberId: memberId, fromDate: fromDate, toDate: toDate) {
            return volume
        }
        let workouts = await getWorkoutsInRange(memberId: memberId, fromDate: fromDate, toDate: toDate)
        var total: Double = 0
        for workout in workouts {
            let exercises = (try? await getWorkoutExercisesWithSets(workoutId: workout.id)) ?? []
            for exercise in exercises {
                for set in exercise.sets {
                    let reps = Double(set.reps ?? 0)
                    let weight = set.weight ?? 0
                    total += reps * weight
                }
            }
        }
        return total
    }

    /// Single round-trip volume via Supabase RPC (requires migration get_member_volume_in_range). Returns nil on failure.
    private func getTotalVolumeLiftedViaRpc(memberId: String, fromDate: String, toDate: String) async -> Double? {
        do {
            let value = try await client
                .rpc(
                    "get_member_volume_in_range",
                    params: [
                        "p_member_id": memberId,
                        "p_from_date": fromDate,
                        "p_to_date": toDate,
                    ]
                )
                .execute()
                .value
            // PostgREST returns numeric as JSON number; decode as Double.
            if let n = value as? Double { return n }
            if let n = value as? Int { return Double(n) }
            if let s = value as? String, let n = Double(s) { return n }
            return nil
        } catch {
            return nil
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

    // MARK: - Workout details (exercises + sets)

    private struct WorkoutExerciseRow: Decodable {
        let id: String
        let name: String

        enum CodingKeys: String, CodingKey {
            case id
            case name
        }
    }

    private struct WorkoutSetRow: Decodable {
        let memberWorkoutExerciseId: String
        let setNumber: Int
        let reps: Int?
        let weight: Double?

        enum CodingKeys: String, CodingKey {
            case memberWorkoutExerciseId = "member_workout_exercise_id"
            case setNumber = "set_number"
            case reps
            case weight
        }
    }

    func getWorkoutExercisesWithSets(workoutId: String) async throws -> [WorkoutExerciseDetail] {
        let exercises: [WorkoutExerciseRow] = try await client
            .from("member_workout_exercises")
            .select("id,name")
            .eq("member_workout_id", value: workoutId)
            .order("position", ascending: true)
            .execute()
            .value

        guard !exercises.isEmpty else { return [] }

        let exerciseIds = exercises.map(\.id)

        let sets: [WorkoutSetRow] = try await client
            .from("member_workout_sets")
            .select()
            .in("member_workout_exercise_id", values: exerciseIds)
            .order("set_number", ascending: true)
            .execute()
            .value

        let setsByExercise = Dictionary(grouping: sets, by: { $0.memberWorkoutExerciseId })

        return exercises.map { ex in
            let exSets = setsByExercise[ex.id] ?? []
            let mappedSets = exSets.map {
                WorkoutExerciseDetail.WorkoutSetDetail(
                    setNumber: $0.setNumber,
                    reps: $0.reps,
                    weight: $0.weight
                )
            }
            return WorkoutExerciseDetail(
                id: ex.id,
                name: ex.name,
                sets: mappedSets
            )
        }
    }
}
