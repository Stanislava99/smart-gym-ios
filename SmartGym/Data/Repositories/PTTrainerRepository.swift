//
//  PTTrainerRepository.swift
//  SmartGym
//

import Foundation
import Supabase

private struct PTTrainerRow: Decodable {
    let id: String
    let gymId: String
    let fullName: String
    let email: String?
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case id, email, phone
        case gymId = "gym_id"
        case fullName = "full_name"
    }

    var toModel: PTTrainer {
        PTTrainer(
            id: id,
            gymId: gymId,
            fullName: fullName,
            email: email,
            phone: phone
        )
    }
}

final class PTTrainerRepository {
    private let client = AppSupabase.client

    func getTrainersByGymId(gymId: String) async throws -> [PTTrainer] {
        let rows: [PTTrainerRow] = try await client
            .from("pt_trainers")
            .select()
            .eq("gym_id", value: gymId)
            .execute()
            .value
        return rows.map(\.toModel)
    }
}
