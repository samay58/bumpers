//
//  NavigationView.swift
//  bumpers
//
//  Core navigation screen — orb as light source with full-screen glow.
//

import SwiftUI
import CoreLocation

struct NavigationView: View {

    // MARK: - Properties

    @State var viewModel: NavigationViewModel
    @State private var showDebug = false
    @State private var showArrival = false
    @Environment(\.dismiss) private var dismiss

    // Glow animation state
    @State private var glowIntensity: Double = 0.5
    @State private var glowScale: CGFloat = 1.0

    // MARK: - Body

    var body: some View {
        ZStack {
            // Layer 0: Background
            Theme.background
                .ignoresSafeArea()

            if !viewModel.isLocationAuthorized {
                // Permission required
                PermissionView(
                    authorizationStatus: viewModel.locationService.authorizationStatus,
                    onRequestPermission: {
                        viewModel.locationService.requestPermission()
                    }
                )
            } else {
                // Layer 1: Full-screen ambient glow
                ambientGlow

                // Layer 2: Diffusion layers (blurred halos)
                diffusionLayers

                // Layer 3: Core orb
                orbCore

                // Layer 4: Floating UI (destination, distance)
                navigationUI

                // No heading warning (overlay at bottom)
                if !viewModel.hasHeading && viewModel.isNavigating {
                    noHeadingWarning
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 140)
                }
            }

            // Debug overlay
            if showDebug && viewModel.isLocationAuthorized {
                debugOverlay
            }
        }
        .onTapGesture(count: 3) {
            showDebug.toggle()
        }
        .onChange(of: viewModel.hasArrived) { _, arrived in
            if arrived {
                showArrival = true
            }
        }
        .fullScreenCover(isPresented: $showArrival) {
            ArrivalView(
                destination: viewModel.destination,
                walkDuration: viewModel.startTime.map { Date().timeIntervalSince($0) } ?? 0,
                totalDistance: viewModel.totalDistance,
                journey: viewModel.buildJourney()
            )
            .onDisappear {
                dismiss()
            }
        }
        .onAppear {
            viewModel.startNavigation()
            startAmbientPulse()
        }
        .onDisappear {
            viewModel.stopNavigation()
        }
        .navigationBarBackButtonHidden(true)
        .statusBarHidden(true)
    }

    // MARK: - Glow Animation

    private func startAmbientPulse() {
        withAnimation(
            .easeInOut(duration: Theme.glowPulseDuration)
            .repeatForever(autoreverses: true)
        ) {
            glowIntensity = 1.0
            glowScale = Theme.glowPulseScale
        }
    }

    // MARK: - Layer 1: Ambient Glow (Full-Screen)

    private var ambientGlow: some View {
        GeometryReader { geo in
            RadialGradient(
                colors: [
                    viewModel.zone.colors.inner.opacity(glowIntensity * 0.20),
                    viewModel.zone.colors.outer.opacity(glowIntensity * 0.07),
                    .clear
                ],
                center: .center,
                startRadius: 0,
                endRadius: geo.size.height * 0.65
            )
        }
        .ignoresSafeArea()
        .animation(Theme.smoothSpring, value: viewModel.zone)
    }

    // MARK: - Layer 2: Diffusion Layers

    private var diffusionLayers: some View {
        ZStack {
            // Outer halo — large, very soft
            Circle()
                .fill(viewModel.zone.colors.inner.opacity(0.08))
                .scaleEffect(glowScale * 2.2)
                .blur(radius: 120)

            // Middle glow — medium diffusion
            Circle()
                .fill(viewModel.zone.colors.inner.opacity(0.14))
                .scaleEffect(glowScale * 1.7)
                .blur(radius: 70)

            // Inner glow — tighter, more saturated
            Circle()
                .fill(viewModel.zone.colors.inner.opacity(0.20))
                .scaleEffect(glowScale * 1.25)
                .blur(radius: 35)
        }
        .frame(width: Theme.orbSize, height: Theme.orbSize)
        .animation(Theme.smoothSpring, value: viewModel.zone)
    }

    // MARK: - Layer 3: Core Orb

    private var orbCore: some View {
        OrbView(
            zone: viewModel.zone,
            signal: viewModel.orbSignal,
            bumpTrigger: viewModel.hapticPulseID
        )
        .scaleEffect(1.0 + (glowScale - 1.0) * 0.3) // Subtle core pulse
        .accessibilityLabel(orbAccessibilityLabel)
        .accessibilityHint(orbAccessibilityHint)
    }

    // MARK: - Layer 4: Navigation UI

    private var navigationUI: some View {
        VStack {
            // Top: Destination name
            Text(viewModel.destination.name)
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 70)
                .accessibilityLabel("Navigating to \(viewModel.destination.name)")

            Text(viewModel.mode.label)
                .font(Theme.labelFont)
                .foregroundStyle(Theme.textTertiary)
                .padding(.top, 6)

            statusChip
                .padding(.top, 12)

            Spacer()

            // Bottom: Distance and info
            VStack(spacing: 8) {
                Text(viewModel.distanceString)
                    .font(Theme.distanceFont)
                    .foregroundStyle(viewModel.zone.colors.inner)
                    .contentTransition(.numericText())
                    .accessibilityLabel("\(viewModel.distanceString) remaining")

                // GPS accuracy warning
                if let accuracy = gpsAccuracy, accuracy > 30 {
                    HStack(spacing: 4) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 10, weight: .medium))
                        Text("±\(Int(accuracy))m")
                            .font(.system(size: 11, weight: .regular))
                    }
                    .foregroundStyle(Theme.cold.inner.opacity(0.7))
                    .accessibilityLabel("GPS accuracy is \(Int(accuracy)) meters")
                }

                // Wander budget (if set)
                if let wanderString = viewModel.wanderBudgetString {
                    Text(wanderString)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textTertiary)
                        .accessibilityLabel(wanderString)
                }

            }
            .padding(.bottom, 90)
        }
    }

    private var statusChip: some View {
        Text(statusDisplayText)
            .font(Theme.captionFont)
            .foregroundStyle(statusColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(statusColor.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(statusColor.opacity(0.16), lineWidth: 1)
            )
            .accessibilityLabel("Navigation status: \(statusDisplayText)")
    }

    // MARK: - Subviews

    private var noHeadingWarning: some View {
        HStack(spacing: 12) {
            // Animated compass icon
            Image(systemName: "location.north.line")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Theme.warm.inner)
                .rotationEffect(.degrees(headingAnimationAngle))
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: headingAnimationAngle)
                .onAppear { headingAnimationAngle = 30 }

            VStack(alignment: .leading, spacing: 2) {
                Text("Finding direction")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textSecondary)

                Text(headingHint)
                    .font(Theme.labelFont)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.surfaceSubtle)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
    }

    @State private var headingAnimationAngle: Double = -30

    private var headingHint: String {
        if viewModel.locationService.headingAvailable {
            return "Calibrating compass..."
        } else {
            return "Start walking to detect direction"
        }
    }

    private var gpsAccuracy: Double? {
        viewModel.currentLocation?.horizontalAccuracy
    }

    private var statusColor: Color {
        switch viewModel.currentInstruction.state {
        case .inLane, .arrived:
            return Theme.textSecondary
        case .drifting, .simpleGuidance:
            return Theme.warm.inner
        case .offCourse, .wrongWay:
            return Theme.hot.inner
        case .acquiringLocation, .lowConfidence:
            return Theme.textTertiary
        }
    }

    private var statusDisplayText: String {
        viewModel.fieldModeEnabled ? viewModel.fieldDiagnosticsText : viewModel.statusText
    }

    private var orbAccessibilityLabel: String {
        let zone = viewModel.zone
        let direction: String
        if viewModel.correctionDirection == .right {
            direction = "Turn right"
        } else if viewModel.correctionDirection == .left {
            direction = "Turn left"
        } else {
            direction = "On track"
        }
        return "\(zone.displayName). \(direction)"
    }

    private var orbAccessibilityHint: String {
        "Shows your direction relative to destination. Haptic feedback guides you."
    }

    private var debugOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DEBUG")
                .font(Theme.debugFont)
                .foregroundStyle(.orange)

            Group {
                if let loc = viewModel.currentLocation {
                    Text("Lat: \(loc.coordinate.latitude, specifier: "%.6f")")
                    Text("Lon: \(loc.coordinate.longitude, specifier: "%.6f")")
                    Text("Accuracy: \(loc.horizontalAccuracy, specifier: "%.1f")m")
                } else {
                    Text("Location: --")
                }

                Text("")

                if let heading = viewModel.currentHeading {
                    Text("Heading: \(heading, specifier: "%.1f")°")
                } else {
                    Text("Heading: --")
                }

                Text("Bearing: \(viewModel.bearing, specifier: "%.1f")°")
                Text("Deviation: \(viewModel.deviation, specifier: "%.1f")°")
                Text("Zone: \(viewModel.zone.rawValue)")
                Text("Shift: \(viewModel.directionShift, specifier: "%.2f")")
                Text("Orb Signal: \(viewModel.orbSignal.shift, specifier: "%.2f")")
                Text("Profile: \(viewModel.hapticProfile.displayName)")
                Text("Last Buzz: \(viewModel.lastHapticAge.map { String(format: "%.1fs", $0) } ?? "--")")
                Text("Cooldown: \(viewModel.currentHapticCooldown, specifier: "%.1f")s")
                Text("Field Mode: \(viewModel.fieldModeEnabled ? "on" : "off")")
                Text("State: \(String(describing: viewModel.currentInstruction.state))")
                Text("Confidence: \(viewModel.currentInstruction.confidence, specifier: "%.2f")")
                Text("Mode: \(viewModel.mode.rawValue)")
                Text("Route: \(viewModel.routeCorridor == nil ? "simple" : "corridor")")

                Text("")

                Text("Distance: \(viewModel.distance, specifier: "%.0f")m")
                Text("ETA: \(Int(viewModel.estimatedWalkingTime / 60)) min")

                if let budget = viewModel.wanderBudget {
                    Text("Wander: \(Int(budget / 60)) min")
                }
            }
            .font(Theme.debugFont)
            .foregroundStyle(Theme.textSecondary)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }

}

// MARK: - Preview

#Preview {
    NavigationView(
        viewModel: NavigationViewModel(
            destination: .testDestination
        )
    )
}
