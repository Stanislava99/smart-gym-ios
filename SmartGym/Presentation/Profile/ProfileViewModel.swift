//
//  ProfileViewModel.swift
//  SmartGym
//

import Foundation
internal import Auth

struct EditProfileState: Equatable {
    var firstName: String = ""
    var lastName: String = ""
    var age: Int?
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
    var isLoading = true
    var isLoadingReferral = false
    var error: String?
    var referralError: String?
    var editProfileState: EditProfileState?
    var isSaving = false

    private let authRepository = AuthRepository()
    private let memberRepository = MemberRepository()
    private let referralRepository = ReferralRepository()

    init() {
        Task { await loadProfile() }
    }

    func loadProfile() async {
        isLoading = true
        error = nil
        userEmail = await authRepository.currentUser?.email
        do {
            member = try await memberRepository.getCurrentMember()
            if let m = member {
                await loadReferral(for: m)
            } else {
                referralOverview = nil
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
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

    func startEditProfile() {
        guard let m = member else { return }
        editProfileState = EditProfileState(
            firstName: m.firstName ?? "",
            lastName: m.lastName ?? "",
            age: m.age,
            heightCm: m.heightCm,
            weightKg: m.weightKg,
            goal: m.goal ?? ""
        )
    }

    func updateEdit(firstName: String? = nil, lastName: String? = nil, age: Int? = nil, heightCm: Double? = nil, weightKg: Double? = nil, goal: String? = nil) {
        guard var state = editProfileState else { return }
        if let v = firstName { state.firstName = v }
        if let v = lastName { state.lastName = v }
        if let v = age { state.age = v }
        if let v = heightCm { state.heightCm = v }
        if let v = weightKg { state.weightKg = v }
        if let v = goal { state.goal = v }
        editProfileState = state
    }

    func saveProfile(avatarImageData: Data? = nil) async {
        guard let m = member, let edit = editProfileState else { return }
        isSaving = true
        do {
            var avatarUrl: String? = nil
            if let data = avatarImageData, !data.isEmpty {
                let ext = "jpg"
                avatarUrl = try await memberRepository.uploadAvatar(memberId: m.id, imageData: data, fileExtension: ext)
            }
            try await memberRepository.updateProfile(
                firstName: edit.firstName.isEmpty ? nil : edit.firstName,
                lastName: edit.lastName.isEmpty ? nil : edit.lastName,
                age: edit.age,
                heightCm: edit.heightCm,
                weightKg: edit.weightKg,
                goal: edit.goal.isEmpty ? nil : edit.goal,
                avatarUrl: avatarUrl
            )
            editProfileState = nil
            await loadProfile()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }

    func signOut() async {
        try? await authRepository.signOut()
    }
}
