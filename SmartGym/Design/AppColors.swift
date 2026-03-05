//
//  AppColors.swift
//  SmartGym
//
//  Design system colors from DESIGN_SYSTEM_PROFILE.md
//

import SwiftUI

enum AppColors {
    // Primary
    static let canvas = Color(hex: "f8f8f8")
    static let surface = Color.white
    static let textPrimary = Color(hex: "0d101b")
    static let textSecondary = Color(hex: "666666")
    static let textTertiary = Color(hex: "999999")

    // Accents
    static let accentLavender = Color(hex: "b3a0ff")
    static let accentBlue = Color(hex: "a0c6ff")
    static let accentOrange = Color(hex: "FFB200")
    static let accentMint = Color(hex: "A0E2A0")
    static let accentPeach = Color(hex: "FFA84C")

    // Neutral & UI
    static let neutralDark = Color(hex: "0d101b")
    static let neutralLight = Color(hex: "f8f8f8")
    static let borderSubtle = Color(hex: "E5E5E5")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
