//
//  OrbView.swift
//  bumpers
//
//  The glowing core — a simple gradient sphere.
//  Shadows and diffusion are handled by NavigationView's glow layers.
//

import SwiftUI

struct OrbView: View {
    let zone: TemperatureZone
    let signal: FieldOrbSignal
    let bumpTrigger: Int

    var body: some View {
        ZStack {
            // Main orb gradient
            Circle()
                .fill(orbGradient)

            // Subtle highlight (3D glass effect)
            Circle()
                .fill(highlightGradient)

            if signal.isAlive && !signal.isDirectionalCorrection {
                Circle()
                    .stroke(zone.colors.inner.opacity(0.18), lineWidth: 2)
                    .scaleEffect(1.08)
                    .blur(radius: 1)
            }
        }
        .frame(width: Theme.orbSize, height: Theme.orbSize)
        // GPU-optimized rendering
        .drawingGroup()
        // Smooth zone transitions
        .animation(Theme.smoothSpring, value: zone)
        .animation(Theme.snappySpring, value: signal.shift)
        // Bump animation on haptic
        .orbAnimation(zone: zone, bumpTrigger: bumpTrigger)
    }

    // MARK: - Gradient

    /// Vibrant gradient with sharper color zones and soft edge
    private var orbGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(stops: gradientStops),
            center: gradientCenter,
            startRadius: 0,
            endRadius: Theme.orbSize * 0.5
        )
    }

    private var gradientStops: [Gradient.Stop] {
        [
            // Core — pure inner color
            .init(color: zone.colors.inner, location: 0),
            // Hold inner color longer for vibrancy
            .init(color: zone.colors.inner, location: 0.25),
            // Transition to outer
            .init(color: zone.colors.outer, location: 0.55),
            // Outer color holds
            .init(color: zone.colors.outer.opacity(0.8), location: 0.75),
            // Soft fade to transparent (blends with glow layers)
            .init(color: zone.colors.outer.opacity(0.3), location: 0.9),
            .init(color: .clear, location: 1.0)
        ]
    }

    // MARK: - Directional Shift

    private var gradientCenter: UnitPoint {
        let clampedShift = max(-1, min(1, signal.shift))

        // X shift — moves hotspot left/right based on direction
        let x = 0.5 + (clampedShift * Theme.OrbGradient.shiftX)
        // Y shift — rises slightly when turning (3D depth illusion)
        let yOffset = abs(clampedShift) * Theme.OrbGradient.shiftY
        let y = 0.5 - yOffset

        return UnitPoint(
            x: min(max(x, 0.08), 0.92),
            y: min(max(y, 0.35), 0.55)
        )
    }

    // MARK: - Highlight

    private var highlightGradient: RadialGradient {
        let offset = Theme.OrbShadow.highlightOffset
        let highlightX = offset - (signal.shift * 0.08)
        let highlightY = offset + (abs(signal.shift) * 0.04)

        return RadialGradient(
            colors: [
                .white.opacity(Theme.OrbShadow.highlightOpacity),
                .white.opacity(Theme.OrbShadow.highlightOpacity * 0.3),
                .clear
            ],
            center: UnitPoint(x: highlightX, y: highlightY),
            startRadius: 0,
            endRadius: Theme.orbSize * Theme.OrbShadow.highlightRadius
        )
    }
}

// MARK: - Preview

#Preview("All Zones") {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack(spacing: 40) {
            HStack(spacing: 30) {
                OrbView(
                    zone: .hot,
                    signal: FieldOrbSignal(shift: 0, isAlive: true, isDirectionalCorrection: false),
                    bumpTrigger: 0
                )
                    .scaleEffect(0.5)
                OrbView(
                    zone: .warm,
                    signal: FieldOrbSignal(shift: 0.3, isAlive: true, isDirectionalCorrection: false),
                    bumpTrigger: 0
                )
                    .scaleEffect(0.5)
            }
            HStack(spacing: 30) {
                OrbView(
                    zone: .cool,
                    signal: FieldOrbSignal(shift: -0.5, isAlive: true, isDirectionalCorrection: true),
                    bumpTrigger: 0
                )
                    .scaleEffect(0.5)
                OrbView(
                    zone: .cold,
                    signal: FieldOrbSignal(shift: 0.7, isAlive: true, isDirectionalCorrection: true),
                    bumpTrigger: 0
                )
                    .scaleEffect(0.5)
            }
            OrbView(
                zone: .freezing,
                signal: FieldOrbSignal(shift: -0.9, isAlive: true, isDirectionalCorrection: true),
                bumpTrigger: 0
            )
                .scaleEffect(0.6)
        }
    }
}

#Preview("Interactive") {
    ZStack {
        Theme.background.ignoresSafeArea()
        OrbView(
            zone: .warm,
            signal: FieldOrbSignal(shift: 0.5, isAlive: true, isDirectionalCorrection: true),
            bumpTrigger: 1
        )
    }
}
