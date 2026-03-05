//
//  Plan.swift
//  SmartGym
//
//  Subscription plan per gym (title, duration, price)
//

import Foundation

struct Plan {
    let id: String
    let gymId: String
    let title: String
    let durationDays: Int
    let description: String?
    let price: Double
}
