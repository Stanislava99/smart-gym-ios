//
//  MemberWeightLog.swift
//  SmartGym
//

import Foundation

struct MemberWeightLog: Identifiable, Equatable {
    let id: String
    let userId: String
    let memberId: String
    let gymId: String
    let loggedAt: String
    let weightKg: Double
    let notes: String?

    var loggedDate: Date {
        Self.dateFormatter.date(from: loggedAt) ?? Date.distantPast
    }

    static func storageDateString(from date: Date) -> String {
        dateFormatter.string(from: date)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
