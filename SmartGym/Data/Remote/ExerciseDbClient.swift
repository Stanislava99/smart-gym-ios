//
//  ExerciseDbClient.swift
//  SmartGym
//

import Foundation
import OSLog

struct ExerciseDbExercise: Decodable, Identifiable {
    let id: String
    let name: String
    let bodyPart: String?
    let target: String?
    let equipment: String?
    let instructions: String?
}

final class ExerciseDbClient {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "SmartGym",
        category: "ExerciseSearch"
    )

    /// Searches exercises in the external exercise database.
    /// Currently disabled and returns an empty array.
    func search(
        query: String,
        bodyPart: String? = nil,
        target: String? = nil,
        limit: Int = 20
    ) async throws -> [ExerciseDbExercise] {
        let requestId = UUID().uuidString
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else {
            logger.debug("Exercise search skipped (empty query). requestId=\(requestId, privacy: .public)")
            return []
        }
        
        logger.debug(
            "Exercise search disabled (external spec removed). requestId=\(requestId, privacy: .public)"
        )
        return []
    }
}


