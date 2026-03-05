//
//  GymWorkingHours.swift
//  SmartGym
//

import Foundation

/// Working hours for one weekday. dayOfWeek: 1=Monday .. 7=Sunday (ISO)
struct GymWorkingHours {
    let dayOfWeek: Int
    let openTime: String?   // "HH:mm" or "HH:mm:ss"
    let closeTime: String?
    let isClosed: Bool
}
