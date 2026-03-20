//
//  ArrivalView.swift
//  bumpers
//
//  The quiet celebration — you made it.
//

import SwiftUI

struct ArrivalView: View {
    let destination: Destination
    let walkDuration: TimeInterval
    let totalDistance: Double
    let journey: Journey?

    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false

    // Haptic service for arrival celebration
    private let hapticService = HapticService()

    // Staggered entrance delays (hand-crafted uneven timing)
    private let orbDelay: Double = 0.1
    private let titleDelay: Double = 0.3
    private let subtitleDelay: Double = 0.5
    private let mapDelay: Double = 0.6
    private let statsDelay: Double = 0.8
    private let buttonDelay: Double = 1.1

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Arrival orb — warm glow, stationary
                arrivalOrb
                    .padding(.bottom, Theme.Spacing.xxxl)

                // Message
                Text("You're here")
                    .font(Theme.displayFont)
                    .foregroundStyle(Theme.textPrimary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                    .animation(.easeOut(duration: 0.8).delay(titleDelay), value: appeared)

                Text(destination.name)
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 8)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.6).delay(subtitleDelay), value: appeared)

                Spacer()

                // Journey map (if available)
                if let journey = journey, journey.points.count > 2 {
                    JourneyMapView(journey: journey)
                        .frame(height: 180)
                        .padding(.horizontal, Theme.Spacing.xl)
                        .padding(.bottom, Theme.Spacing.xl)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 30)
                        .animation(.easeOut(duration: 0.7).delay(mapDelay), value: appeared)
                }

                // Journey stats
                journeyStats
                    .padding(.bottom, Theme.Spacing.xxxl)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(.easeOut(duration: 0.6).delay(statsDelay), value: appeared)

                // Done button
                doneButton
                    .padding(.horizontal, Theme.Spacing.xxl)
                    .padding(.bottom, 60)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.5).delay(buttonDelay), value: appeared)
            }
        }
        .statusBarHidden(true)
        .onAppear {
            appeared = true

            // Play celebratory haptic crescendo
            hapticService.prepare()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                hapticService.playArrival()
            }
        }
    }

    // MARK: - Arrival Orb

    private var arrivalOrb: some View {
        Circle()
            .fill(arrivalGradient)
            .frame(width: 160, height: 160)
            .shadow(color: Theme.warm.inner.opacity(0.3), radius: 40, x: 0, y: 20)
            .scaleEffect(appeared ? 1 : 0.8)
            .opacity(appeared ? 1 : 0)
            .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(orbDelay), value: appeared)
    }

    private var arrivalGradient: RadialGradient {
        RadialGradient(
            gradient: Gradient(stops: [
                .init(color: Theme.hot.inner, location: 0),
                .init(color: Theme.warm.inner, location: 0.4),
                .init(color: Theme.warm.outer.opacity(0.6), location: 0.7),
                .init(color: Theme.background, location: 1)
            ]),
            center: .center,
            startRadius: 0,
            endRadius: 90
        )
    }

    // MARK: - Journey Stats

    private var journeyStats: some View {
        HStack(spacing: Theme.Spacing.xxl) {
            statItem(value: formattedDuration, label: "walked")

            divider

            statItem(value: formattedDistance, label: "traveled")

            if let wander = wanderFactorString {
                divider
                statItem(value: wander, label: "wander")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(statsAccessibilityLabel)
    }

    private var wanderFactorString: String? {
        guard let journey = journey, journey.wanderFactor > 1.05 else { return nil }
        return String(format: "%.1f×", journey.wanderFactor)
    }

    private var statsAccessibilityLabel: String {
        var label = "You walked \(formattedDuration) and traveled \(formattedDistance)"
        if let wander = wanderFactorString {
            label += ". Wander factor \(wander)"
        }
        return label
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text(value)
                .font(Theme.statValueFont)
                .foregroundStyle(Theme.textPrimary)

            Text(label)
                .font(Theme.labelFont)
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.surfaceHighlight)
            .frame(width: 1, height: 32)
    }

    // MARK: - Done Button

    private var doneButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Done")
                .bumperButton(.secondary)
        }
    }

    // MARK: - Formatting

    private var formattedDuration: String {
        let minutes = Int(walkDuration / 60)
        if minutes < 1 {
            return "<1 min"
        } else if minutes == 1 {
            return "1 min"
        } else {
            return "\(minutes) min"
        }
    }

    private var formattedDistance: String {
        let measurement = Measurement(value: totalDistance, unit: UnitLength.meters)
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter.string(from: measurement)
    }
}

// MARK: - Preview

#Preview {
    ArrivalView(
        destination: .testDestination,
        walkDuration: 847, // ~14 min
        totalDistance: 1240, // 1.24 km
        journey: nil
    )
}
