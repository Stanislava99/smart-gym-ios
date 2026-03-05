//
//  PlanRepository.swift
//  SmartGym
//

import Foundation
import Supabase

private struct PlanRow: Decodable {
    let id: String
    let gymId: String
    let title: String
    let durationDays: Int
    let description: String?
    let price: Double

    enum CodingKeys: String, CodingKey {
        case id, title, description, price
        case gymId = "gym_id"
        case durationDays = "duration_days"
    }

    var toPlan: Plan {
        Plan(
            id: id,
            gymId: gymId,
            title: title,
            durationDays: durationDays,
            description: description,
            price: price
        )
    }
}

final class PlanRepository {
    private let client = AppSupabase.client

    func getPlansByGymId(gymId: String) async throws -> [Plan] {
        let rows: [PlanRow] = try await client
            .from("plans")
            .select()
            .eq("gym_id", value: gymId)
            .execute()
            .value
        return rows.map(\.toPlan)
    }
}
