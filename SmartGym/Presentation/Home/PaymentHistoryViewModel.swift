//
//  PaymentHistoryViewModel.swift
//  SmartGym
//

import Foundation

@MainActor
@Observable
final class PaymentHistoryViewModel {
    var member: Member?
    var payments: [Payment] = []
    var isLoading = true
    var error: String?

    private let memberRepository = MemberRepository()
    private let paymentRepository = PaymentRepository()

    init() {
        Task { await load() }
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            member = try await memberRepository.getCurrentMember()
            if let memberId = member?.id {
                payments = try await paymentRepository.getPaymentsByMemberId(memberId: memberId)
            } else {
                payments = []
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
