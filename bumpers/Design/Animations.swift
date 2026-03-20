//
//  Animations.swift
//  bumpers
//
//  Snappy animation modifiers for the orb.
//  Designed for immediate feedback and smooth 60fps performance.
//

import SwiftUI

// MARK: - Animation Presets

enum Animations {
    /// Ultra-snappy spring for haptic bump feedback
    static let bumpSpring = Animation.spring(response: 0.15, dampingFraction: 0.6)

    /// Quick recovery spring
    static let bumpReset = Animation.spring(response: 0.2, dampingFraction: 0.7)

    /// Smooth continuous pulse
    static let pulseSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
}

// MARK: - Unified Scale Modifier

/// Combines pulse and bump into a single scale state.
/// Prevents animation conflicts from multiple scaleEffect modifiers.
struct OrbScaleModifier: ViewModifier {
    let zone: TemperatureZone
    let bumpTrigger: Int

    @State private var pulsePhase: CGFloat = 0
    @State private var bumpScale: CGFloat = 1.0

    private var combinedScale: CGFloat {
        let pulseAmount = 1.0 + (sin(pulsePhase) * 0.5 + 0.5) * (zone.pulseScale - 1.0)
        return pulseAmount * bumpScale
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(combinedScale)
            .onChange(of: bumpTrigger) { _, _ in
                triggerBump()
            }
            .onAppear {
                startPulse()
            }
    }

    private func startPulse() {
        // Use a continuous timer for smooth pulsing
        withAnimation(
            .easeInOut(duration: Theme.orbPulseDuration)
            .repeatForever(autoreverses: true)
        ) {
            pulsePhase = .pi
        }
    }

    private func triggerBump() {
        // Immediate scale up
        withAnimation(Animations.bumpSpring) {
            bumpScale = 1.06
        }

        // Quick snap back
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(Animations.bumpReset) {
                bumpScale = 1.0
            }
        }
    }
}

// MARK: - Legacy Modifiers (for compatibility)

struct PulseModifier: ViewModifier {
    let scale: CGFloat
    let duration: Double

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

struct BumpModifier: ViewModifier {
    let trigger: Int
    let scale: CGFloat
    let duration: Double

    @State private var isBumping = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isBumping ? scale : 1)
            .onChange(of: trigger) { _, _ in
                triggerBump()
            }
    }

    private func triggerBump() {
        withAnimation(Animations.bumpSpring) {
            isBumping = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(Animations.bumpReset) {
                isBumping = false
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Unified orb animation (recommended)
    func orbAnimation(zone: TemperatureZone, bumpTrigger: Int) -> some View {
        modifier(OrbScaleModifier(zone: zone, bumpTrigger: bumpTrigger))
    }

    /// Legacy pulse animation
    func pulse(scale: CGFloat = Theme.orbPulseScale, duration: Double = Theme.orbPulseDuration) -> some View {
        modifier(PulseModifier(scale: scale, duration: duration))
    }

    /// Legacy bump animation
    func bump(trigger: Int, scale: CGFloat = 1.05, duration: Double = 0.1) -> some View {
        modifier(BumpModifier(trigger: trigger, scale: scale, duration: duration))
    }
}
