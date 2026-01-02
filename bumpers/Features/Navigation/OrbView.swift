//
//  OrbView.swift
//  bumpers
//
//  Animated orb that conveys temperature zone and directionality.
//

import SwiftUI

struct OrbView: View {
    let zone: TemperatureZone
    let directionShift: Double
    let bumpTrigger: Int

    var body: some View {
        Circle()
            .fill(orbGradient)
            .frame(width: Theme.orbSize, height: Theme.orbSize)
            .shadow(color: zone.colors.inner.opacity(0.25), radius: 24, x: 0, y: 12)
            .animation(Theme.gradientTransition, value: zone)
            .animation(Theme.standardSpring, value: directionShift)
            .pulse()
            .bump(trigger: bumpTrigger)
    }

    private var orbGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: zone.colors.inner, location: 0),
                .init(color: zone.colors.outer, location: 0.55),
                .init(color: Theme.background, location: 1)
            ]),
            center: gradientCenter,
            startRadius: 0,
            endRadius: Theme.orbSize * 0.6
        )
    }

    private var gradientCenter: UnitPoint {
        let clampedShift = max(-1, min(1, directionShift))
        let shiftAmount = 0.22
        let x = min(max(0.5 + (clampedShift * shiftAmount), 0.05), 0.95)
        return UnitPoint(x: x, y: 0.5)
    }
}

#Preview {
    ZStack {
        Theme.background
            .ignoresSafeArea()

        OrbView(zone: .warm, directionShift: 0.5, bumpTrigger: 1)
    }
}
