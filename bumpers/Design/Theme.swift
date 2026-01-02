//
//  Theme.swift
//  bumpers
//
//  Colors, typography, and design constants for Bumper.
//

import SwiftUI

enum Theme {

    // MARK: - Background

    static let background = Color(hex: "0A0A0A")

    // MARK: - Temperature Gradient Colors
    // Each tuple is (inner/hot center, outer/edge)

    static let freezing = (
        inner: Color(hex: "667EEA"),
        outer: Color(hex: "764BA2")
    )

    static let cold = (
        inner: Color(hex: "06B6D4"),
        outer: Color(hex: "3B82F6")
    )

    static let cool = (
        inner: Color(hex: "84CC16"),
        outer: Color(hex: "22D3D1")
    )

    static let warm = (
        inner: Color(hex: "F59E0B"),
        outer: Color(hex: "EF4444")
    )

    static let hot = (
        inner: Color(hex: "EF4444"),
        outer: Color(hex: "DC2626")
    )

    // MARK: - Text Colors

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.4)

    // MARK: - Typography

    static let titleFont = Font.system(size: 20, weight: .light, design: .default)
    static let headlineFont = Font.system(size: 17, weight: .light, design: .default)
    static let bodyFont = Font.system(size: 15, weight: .regular, design: .default)
    static let captionFont = Font.system(size: 13, weight: .light, design: .default)
    static let debugFont = Font.system(size: 11, weight: .medium, design: .monospaced)

    // MARK: - Layout

    static let orbSize: CGFloat = 200
    static let orbPulseScale: CGFloat = 1.02
    static let orbPulseDuration: Double = 2.0

    // MARK: - Animation

    static let standardSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let gradientTransition = Animation.easeInOut(duration: 0.5)
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
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
