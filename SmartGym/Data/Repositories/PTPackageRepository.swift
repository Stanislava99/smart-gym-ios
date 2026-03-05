//
//  PTPackageRepository.swift
//  SmartGym
//

import Foundation
import Supabase

private struct PTPackageRow: Decodable {
    let id: String
    let gymId: String
    let name: String
    let sessionsCount: Int
    let price: Double
    let durationDays: Int?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case id, name, price, description
        case gymId = "gym_id"
        case sessionsCount = "sessions_count"
        case durationDays = "duration_days"
    }

    var toModel: PTPackage {
        PTPackage(
            id: id,
            gymId: gymId,
            name: name,
            sessionsCount: sessionsCount,
            price: price,
            durationDays: durationDays,
            description: description
        )
    }
}

final class PTPackageRepository {
    private let client = AppSupabase.client

    func getPackagesByGymId(gymId: String) async throws -> [PTPackage] {
        let rows: [PTPackageRow] = try await client
            .from("pt_packages")
            .select()
            .eq("gym_id", value: gymId)
            .eq("is_active", value: true)
            .execute()
            .value
        return rows.map(\.toModel)
    }
}
