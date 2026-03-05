//
//  GymRepository.swift
//  SmartGym
//

import Foundation
import Supabase

private struct GymRow: Decodable {
    let id: String
    let name: String
    let tagline: String?
    let address: String?
    let phone: String?
    let website: String?
    let logoUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, tagline, address, phone, website
        case logoUrl = "logo_url"
    }

    var toGym: Gym {
        Gym(
            id: id,
            name: name,
            tagline: tagline,
            address: address,
            phone: phone,
            website: website,
            logoUrl: logoUrl
        )
    }
}

private struct GymWorkingHoursRow: Decodable {
    let dayOfWeek: Int
    let openTime: String?
    let closeTime: String?
    let isClosed: Bool

    enum CodingKeys: String, CodingKey {
        case dayOfWeek = "day_of_week"
        case openTime = "open_time"
        case closeTime = "close_time"
        case isClosed = "is_closed"
    }

    var toModel: GymWorkingHours {
        GymWorkingHours(dayOfWeek: dayOfWeek, openTime: openTime, closeTime: closeTime, isClosed: isClosed)
    }
}

final class GymRepository {
    private let client = AppSupabase.client

    func getGymById(gymId: String) async throws -> Gym? {
        let rows: [GymRow] = try await client
            .from("gyms")
            .select()
            .eq("id", value: gymId)
            .execute()
            .value
        return rows.first?.toGym
    }

    func getWorkingHours(gymId: String) async throws -> [GymWorkingHours] {
        let rows: [GymWorkingHoursRow] = try await client
            .from("gym_working_hours")
            .select()
            .eq("gym_id", value: gymId)
            .execute()
            .value
        return rows.map(\.toModel)
    }
}
