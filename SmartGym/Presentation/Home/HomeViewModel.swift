//
//  HomeViewModel.swift
//  SmartGym
//

import Foundation

@MainActor
@Observable
final class HomeViewModel {
    var member: Member?
    var gym: Gym?
    var workingHours: [GymWorkingHours] = []
    var memberships: [(Member, Gym)] = []
    var referralOverview: MemberReferralOverview?
    var isLoading = true
    var error: String?

    /// Whether the member has logged a workout today.
    /// TODO: Wire this to real workout data once available.
    var hasWorkoutToday: Bool = false

    private let memberRepository = MemberRepository()
    private let gymRepository = GymRepository()
    private let referralRepository = ReferralRepository()
    private let workoutRepository = WorkoutRepository()

    /// Open/closed status based on current time and working hours
    var gymOpenStatus: GymOpenStatus {
        GymOpenStatus.status(workingHours: workingHours)
    }

    /// Today's hours text, e.g. "6:00 AM – 10:00 PM" or "Closed today"
    var gymHoursText: String? {
        GymOpenStatus.hoursText(workingHours: workingHours)
    }

    init() {
        Task { await loadMember() }
    }

    /// Ensures a referral code exists for the current member/gym by calling the backend RPC,
    /// updates the in-memory overview with the latest code, and returns the share message.
    func inviteFriendShareMessage() async -> String {
        let genericMessage = "Join me at Smart Gym! Ask staff about the referral program."

        guard
            let member,
            let gym
        else {
            print("[HomeViewModel] inviteFriendShareMessage: missing member or gym; using generic message")
            return genericMessage
        }

        let code = try? await referralRepository.getOrCreateMemberCode(
            memberId: member.id,
            gymId: gym.id
        )

        // Update referralOverview with the latest code if we have one.
        if
            let existingOverview = referralOverview,
            let code,
            !code.isEmpty,
            code != existingOverview.referralCode
        {
            referralOverview = MemberReferralOverview(
                gymId: existingOverview.gymId,
                memberId: existingOverview.memberId,
                pointsBalance: existingOverview.pointsBalance,
                pointValueMinor: existingOverview.pointValueMinor,
                currencyCode: existingOverview.currencyCode,
                referralCode: code
            )
        }

        let finalCode = code ?? referralOverview?.referralCode

        if let finalCode, !finalCode.isEmpty {
            return "Join me at Smart Gym! Use my referral code \(finalCode) when signing up."
        } else {
            return genericMessage
        }
    }

    func loadMember() async {
        print("[HomeViewModel] loadMember: starting")
        isLoading = true
        error = nil
        do {
            member = try await memberRepository.getCurrentMember()
            memberships = (try? await memberRepository.getAllMemberships()) ?? []
            print("[HomeViewModel] loadMember: member=\(member != nil ? "\(member!.fullName) (id=\(member!.id))" : "nil"), memberships=\(memberships.count)")
            if let gymId = member?.gymId {
                gym = try await gymRepository.getGymById(gymId: gymId)
                workingHours = (try? await gymRepository.getWorkingHours(gymId: gymId)) ?? []
                print("[HomeViewModel] loadMember: gym=\(gym != nil ? gym!.name : "nil")")
            } else {
                gym = nil
                workingHours = []
                print("[HomeViewModel] loadMember: no gymId, gym=nil")
            }

            if let currentMember = member {
                // Load referral overview for quick actions on Home.
                referralOverview = try? await referralRepository.getReferralOverview(
                    memberId: currentMember.id,
                    gymId: currentMember.gymId
                )

                // Check if member has a workout logged today for Weekly Strikes.
                let isoFormatter = DateFormatter()
                isoFormatter.locale = Locale(identifier: "en_US_POSIX")
                isoFormatter.dateFormat = "yyyy-MM-dd"
                let todayIso = isoFormatter.string(from: Date())
                hasWorkoutToday = await workoutRepository.hasWorkout(on: todayIso, memberId: currentMember.id)
            } else {
                referralOverview = nil
                hasWorkoutToday = false
            }
        } catch {
            print("[HomeViewModel] loadMember: ERROR - \(error)")
            self.error = error.localizedDescription
        }
        print("[HomeViewModel] loadMember: done, error=\(error ?? "nil")")
        isLoading = false
    }

    func switchGym(member: Member, gym: Gym) async {
        do {
            try await memberRepository.setActiveGym(gymId: gym.id, memberId: member.id)
            await loadMember()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
