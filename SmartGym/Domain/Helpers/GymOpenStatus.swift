//
//  GymOpenStatus.swift
//  SmartGym
//

import Foundation

/// Computes whether a gym is open now based on working hours.
enum GymOpenStatus {
    case open
    case closed
    case unknown  // no hours configured

    /// Human-readable status for today's hours
    static func status(workingHours: [GymWorkingHours], now: Date = Date()) -> GymOpenStatus {
        let calendar = Calendar.current
        // Swift: 1=Sun, 2=Mon, ..., 7=Sat. DB: 1=Mon, 2=Tue, ..., 7=Sun
        let swiftWeekday = calendar.component(.weekday, from: now)
        let dbDayOfWeek = swiftWeekday == 1 ? 7 : swiftWeekday - 1

        guard let today = workingHours.first(where: { $0.dayOfWeek == dbDayOfWeek }) else {
            return .unknown
        }
        if today.isClosed {
            return .closed
        }
        guard let openStr = today.openTime, let closeStr = today.closeTime else {
            return .unknown
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = calendar.timeZone

        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let dayStart = calendar.date(from: components),
              let openDate = parseTime(openStr, on: dayStart, formatter: formatter),
              let closeDate = parseTime(closeStr, on: dayStart, formatter: formatter) else {
            return .unknown
        }

        // Handle close time past midnight (e.g. 23:00–01:00)
        let closeAdjusted = closeDate < openDate ? calendar.date(byAdding: .day, value: 1, to: closeDate) ?? closeDate : closeDate

        if now >= openDate && now <= closeAdjusted {
            return .open
        }
        return .closed
    }

    /// Format today's hours for display, e.g. "10:00 – 22:00" or "Closed today"
    static func hoursText(workingHours: [GymWorkingHours], now: Date = Date()) -> String? {
        let calendar = Calendar.current
        let swiftWeekday = calendar.component(.weekday, from: now)
        let dbDayOfWeek = swiftWeekday == 1 ? 7 : swiftWeekday - 1

        guard let today = workingHours.first(where: { $0.dayOfWeek == dbDayOfWeek }) else {
            return nil
        }
        if today.isClosed {
            return "Closed today"
        }
        guard let openStr = today.openTime, let closeStr = today.closeTime else {
            return nil
        }
        let parseFmt = DateFormatter()
        parseFmt.dateFormat = "HH:mm"
        parseFmt.timeZone = calendar.timeZone

        let components = calendar.dateComponents([.year, .month, .day], from: now)
        guard let dayStart = calendar.date(from: components),
              let openDate = parseTime(openStr, on: dayStart, formatter: parseFmt),
              let closeDate = parseTime(closeStr, on: dayStart, formatter: parseFmt) else {
            return "\(openStr) – \(closeStr)"
        }

        let displayFmt = DateFormatter()
        displayFmt.dateFormat = "HH:mm"
        displayFmt.timeZone = calendar.timeZone
        return "\(displayFmt.string(from: openDate)) – \(displayFmt.string(from: closeDate))"
    }

    private static func parseTime(_ s: String, on day: Date, formatter: DateFormatter) -> Date? {
        let trimmed = String(s.prefix(5))  // "HH:mm"
        guard let parsed = formatter.date(from: trimmed) else { return nil }
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: parsed)
        return cal.date(bySettingHour: comps.hour ?? 0, minute: comps.minute ?? 0, second: 0, of: day)
    }
}
