//
//  PTPackage.swift
//  SmartGym
//
//  Personal training package definition
//

import Foundation

struct PTPackage {
    let id: String
    let gymId: String
    let name: String
    let sessionsCount: Int
    let price: Double
    let durationDays: Int?
    let description: String?
}
