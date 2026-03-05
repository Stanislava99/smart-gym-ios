//
//  MemberRepository.swift
//  SmartGym
//

import Foundation
import Supabase

private struct MemberRow: Decodable {
    let id: String
    let userId: String?
    let gymId: String
    let fullName: String?
    let email: String?
    let phone: String?
    let subscriptionStatus: String?
    let subscriptionStartDate: String?
    let subscriptionEndDate: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case gymId = "gym_id"
        case fullName = "full_name"
        case email
        case phone
        case subscriptionStatus = "subscription_status"
        case subscriptionStartDate = "subscription_start_date"
        case subscriptionEndDate = "subscription_end_date"
        case avatarUrl = "avatar_url"
    }
}

private struct MemberProfileRow: Decodable {
    let userId: String
    let gymId: String?
    let memberId: String?
    let activeGymId: String?
    let firstName: String?
    let lastName: String?
    let age: Int?
    let heightCm: Double?
    let weightKg: Double?
    let goal: String?
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case gymId = "gym_id"
        case memberId = "member_id"
        case activeGymId = "active_gym_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case age
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case goal
        case avatarUrl = "avatar_url"
    }
}

private struct MembershipItem: Decodable {
    let memberId: String
    let gymId: String
    enum CodingKeys: String, CodingKey {
        case memberId = "member_id"
        case gymId = "gym_id"
    }
}

private struct LinkMemberResponse: Decodable {
    let success: Bool?
    let memberId: String?
    let gymId: String?
    let memberships: [MembershipItem]?
    let error: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case success
        case memberId = "member_id"
        case gymId = "gym_id"
        case memberships
        case error
        case message
    }
}

final class MemberRepository {
    private let client = AppSupabase.client

    func getCurrentMember() async throws -> Member? {
        print("[MemberRepository] getCurrentMember: starting")

        var session = try await client.auth.session
        // With emitLocalSessionAsInitialSession: true, session may be expired initially.
        // Refresh before using for API calls to avoid 401 from Edge Functions.
        if session.isExpired {
            print("[MemberRepository] getCurrentMember: session expired, refreshing")
            session = try await client.auth.refreshSession()
        }
        print("[MemberRepository] getCurrentMember: session OK, user id=\(session.user.id), email=\(session.user.email ?? "nil")")

        // 1. Try direct fetch (member already linked via user_id)
        print("[MemberRepository] getCurrentMember: step 1 - fetching member by user_id (RLS)")
        var member: Member?
        do {
            member = try await fetchMemberByUserId()
            print("[MemberRepository] getCurrentMember: step 1 - direct fetch returned \(member != nil ? "member(\(member!.id))" : "nil")")
        } catch {
            print("[MemberRepository] getCurrentMember: step 1 - direct fetch FAILED: \(error)")
            throw error
        }

        if member != nil {
            print("[MemberRepository] getCurrentMember: returning existing member")
            return member
        }

        // 2. Try to link by email via Edge Function (finds unlinked member with matching email)
        // Workaround: explicitly pass Authorization header - supabase-swift Functions client
        // can send anon key instead of user JWT after sign-in (issue #877)
        print("[MemberRepository] getCurrentMember: step 2 - calling link-member-account Edge Function")
        do {
            let response: LinkMemberResponse = try await client.functions.invoke(
                "link-member-account",
                options: FunctionInvokeOptions(
                    headers: ["Authorization": "Bearer \(session.accessToken)"]
                )
            )
            print("[MemberRepository] getCurrentMember: step 2 - link response: success=\(response.success ?? false), error=\(response.error ?? "nil"), message=\(response.message ?? "nil")")
            if response.success == true {
                print("[MemberRepository] getCurrentMember: step 2 - link succeeded, retrying fetch")
                member = try await fetchMemberByUserId()
                print("[MemberRepository] getCurrentMember: step 2 - retry fetch returned \(member != nil ? "member" : "nil")")
            }
        } catch {
            print("[MemberRepository] getCurrentMember: step 2 - link-member-account FAILED: \(error)")
            // Link failed (no member found, etc.) - fall through to return null
        }

        print("[MemberRepository] getCurrentMember: returning \(member != nil ? "member" : "nil")")
        return member
    }

    private func fetchMemberByUserId() async throws -> Member? {
        // 1. Fetch member_profiles first (has profile data + active_gym_id for multi-gym)
        var profileRows: [MemberProfileRow] = []
        do {
            profileRows = try await client.from("member_profiles").select().execute().value
        } catch {
            print("[MemberRepository] member_profiles fetch failed: \(error)")
        }

        let profile = profileRows.first
        let activeGymId = profile?.activeGymId ?? profile?.gymId

        // 2. Fetch all members for user (RLS allows)
        let allRows: [MemberRow] = try await client.from("members").select().execute().value
        guard !allRows.isEmpty else {
            print("[MemberRepository] fetchMemberByUserId: no members")
            return nil
        }

        // 3. Pick member for active gym, or first if no active
        let memberRow: MemberRow?
        if let gymId = activeGymId {
            memberRow = allRows.first { $0.gymId == gymId } ?? allRows.first
        } else {
            memberRow = allRows.first
        }

        guard let member = memberRow else {
            return nil
        }
        print("[MemberRepository] fetchMemberByUserId: member found for gym \(member.gymId)")

        // 4. Ensure profile exists (create empty on first login)
        if profile == nil, let uid = member.userId {
            do {
                struct ProfileInsert: Encodable {
                    let userId: String
                    let gymId: String
                    let memberId: String
                    let activeGymId: String?
                    enum CodingKeys: String, CodingKey {
                        case userId = "user_id"
                        case gymId = "gym_id"
                        case memberId = "member_id"
                        case activeGymId = "active_gym_id"
                    }
                }
                try await client.from("member_profiles")
                    .insert(ProfileInsert(userId: uid, gymId: member.gymId, memberId: member.id, activeGymId: member.gymId))
                    .execute()
                profileRows = try await client.from("member_profiles").select().execute().value
            } catch {
                print("[MemberRepository] member_profiles insert failed: \(error)")
            }
        }

        return toMember(memberRow: member, profile: profileRows.first)
    }

    /// Returns all memberships (member + gym) for the current user. Used for gym switcher.
    func getAllMemberships() async throws -> [(Member, Gym)] {
        let memberRows: [MemberRow] = try await client.from("members").select().execute().value
        guard !memberRows.isEmpty else { return [] }

        var result: [(Member, Gym)] = []
        let profileRows: [MemberProfileRow] = (try? await client.from("member_profiles").select().execute().value) ?? []
        let profile = profileRows.first

        for row in memberRows {
            let member = toMember(memberRow: row, profile: profile)
            if let gym = try? await GymRepository().getGymById(gymId: row.gymId) {
                result.append((member, gym))
            }
        }
        return result
    }

    /// Switch active gym. Updates member_profiles and subsequent getCurrentMember() returns the new gym's member.
    func setActiveGym(gymId: String, memberId: String) async throws {
        let session = try await client.auth.session
        struct UpdatePayload: Encodable {
            let gymId: String
            let memberId: String
            let activeGymId: String
            enum CodingKeys: String, CodingKey {
                case gymId = "gym_id"
                case memberId = "member_id"
                case activeGymId = "active_gym_id"
            }
        }
        try await client
            .from("member_profiles")
            .update(UpdatePayload(gymId: gymId, memberId: memberId, activeGymId: gymId))
            .eq("user_id", value: session.user.id)
            .execute()
    }

    private func toMember(memberRow: MemberRow, profile: MemberProfileRow?) -> Member {
        Member(
            id: memberRow.id,
            userId: memberRow.userId,
            gymId: profile?.gymId ?? memberRow.gymId,
            fullName: memberRow.fullName ?? "",
            firstName: profile?.firstName,
            lastName: profile?.lastName,
            email: memberRow.email ?? "",
            phone: memberRow.phone ?? "",
            planId: nil,
            status: memberRow.subscriptionStatus ?? "active",
            subscriptionStartDate: memberRow.subscriptionStartDate,
            subscriptionEndDate: memberRow.subscriptionEndDate,
            avatarUrl: profile?.avatarUrl ?? memberRow.avatarUrl,
            age: profile?.age,
            heightCm: profile?.heightCm,
            weightKg: profile?.weightKg,
            goal: profile?.goal
        )
    }

    func updateProfile(
        firstName: String?,
        lastName: String?,
        age: Int?,
        heightCm: Double?,
        weightKg: Double?,
        goal: String?,
        avatarUrl: String? = nil
    ) async throws {
        let session = try await client.auth.session
        let userId = session.user.id

        struct UpdatePayload: Encodable {
            let firstName: String?
            let lastName: String?
            let age: Int?
            let heightCm: Double?
            let weightKg: Double?
            let goal: String?
            let avatarUrl: String?

            enum CodingKeys: String, CodingKey {
                case firstName = "first_name"
                case lastName = "last_name"
                case age
                case heightCm = "height_cm"
                case weightKg = "weight_kg"
                case goal
                case avatarUrl = "avatar_url"
            }
        }
        let payload = UpdatePayload(
            firstName: firstName?.isEmpty == true ? nil : firstName,
            lastName: lastName?.isEmpty == true ? nil : lastName,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            goal: goal?.isEmpty == true ? nil : goal,
            avatarUrl: avatarUrl
        )
        try await client
            .from("member_profiles")
            .update(payload)
            .eq("user_id", value: userId)
            .execute()
    }

    /// Uploads avatar image to member-avatars bucket and returns public URL.
    func uploadAvatar(memberId: String, imageData: Data, fileExtension: String = "jpg") async throws -> String {
        let filePath = "\(memberId)/\(Int(Date().timeIntervalSince1970 * 1000)).\(fileExtension)"
        let contentType = fileExtension.lowercased() == "png" ? "image/png" : "image/jpeg"
        try await client.storage
            .from("member-avatars")
            .upload(
                filePath,
                data: imageData,
                options: FileOptions(cacheControl: "3600", contentType: contentType, upsert: true)
            )
        let publicUrl = try client.storage.from("member-avatars").getPublicURL(path: filePath)
        return publicUrl.absoluteString
    }
}
