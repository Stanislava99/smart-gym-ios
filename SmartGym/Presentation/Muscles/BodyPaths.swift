//
//  BodyPaths.swift
//  SmartGym
//
//  Loads body path data from Resources/body_paths.json (maleFront, maleBack, femaleFront, femaleBack).
//

import Foundation

/// Per-slug path data: left, right, and common path strings (SVG "d" format).
struct SluggedPathSet: Codable {
    let left: [String]
    let right: [String]
    let common: [String]

    static let empty = SluggedPathSet(left: [], right: [], common: [])
}

/// Root JSON shape: { "maleFront": { "chest": { "left": [...], "right": [...], "common": [] }, ... }, ... }
struct BodyPathsRoot: Codable {
    let maleFront: [String: SluggedPathSet]?
    let maleBack: [String: SluggedPathSet]?
    let femaleFront: [String: SluggedPathSet]?
    let femaleBack: [String: SluggedPathSet]?

    enum CodingKeys: String, CodingKey {
        case maleFront
        case maleBack
        case femaleFront
        case femaleBack
    }
}

enum BodyPathsLoader {
    private static var cached: BodyPathsRoot?

    /// Load body paths from bundle (Resources/body_paths.json). Cached after first load.
    static func loadFromBundle() -> BodyPathsRoot? {
        if let c = cached { return c }
        guard let url = Bundle.main.url(forResource: "body_paths", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(BodyPathsRoot.self, from: data) else {
            return nil
        }
        cached = decoded
        return decoded
    }

    /// Returns slug -> path set for the given side and gender.
    static func paths(side: BodySide, gender: BodyGender) -> [String: SluggedPathSet] {
        guard let root = loadFromBundle() else { return [:] }
        switch (side, gender) {
        case (.front, .male): return root.maleFront ?? [:]
        case (.back, .male): return root.maleBack ?? [:]
        case (.front, .female): return root.femaleFront ?? [:]
        case (.back, .female): return root.femaleBack ?? [:]
        }
    }
}

enum BodySide { case front, back }
enum BodyGender { case male, female }
