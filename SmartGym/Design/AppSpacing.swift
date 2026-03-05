//
//  AppSpacing.swift
//  SmartGym
//
//  Design system spacing from DESIGN_SYSTEM_PROFILE.md
//

import SwiftUI

enum AppSpacing {
    /// Base: 4px, Scale: 4, 8, 12, 16, 20, 24, 32, 40, 48, 64
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
    static let huge: CGFloat = 48
    static let massive: CGFloat = 64

    /// Outer screen padding: 16–24px
    static let screenHorizontal: CGFloat = 20
    static let screenVertical: CGFloat = 16

    /// Gap between stacked cards: 12–16px
    static let cardGap: CGFloat = 14
}
