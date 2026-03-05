//
//  PaymentRepository.swift
//  SmartGym
//

import Foundation
import Supabase

private struct PaymentRow: Decodable {
    let id: String
    let amount: Double
    let paymentDate: String
    let paymentMethod: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id
        case amount
        case paymentDate = "payment_date"
        case paymentMethod = "payment_method"
        case notes
    }

    var toPayment: Payment {
        Payment(
            id: id,
            amount: amount,
            paymentDate: paymentDate,
            paymentMethod: paymentMethod,
            notes: notes
        )
    }
}

final class PaymentRepository {
    private let client = AppSupabase.client

    func getPaymentsByMemberId(memberId: String) async throws -> [Payment] {
        let rows: [PaymentRow] = try await client
            .from("payments")
            .select()
            .eq("member_id", value: memberId)
            .order("payment_date", ascending: false)
            .execute()
            .value
        return rows.map(\.toPayment)
    }
}
