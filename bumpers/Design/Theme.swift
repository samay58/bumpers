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

    // MARK: - Surfaces

    static let surfaceSubtle = Color.white.opacity(0.04)
    static let surfaceDefault = Color.white.opacity(0.06)
    static let surfaceElevated = Color.white.opacity(0.08)
    static let surfaceHighlight = Color.white.opacity(0.10)
    static let borderSubtle = Color.white.opacity(0.06)
    static let borderDefault = Color.white.opacity(0.08)
    static let borderElevated = Color.white.opacity(0.10)

    // MARK: - Text Colors

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.6)
    static let textTertiary = Color.white.opacity(0.4)

    // MARK: - Typography
    // Using Quicksand — a rounded geometric sans-serif for warmth

    static func quicksand(size: CGFloat, weight: Font.Weight) -> Font {
        Font.custom("Quicksand", size: size).weight(weight)
    }

    static let displayFont = quicksand(size: 32, weight: .ultraLight)
    static let screenTitleFont = quicksand(size: 28, weight: .light)
    static let sheetTitleFont = quicksand(size: 24, weight: .light)
    static let titleFont = quicksand(size: 22, weight: .light)
    static let distanceFont = quicksand(size: 48, weight: .regular)
    static let statValueFont = quicksand(size: 20, weight: .light)
    static let headlineFont = quicksand(size: 18, weight: .regular)
    static let buttonFont = quicksand(size: 17, weight: .medium)
    static let bodyFont = quicksand(size: 16, weight: .medium)
    static let captionFont = quicksand(size: 14, weight: .regular)
    static let sectionHeaderFont = quicksand(size: 13, weight: .medium)
    static let labelFont = quicksand(size: 12, weight: .medium)
    static let debugFont = Font.system(size: 11, weight: .medium, design: .monospaced)

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 48
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 14
    }

    // MARK: - Layout

    static let orbSize: CGFloat = 280  // Larger, screen-dominant
    static let orbPulseScale: CGFloat = 1.025
    static let orbPulseDuration: Double = 1.2

    // MARK: - Glow Animation (Full-Screen)

    /// Duration of the ambient glow pulse (slow, meditative breathing)
    static let glowPulseDuration: Double = 2.4
    /// Scale expansion of glow layers during pulse
    static let glowPulseScale: CGFloat = 1.15

    // MARK: - Animation

    /// Snappy spring for immediate feedback (buttons, toggles)
    static let snappySpring = Animation.spring(response: 0.25, dampingFraction: 0.7)

    /// Standard spring for UI elements
    static let standardSpring = Animation.spring(response: 0.35, dampingFraction: 0.75)

    /// Smooth spring for gradient/color transitions
    static let smoothSpring = Animation.spring(response: 0.4, dampingFraction: 0.85)

    /// Fast gradient transition (was 0.6s, now 0.3s)
    static let gradientTransition = Animation.easeOut(duration: 0.3)

    // MARK: - Orb Shadow System

    /// Multi-layer shadow configuration for premium depth.
    /// Applied in order: ambient (outermost) → drop → glow (innermost).
    enum OrbShadow {
        /// Soft ambient shadow — creates ground plane (optimized radius)
        static let ambient = ShadowStyle(
            radius: 40,  // Reduced from 60 for performance
            y: 20,
            opacity: 0.15
        )

        /// Inner glow — zone-colored warmth
        static let glow = ShadowStyle(
            radius: 16,
            y: 0,
            opacity: 0.4
        )

        /// Highlight offset for 3D reflection
        static let highlightOffset: CGFloat = 0.28
        static let highlightOpacity: Double = 0.12
        static let highlightRadius: CGFloat = 0.35
    }

    // MARK: - Orb Gradient

    enum OrbGradient {
        /// Gradient falloff position for relaxed zones (hot, warm)
        static let falloffRelaxed: Double = 0.55
        /// Gradient falloff position for urgent zones (cold, freezing) — steeper
        static let falloffUrgent: Double = 0.42
        /// End radius multiplier
        static let endRadiusMultiplier: CGFloat = 0.58
        /// Directional shift amount (X-axis)
        static let shiftX: Double = 0.18
        /// Directional shift amount (Y-axis) — rises when turning
        static let shiftY: Double = 0.06
    }
}

// MARK: - Shadow Style

struct ShadowStyle {
    let radius: CGFloat
    let y: CGFloat
    let opacity: Double

    /// Apply this shadow to a view with a given color
    func apply(to color: Color) -> some View {
        Color.clear
            .shadow(color: color.opacity(opacity), radius: radius, x: 0, y: y)
    }
}

// MARK: - Bumper Button Style

enum BumperButtonVariant {
    case primary
    case secondary
}

struct BumperButtonStyle: ViewModifier {
    let variant: BumperButtonVariant

    func body(content: Content) -> some View {
        content
            .font(Theme.buttonFont)
            .foregroundStyle(variant == .primary ? Theme.background : Theme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.lg)
            .background(variant == .primary ? AnyShapeStyle(Theme.warm.inner) : AnyShapeStyle(Theme.surfaceElevated))
            .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.lg))
            .overlay(
                variant == .secondary
                    ? RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                        .stroke(Theme.borderElevated, lineWidth: 1)
                    : nil
            )
            .pressable()
    }
}

extension View {
    func bumperButton(_ variant: BumperButtonVariant = .primary) -> some View {
        modifier(BumperButtonStyle(variant: variant))
    }
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
