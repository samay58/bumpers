//
//  Animations.swift
//  bumpers
//
//  Shared animation modifiers for pulse and bump effects.
//

import SwiftUI

enum Animations {
    static let bumpSpring = Animation.spring(response: 0.2, dampingFraction: 0.65)
    static let bumpResetSpring = Animation.spring(response: 0.25, dampingFraction: 0.8)
}

struct PulseModifier: ViewModifier {
    let scale: CGFloat
    let duration: Double

    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
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
            .onChange(of: trigger) { _ in
                triggerBump()
            }
    }

    private func triggerBump() {
        withAnimation(Animations.bumpSpring) {
            isBumping = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            withAnimation(Animations.bumpResetSpring) {
                isBumping = false
            }
        }
    }
}

extension View {
    func pulse(scale: CGFloat = Theme.orbPulseScale, duration: Double = Theme.orbPulseDuration) -> some View {
        modifier(PulseModifier(scale: scale, duration: duration))
    }

    func bump(trigger: Int, scale: CGFloat = 1.04, duration: Double = 0.12) -> some View {
        modifier(BumpModifier(trigger: trigger, scale: scale, duration: duration))
    }
}
