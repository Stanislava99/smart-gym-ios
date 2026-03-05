//
//  Member.swift
//  SmartGym
//

import Foundation

struct Member {
    let id: String
    let userId: String?
    let gymId: String
    let fullName: String
    let firstName: String?
    let lastName: String?
    let email: String
    let phone: String
    let planId: String?
    let status: String
    let subscriptionStartDate: String?
    let subscriptionEndDate: String?
    let avatarUrl: String?
    let age: Int?
    let heightCm: Double?
    let weightKg: Double?
    let goal: String?

    var displayName: String {
        if let first = firstName, !first.isEmpty, let last = lastName, !last.isEmpty {
            return "\(first) \(last)"
        }
        if let first = firstName, !first.isEmpty { return first }
        if let last = lastName, !last.isEmpty { return last }
        return fullName
    }
}
