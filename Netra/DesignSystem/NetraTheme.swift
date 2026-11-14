//
//  NetraTheme.swift
//  Netra
//
//  One source of truth for colour, spacing, radius and type.
//

import SwiftUI
import Foundation
import UIKit

// MARK: - Dynamic colour helper

nonisolated enum DynamicColor {
    static func make(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(
                red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1
            )
        }
    }
}

extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: DynamicColor.make(light: light, dark: dark))
    }
}

// MARK: - Theme

enum NetraTheme {

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    static let cornerRadius: CGFloat = 20
    static let smallRadius: CGFloat = 12
    static let maxContentWidth: CGFloat = 720

    // Brand — navy #0F1B3D on white #FFFFFF.
    // In dark mode the navy becomes the surface and a pale navy tint
    // becomes the accent, so contrast stays high.
    static let navy = Color(light: 0x0F1B3D, dark: 0x0F1B3D)
    static let brand = Color(light: 0x0F1B3D, dark: 0xC7D2F5)
    static let violet = Color(light: 0x3A4A7A, dark: 0x9FB0E8)   // secondary navy tint

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [Color(light: 0x0F1B3D, dark: 0x1E3A8A), Color(light: 0x1B2D63, dark: 0x0F1B3D)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // Surfaces
    static let background = Color(light: 0xFFFFFF, dark: 0x0A1226)
    static let card = Color(light: 0xFFFFFF, dark: 0x0F1B3D)
    static let cardStroke = Color(light: 0xDDE2EF, dark: 0x24366B)
    static let track = Color(light: 0xE6E9F3, dark: 0x24366B)
    static let shadow = Color(light: 0x0F1B3D, dark: 0x000000)

    // Status
    static let good = Color(light: 0x16A34A, dark: 0x34D399)
    static let ok = Color(light: 0x0D9488, dark: 0x2DD4BF)
    static let warn = Color(light: 0xD97706, dark: 0xFBBF24)
    static let bad = Color(light: 0xDC2626, dark: 0xF87171)

    static func scoreColor(_ score: Int) -> Color {
        switch score {
        case 90...: good
        case 75..<90: ok
        case 50..<75: warn
        default: bad
        }
    }

    static func riskColor(_ risk: TrackerRisk) -> Color {
        switch risk {
        case .high: bad
        case .medium: warn
        case .low: ok
        }
    }

    static func severityColor(_ severity: NetraAlert.Severity) -> Color {
        switch severity {
        case .critical: bad
        case .warning: warn
        case .info: brand
        case .safe: good
        }
    }
}

// MARK: - Typography

enum NetraFont {
    static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let title = Font.system(.title2, design: .rounded).weight(.bold)
    static let headline = Font.system(.headline, design: .rounded)
    static let body = Font.system(.body)
    static let callout = Font.system(.callout)
    static let caption = Font.system(.caption)
    static func number(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
}
