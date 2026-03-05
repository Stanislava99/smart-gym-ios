//
//  Exercise.swift
//  SmartGym
//

import Foundation

struct ExerciseCatalog: Decodable {
    let exercises: [Exercise]
}

struct Exercise: Decodable, Identifiable {
    typealias MuscleId = String

    let id: String
    let name: String
    let category: String
    let equipment: String?
    let difficulty: String?
    let primaryMuscles: [MuscleId]
    let secondaryMuscles: [MuscleId]
    let instructions: [String]
}

