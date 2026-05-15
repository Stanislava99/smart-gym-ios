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
    var groupTrainings: [GroupTraining] = []
    var workingHours: [GymWorkingHours] = []
    var isLoading = true
    var error: String?

    private let memberRepository = MemberRepository()
    private let gymRepository = GymRepository()
    private let planRepository = PlanRepository()
    private let ptTrainerRepository = PTTrainerRepository()
    private let ptPackageRepository = PTPackageRepository()
    private let groupTrainingRepository = GroupTrainingRepository()

    init() {
        Task { await load() }
    }

    func load(showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
        }
        error = nil
        do {
            member = try await memberRepository.getCurrentMember()
            guard let gymId = member?.gymId else {
                if showLoading || gym == nil {
                    gym = nil
                    resolvedLogoUrl = nil
                    plans = []
                    trainers = []
                    ptPackages = []
                    groupTrainings = []
                    workingHours = []
                }
                if showLoading {
                    isLoading = false
                }
                return
            }
            async let gymTask: Gym? = gymRepository.getGymById(gymId: gymId)
            async let plansTask: [Plan]? = try? planRepository.getPlansByGymId(gymId: gymId)
            async let trainersTask: [PTTrainer]? = try? ptTrainerRepository.getTrainersByGymId(gymId: gymId)
            async let packagesTask: [PTPackage]? = try? ptPackageRepository.getPackagesByGymId(gymId: gymId)
            async let groupsTask: [GroupTraining]? = try? groupTrainingRepository.getGroupTrainings(gymId: gymId)
            async let hoursTask: [GymWorkingHours]? = try? gymRepository.getWorkingHours(gymId: gymId)

            if let fetchedGym = try await gymTask {
                gym = fetchedGym
                resolvedLogoUrl = await resolveGymLogoUrl(fetchedGym.logoUrl)
            } else if showLoading {
                gym = nil
                resolvedLogoUrl = nil
            }
            if let fetchedPlans = await plansTask {
                plans = fetchedPlans
            } else if showLoading {
                plans = []
            }
            if let fetchedTrainers = await trainersTask {
                trainers = fetchedTrainers
            } else if showLoading {
                trainers = []
            }
            if let fetchedPackages = await packagesTask {
                ptPackages = fetchedPackages
            } else if showLoading {
                ptPackages = []
            }
            if let fetchedGroups = await groupsTask {
                groupTrainings = fetchedGroups
            } else if showLoading {
                groupTrainings = []
            }
            if let fetchedHours = await hoursTask {
                workingHours = fetchedHours
            } else if showLoading {
                workingHours = []
            }
        } catch {
            if showLoading || gym == nil {
                self.error = error.localizedDescription
            }
        }
        if showLoading {
            isLoading = false
        }
    }

    func refresh() async {
        async let minimumVisibleRefresh: Void = Task.sleep(nanoseconds: 450_000_000)
        await load(showLoading: false)
        _ = try? await minimumVisibleRefresh
    }
}
