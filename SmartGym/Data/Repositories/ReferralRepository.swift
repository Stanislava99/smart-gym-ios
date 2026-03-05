import Foundation
import Supabase

private struct ReferralProgramRow: Decodable {
    let gymId: String
    let enabled: Bool
    let pointValueMinor: Int64

    enum CodingKeys: String, CodingKey {
        case gymId = "gym_id"
        case enabled
        case pointValueMinor = "point_value_minor"
    }
}

private struct MemberPointBalanceRow: Decodable {
    let gymId: String
    let memberId: String
    let pointsBalance: Int64

    enum CodingKeys: String, CodingKey {
        case gymId = "gym_id"
        case memberId = "member_id"
        case pointsBalance = "points_balance"
    }
}

private struct MemberReferralCodeRow: Decodable {
    let gymId: String
    let memberId: String
    let code: String

    enum CodingKeys: String, CodingKey {
        case gymId = "gym_id"
        case memberId = "member_id"
        case code
    }
}

final class ReferralRepository {
    private let client = AppSupabase.client

    /// Ensures the member has an active referral code for the given gym by calling the
    /// `get_or_create_member_code` RPC. Returns the code if successful, otherwise nil.
    func getOrCreateMemberCode(memberId: String, gymId: String) async throws -> String? {
        do {
            print("[ReferralRepository] getOrCreateMemberCode: starting memberId=\(memberId), gymId=\(gymId)")

            // Decode the RPC result directly as a String. The Postgres function always returns TEXT,
            // so this should either succeed with a non-empty value or throw on failure.
            let code: String = try await client
                .rpc(
                    "get_or_create_member_code",
                    params: [
                        "p_member_id": memberId,
                        "p_gym_id": gymId,
                    ]
                )
                .execute()
                .value

            if !code.isEmpty {
                print("[ReferralRepository] getOrCreateMemberCode: RPC returned code '\(code)' for memberId=\(memberId), gymId=\(gymId)")
                return code
            } else {
                // This should not normally happen because the function always returns a non-empty TEXT,
                // but keep the guard in place for safety.
                print("[ReferralRepository] getOrCreateMemberCode: RPC returned empty code for memberId=\(memberId), gymId=\(gymId)")
                return nil
            }
        } catch {
            print("[ReferralRepository] getOrCreateMemberCode: ERROR for memberId=\(memberId), gymId=\(gymId) - \(error)")
            return nil
        }
    }

    /// Loads referral & points overview for the given member and gym.
    /// Uses direct table access with RLS, matching the schema defined in the referral migration.
    func getReferralOverview(memberId: String, gymId: String) async throws -> MemberReferralOverview? {
        print("[ReferralRepository] getReferralOverview: memberId=\(memberId), gymId=\(gymId) - starting")

        async let programRowsTask: [ReferralProgramRow] = client
            .from("referral_programs")
            .select()
            .eq("gym_id", value: gymId)
            .limit(1)
            .execute()
            .value

        async let balanceRowsTask: [MemberPointBalanceRow] = client
            .from("member_point_balances")
            .select()
            .eq("gym_id", value: gymId)
            .eq("member_id", value: memberId)
            .limit(1)
            .execute()
            .value

        async let codeRowsTask: [MemberReferralCodeRow] = client
            .from("member_referral_codes")
            .select()
            .eq("gym_id", value: gymId)
            .eq("member_id", value: memberId)
            .limit(1)
            .execute()
            .value

        let (programRows, balanceRows, codeRows) = try await (programRowsTask, balanceRowsTask, codeRowsTask)

        if programRows.isEmpty {
            print("[ReferralRepository] getReferralOverview: no referral_programs row for gymId=\(gymId)")
        }

        guard
            let program = programRows.first,
            program.enabled
        else {
            print("[ReferralRepository] getReferralOverview: program disabled or missing for gymId=\(gymId)")
            return nil
        }

        let balance = balanceRows.first
        let referralCode = codeRows.first?.code

        if codeRows.isEmpty {
            print("[ReferralRepository] getReferralOverview: no member_referral_codes row for memberId=\(memberId), gymId=\(gymId)")
        } else if let code = referralCode {
            print("[ReferralRepository] getReferralOverview: loaded referral code '\(code)' for memberId=\(memberId), gymId=\(gymId)")
        }

        let pointsBalance = balance?.pointsBalance ?? 0

        if balance == nil {
            print("[ReferralRepository] getReferralOverview: no member_point_balances row for memberId=\(memberId), gymId=\(gymId). Using 0 points.")
        }

        print("[ReferralRepository] getReferralOverview: returning overview with pointsBalance=\(pointsBalance), pointValueMinor=\(program.pointValueMinor)")

        return MemberReferralOverview(
            gymId: gymId,
            memberId: memberId,
            pointsBalance: pointsBalance,
            pointValueMinor: program.pointValueMinor,
            currencyCode: nil,
            referralCode: referralCode
        )
    }
}

