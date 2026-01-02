//
//  NavigationView.swift
//  bumpers
//
//  Core navigation screen with orb and haptic feedback.
//

import SwiftUI
import CoreLocation

struct NavigationView: View {

    // MARK: - Properties

    @State var viewModel: NavigationViewModel
    @State private var showDebug = false
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        ZStack {
            // Background
            Theme.background
                .ignoresSafeArea()

            // Main content
            VStack(spacing: 40) {
                Spacer()

                // Destination name
                Text(viewModel.destination.name)
                    .font(Theme.headlineFont)
                    .foregroundStyle(Theme.textPrimary)

                Spacer()

                // Orb
                OrbView(
                    zone: viewModel.zone,
                    directionShift: viewModel.directionShift,
                    bumpTrigger: viewModel.hapticPulseID
                )

                Spacer()

                // Distance
                Text(viewModel.distanceString)
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)

                // Wander budget (if set)
                if let wanderString = viewModel.wanderBudgetString {
                    Text(wanderString)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                // No heading warning
                if !viewModel.hasHeading && viewModel.isNavigating {
                    noHeadingWarning
                }

                Spacer()
            }
            .padding()

            // Debug overlay
            if showDebug {
                debugOverlay
            }

            // Arrival overlay
            if viewModel.hasArrived {
                arrivalOverlay
            }
        }
        .onTapGesture(count: 3) {
            showDebug.toggle()
        }
        .onAppear {
            viewModel.startNavigation()
        }
        .onDisappear {
            viewModel.stopNavigation()
        }
        .statusBarHidden(true)
    }

    // MARK: - Subviews

    private var noHeadingWarning: some View {
        VStack(spacing: 4) {
            Text("Keep walking for direction")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textTertiary)

            Text("Compass calibrating...")
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textTertiary.opacity(0.6))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
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

    private var arrivalOverlay: some View {
        ZStack {
            Theme.background.opacity(0.95)

            VStack(spacing: 24) {
                Text("🎉")
                    .font(.system(size: 80))

                Text("You made it!")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.textPrimary)

                VStack(spacing: 8) {
                    if let start = viewModel.startTime {
                        let duration = Date().timeIntervalSince(start)
                        Text("\(Int(duration / 60)) min walk")
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.textSecondary)
                    }

                    Text(viewModel.totalDistanceString)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textTertiary)
                }

                Button("Done") {
                    dismiss()
                }
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .padding(.top, 16)
            }
        }
        .ignoresSafeArea()
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
