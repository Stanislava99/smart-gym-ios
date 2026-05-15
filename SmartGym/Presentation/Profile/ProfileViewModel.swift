//
//  ProfileViewModel.swift
//  SmartGym
//

import Foundation
internal import Auth

struct EditProfileState: Equatable {
    var firstName: String = ""
    var lastName: String = ""
    var birthDate: String = ""
    var heightCm: Double?
    var weightKg: Double?
    var goal: String = ""
}

@MainActor
@Observable
final class ProfileViewModel {
    var member: Member?
    var userEmail: String?
    var referralOverview: MemberReferralOverview?
    var weightLogs: [MemberWeightLog] = []
    var isLoading = true
    var isLoadingReferral = false
    var isLoadingWeightLogs = false
    var error: String?
    var referralError: String?
    var weightLogError: String?
    var editProfileState: EditProfileState?
    var isSaving = false
    var isPreparingShare = false
    var isSavingWeightLog = false

    private let authRepository = AuthRepository()
    private let memberRepository = MemberRepository()
    private let referralRepository = ReferralRepository()

    init() {
        Task { await loadProfile() }
    }

    func loadProfile(showLoading: Bool = true) async {
        if showLoading {
            isLoading = true
        }
        error = nil
        userEmail = await authRepository.currentUser?.email
        do {
            member = try await memberRepository.getCurrentMember()
            if let m = member {
                await loadReferral(for: m)
                await loadWeightLogs()
            } else {
                referralOverview = nil
                weightLogs = []
            }
        } catch {
            if showLoading || member == nil {
                self.error = error.localizedDescription
            }
        }
        if showLoading {
            isLoading = false
        }
    }

    func refreshProfile() async {
        async let minimumVisibleRefresh: Void = Task.sleep(nanoseconds: 450_000_000)
        await loadProfile(showLoading: false)
        _ = try? await minimumVisibleRefresh
    }

    private func loadReferral(for member: Member) async {
        isLoadingReferral = true
        referralError = nil
        do {
            referralOverview = try await referralRepository.getReferralOverview(
                memberId: member.id,
                gymId: member.gymId
            )
        } catch {
            referralError = error.localizedDescription
        }
        isLoadingReferral = false
    }

    func loadWeightLogs() async {
        isLoadingWeightLogs = true
        weightLogError = nil
        do {
            weightLogs = try await memberRepository.getWeightLogs()
        } catch {
            weightLogError = error.localizedDescription
        }
        isLoadingWeightLogs = false
    }

    func saveWeightLog(weightKg: Double, loggedAt: Date = Date(), notes: String? = nil) async -> Bool {
        guard let member else { return false }
        isSavingWeightLog = true
        weightLogError = nil
        defer { isSavingWeightLog = false }

        do {
            try await memberRepository.addWeightLog(
                member: member,
                weightKg: weightKg,
                loggedAt: loggedAt,
                notes: notes
            )
            await loadWeightLogs()
            return true
        } catch {
            weightLogError = error.localizedDescription
            return false
        }
    }

    func inviteFriendShareMessage() async -> String {
        let genericMessage = "Join me at Smart Gym! Ask staff about the referral program."

        guard let member else {
            return genericMessage
        }

        isPreparingShare = true
        defer { isPreparingShare = false }

        let code = try? await referralRepository.getOrCreateMemberCode(
            memberId: member.id,
            gymId: member.gymId
        )

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
        } else if referralOverview == nil {
            await loadReferral(for: member)
        }

        let finalCode = code ?? referralOverview?.referralCode
        if let finalCode, !finalCode.isEmpty {
            return "Join me at Smart Gym! Use my referral code \(finalCode) when signing up."
        }

        return genericMessage
    }

    func startEditProfile() {
        guard let m = member else { return }
        editProfileState = EditProfileState(
            firstName: m.firstName ?? "",
            lastName: m.lastName ?? "",
            birthDate: m.birthDate ?? "",
            heightCm: m.heightCm,
            weightKg: m.weightKg,
            goal: m.goal ?? ""
        )
    }

    func updateEdit(_ state: EditProfileState) {
        editProfileState = state
    }

    func saveProfile(avatarImageData: Data? = nil) async -> Bool {
        guard let m = member, let edit = editProfileState else { return false }
        isSaving = true
        error = nil
        defer { isSaving = false }

        do {
            var avatarUrl: String? = nil
            if let data = avatarImageData, !data.isEmpty {
                let ext = "jpg"
                avatarUrl = try await memberRepository.uploadAvatar(memberId: m.id, imageData: data, fileExtension: ext)
            }
            try await memberRepository.updateProfile(
                firstName: edit.firstName.isEmpty ? nil : edit.firstName,
                lastName: edit.lastName.isEmpty ? nil : edit.lastName,
                birthDate: edit.birthDate.isEmpty ? nil : edit.birthDate,
                heightCm: edit.heightCm,
                weightKg: edit.weightKg,
                goal: edit.goal.isEmpty ? nil : edit.goal,
                avatarUrl: avatarUrl
            )
            editProfileState = nil
            await loadProfile()
            return true
        } catch {
            self.error = error.localizedDescription
            return false
        }
    }

    func signOut() async {
        try? await authRepository.signOut()
    }
}
