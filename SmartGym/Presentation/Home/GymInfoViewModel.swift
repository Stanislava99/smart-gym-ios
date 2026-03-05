//
//  GymInfoViewModel.swift
//  SmartGym
//

import Foundation

@MainActor
@Observable
final class GymInfoViewModel {
    var member: Member?
    var gym: Gym?
    /// Resolved logo URL (signed when from Supabase gym-logos bucket)
    var resolvedLogoUrl: String?
    var plans: [Plan] = []
    var trainers: [PTTrainer] = []
    var ptPackages: [PTPackage] = []
    var isLoading = true
    var error: String?

    private let memberRepository = MemberRepository()
    private let gymRepository = GymRepository()
    private let planRepository = PlanRepository()
    private let ptTrainerRepository = PTTrainerRepository()
    private let ptPackageRepository = PTPackageRepository()

    init() {
        Task { await load() }
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            member = try await memberRepository.getCurrentMember()
            guard let gymId = member?.gymId else {
                gym = nil
                resolvedLogoUrl = nil
                plans = []
                trainers = []
                ptPackages = []
                isLoading = false
                return
            }
            async let gymTask: Gym? = gymRepository.getGymById(gymId: gymId)
            async let plansTask: [Plan] = (try? planRepository.getPlansByGymId(gymId: gymId)) ?? []
            async let trainersTask: [PTTrainer] = (try? ptTrainerRepository.getTrainersByGymId(gymId: gymId)) ?? []
            async let packagesTask: [PTPackage] = (try? ptPackageRepository.getPackagesByGymId(gymId: gymId)) ?? []

            gym = try await gymTask
            resolvedLogoUrl = await resolveGymLogoUrl(gym?.logoUrl)
            plans = await plansTask
            trainers = await trainersTask
            ptPackages = await packagesTask
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
