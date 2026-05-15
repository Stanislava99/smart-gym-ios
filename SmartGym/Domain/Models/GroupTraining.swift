//
//  GroupTraining.swift
//  SmartGym
//

import Foundation

struct GroupTraining: Identifiable, Equatable {
    let id: String
    let gymId: String
    let trainerId: String
    let title: String
    let price: Double
    let description: String?
    let isActive: Bool
    let trainerName: String?
    let slots: [GroupTrainingSlot]
}

struct GroupTrainingSlot: Identifiable, Equatable {
    let id: String
    let groupTrainingId: String
    let weekday: Int
    let startTime: String
    let endTime: String?
}

struct NextGroupTraining: Equatable {
    let groupTitle: String
    let trainerName: String?
    let dateIso: String
    let startTime: String
    let endTime: String?
}
