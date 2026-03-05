//
//  ExerciseJsonLoader.swift
//  SmartGym
//

import Foundation

enum ExerciseJsonLoader {
    static func loadCatalog() throws -> ExerciseCatalog {
        guard let url = Bundle.main.url(forResource: "gym_exercises_database", withExtension: "json") else {
            print("ExerciseJsonLoader: gym_exercises_database.json not found in bundle")
            throw NSError(domain: "ExerciseJsonLoader", code: 1, userInfo: [NSLocalizedDescriptionKey: "gym_exercises_database.json not found in bundle"])
        }
        let data = try Data(contentsOf: url)
        print("ExerciseJsonLoader: Loaded JSON data with \(data.count) bytes")
        let decoder = JSONDecoder()
        let catalog = try decoder.decode(ExerciseCatalog.self, from: data)
        print("ExerciseJsonLoader: Decoded \(catalog.exercises.count) exercises")
        return catalog
    }
}

