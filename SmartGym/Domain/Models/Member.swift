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
    let birthDate: String?
    let fallbackAge: Int?
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

    var age: Int? {
        Self.age(from: birthDate) ?? fallbackAge
    }

    private static func age(from birthDate: String?) -> Int? {
        guard let birthDate else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: birthDate) else { return nil }
        return Calendar.current.dateComponents([.year], from: date, to: Date()).year
    }
}
