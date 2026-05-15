//
//  GroupTrainingRepository.swift
//  SmartGym
//

import Foundation
import Supabase

private struct GroupTrainingRow: Decodable {
    let id: String
    let gymId: String
    let trainerId: String
    let title: String
    let price: Double
    let description: String?
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, price, description
        case gymId = "gym_id"
        case trainerId = "trainer_id"
        case isActive = "is_active"
    }
}

private struct GroupTrainingSlotRow: Decodable {
    let id: String
    let groupTrainingId: String
    let weekday: Int
    let startTime: String
    let endTime: String?

    enum CodingKeys: String, CodingKey {
        case id, weekday
        case groupTrainingId = "group_training_id"
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

private struct GroupTrainingMemberRow: Decodable {
    let groupTrainingId: String

    enum CodingKeys: String, CodingKey {
        case groupTrainingId = "group_training_id"
    }
}

private struct GroupTrainerRow: Decodable {
    let id: String
    let fullName: String

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
    }
}

private struct GroupTrainingOverrideRow: Decodable {
    let slotId: String
    let originalDate: String
    let overrideDate: String?
    let startTime: String?
    let endTime: String?
    let isCancelled: Bool

    enum CodingKeys: String, CodingKey {
        case slotId = "slot_id"
        case originalDate = "original_date"
        case overrideDate = "override_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case isCancelled = "is_cancelled"
    }
}

final class GroupTrainingRepository {
    private let client = AppSupabase.client

    func getGroupTrainings(gymId: String) async throws -> [GroupTraining] {
        let groups: [GroupTrainingRow] = try await client
            .from("group_trainings")
            .select()
            .eq("gym_id", value: gymId)
            .eq("is_active", value: true)
            .order("title", ascending: true)
            .execute()
            .value

        let slots: [GroupTrainingSlotRow] = (try? await client
            .from("group_training_slots")
            .select()
            .eq("gym_id", value: gymId)
            .order("weekday", ascending: true)
            .order("start_time", ascending: true)
            .execute()
            .value) ?? []

        let trainers: [GroupTrainerRow] = (try? await client
            .from("pt_trainers")
            .select()
            .eq("gym_id", value: gymId)
            .execute()
            .value) ?? []
        let trainersById = Dictionary(uniqueKeysWithValues: trainers.map { ($0.id, $0.fullName) })

        return groups.map { group in
            let groupSlots = slots
                .filter { $0.groupTrainingId == group.id }
                .sorted {
                    if $0.weekday == $1.weekday {
                        return $0.startTime < $1.startTime
                    }
                    return $0.weekday < $1.weekday
                }
                .map {
                    GroupTrainingSlot(
                        id: $0.id,
                        groupTrainingId: $0.groupTrainingId,
                        weekday: $0.weekday,
                        startTime: $0.startTime,
                        endTime: $0.endTime
                    )
                }
            return GroupTraining(
                id: group.id,
                gymId: group.gymId,
                trainerId: group.trainerId,
                title: group.title,
                price: group.price,
                description: group.description,
                isActive: group.isActive,
                trainerName: trainersById[group.trainerId],
                slots: groupSlots
            )
        }
    }

    func getMemberGroupTrainings(memberId: String, gymId: String) async throws -> [GroupTraining] {
        let memberships: [GroupTrainingMemberRow] = try await client
            .from("group_training_members")
            .select()
            .eq("member_id", value: memberId)
            .eq("is_active", value: true)
            .execute()
            .value
        let groupIds = Set(memberships.map(\.groupTrainingId))
        guard !groupIds.isEmpty else { return [] }
        let trainings = try await getGroupTrainings(gymId: gymId)
        return trainings.filter { groupIds.contains($0.id) }
    }

    func getNextTrainingForMember(memberId: String, gymId: String) async throws -> NextGroupTraining? {
        let groups = try await getMemberGroupTrainings(memberId: memberId, gymId: gymId)
        guard !groups.isEmpty else { return nil }

        let overrides: [GroupTrainingOverrideRow] = (try? await client
            .from("group_training_occurrence_overrides")
            .select()
            .eq("gym_id", value: gymId)
            .execute()
            .value) ?? []
        let overridesByKey = Dictionary(uniqueKeysWithValues: overrides.map { ("\($0.slotId):\($0.originalDate)", $0) })

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let isoFormatter = DateFormatter()
        isoFormatter.locale = Locale(identifier: "en_US_POSIX")
        isoFormatter.dateFormat = "yyyy-MM-dd"

        var candidates: [(date: Date, training: NextGroupTraining)] = []
        for offset in 0...28 {
            guard let date = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: date) - 1
            let originalDate = isoFormatter.string(from: date)
            for group in groups {
                for slot in group.slots where slot.weekday == weekday {
                    let override = overridesByKey["\(slot.id):\(originalDate)"]
                    if override?.isCancelled == true { continue }
                    let finalDateIso = override?.overrideDate ?? originalDate
                    let finalStart = override?.startTime ?? slot.startTime
                    let finalEnd = override?.endTime ?? slot.endTime
                    guard let finalDate = isoFormatter.date(from: finalDateIso) else { continue }
                    candidates.append((
                        date: finalDate,
                        training: NextGroupTraining(
                            groupTitle: group.title,
                            trainerName: group.trainerName,
                            dateIso: finalDateIso,
                            startTime: finalStart,
                            endTime: finalEnd
                        )
                    ))
                }
            }
        }

        return candidates.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                return lhs.training.startTime < rhs.training.startTime
            }
            return lhs.date < rhs.date
        }.first?.training
    }
}
