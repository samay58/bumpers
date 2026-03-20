//
//  WanderDialSheet.swift
//  bumpers
//
//  Time constraint selector — "How much time do you have?"
//

import SwiftUI
import CoreLocation

struct WanderDialSheet: View {
    let destination: Destination

    @Environment(\.dismiss) private var dismiss
    @State private var wanderMinutes: Double = 60 // Start at "no rush" position
    @State private var showNavigation = false
    @State private var estimatedWalkTime: TimeInterval = 0

    // For haptic tick feedback on slider
    @State private var lastTickValue: Int = 12 // 60/5 = 12 ticks

    // Hero transition state
    @State private var isTransitioning = false

    private let locationService = LocationService()

    // Slider range: 0 = leave now, 60+ = no rush
    private let maxMinutes: Double = 60
    private let tickInterval: Double = 5 // Fire haptic every 5 minutes

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 40)

                    destinationHeader
                        .padding(.bottom, Theme.Spacing.xxxl)
                        .opacity(isTransitioning ? 0 : 1)

                    walkTimeEstimate
                        .padding(.bottom, 40)
                        .opacity(isTransitioning ? 0 : 1)

                    wanderDial
                        .padding(.horizontal, Theme.Spacing.xxl)
                        .padding(.bottom, Theme.Spacing.xxxl)
                        .opacity(isTransitioning ? 0 : 1)

                    wanderBudgetDisplay
                        .padding(.bottom, Theme.Spacing.xxxl)
                        .opacity(isTransitioning ? 0 : 1)

                    startButton
                        .padding(.horizontal, Theme.Spacing.xxl)

                    Spacer()
                }
                .animation(.easeOut(duration: 0.25), value: isTransitioning)
            }
            .navigationDestination(isPresented: $showNavigation) {
                NavigationView(viewModel: createViewModel())
            }
            .onAppear {
                locationService.requestPermission()
                updateWalkTimeEstimate()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
    }

    // MARK: - Destination Header

    private var destinationHeader: some View {
        VStack(spacing: 8) {
            Text(destination.name)
                .font(Theme.sheetTitleFont)
                .foregroundStyle(Theme.textPrimary)

            Text(destination.address)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textTertiary)
                .lineLimit(1)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, Theme.Spacing.xxl)
    }

    // MARK: - Walk Time Estimate

    private var walkTimeEstimate: some View {
        VStack(spacing: 4) {
            Text("Estimated walk")
                .font(Theme.labelFont)
                .foregroundStyle(Theme.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)

            Text(formatWalkTime(estimatedWalkTime))
                .font(Theme.headlineFont)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Wander Dial

    private var wanderDial: some View {
        VStack(spacing: 20) {
            // Slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Track background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Theme.surfaceElevated)
                        .frame(height: 8)

                    // Filled portion with gradient
                    RoundedRectangle(cornerRadius: 4)
                        .fill(sliderGradient)
                        .frame(width: sliderFillWidth(in: geometry.size.width), height: 8)

                    // Thumb
                    Circle()
                        .fill(thumbColor)
                        .frame(width: 28, height: 28)
                        .shadow(color: thumbColor.opacity(0.4), radius: 8, x: 0, y: 4)
                        .offset(x: thumbOffset(in: geometry.size.width))
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    updateSlider(with: value, in: geometry.size.width)
                                }
                        )
                        .sensoryFeedback(.selection, trigger: lastTickValue)
                }
                .frame(height: 28)
            }
            .frame(height: 28)

            // Labels
            HStack {
                Text("Leave now")
                    .font(Theme.labelFont)
                    .foregroundStyle(Theme.textTertiary)

                Spacer()

                Text("No rush")
                    .font(Theme.labelFont)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    // MARK: - Wander Budget Display

    private var wanderBudgetDisplay: some View {
        VStack(spacing: 6) {
            if isNoRush {
                Text("Take your time")
                    .font(Theme.screenTitleFont)
                    .foregroundStyle(Theme.textPrimary)

                Text("No time constraint")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textTertiary)
            } else if isTightSchedule {
                Text("~\(Int(wanderMinutes)) min")
                    .font(Theme.screenTitleFont)
                    .foregroundStyle(Theme.warm.inner)

                Text("You'll need to walk directly")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.warm.inner.opacity(0.8))
            } else {
                Text("~\(Int(wanderMinutes)) min")
                    .font(Theme.screenTitleFont)
                    .foregroundStyle(Theme.textPrimary)

                Text("to wander")
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textTertiary)
            }
        }
        .animation(.easeOut(duration: 0.2), value: wanderMinutes)
    }

    /// True when wander time is less than 5 minutes (very tight schedule)
    private var isTightSchedule: Bool {
        !isNoRush && wanderMinutes < 5
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            startNavigation()
        } label: {
            ZStack {
                // Button background (fades during transition)
                RoundedRectangle(cornerRadius: Theme.CornerRadius.lg)
                    .fill(Theme.warm.inner)
                    .opacity(isTransitioning ? 0 : 1)

                // Growing orb (appears during transition)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Theme.warm.inner, Theme.warm.outer.opacity(0.6), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: isTransitioning ? 200 : 30
                        )
                    )
                    .scaleEffect(isTransitioning ? 3.5 : 0.3)
                    .opacity(isTransitioning ? 1 : 0)

                // Text (fades during transition)
                Text("Start")
                    .font(Theme.buttonFont)
                    .foregroundStyle(Theme.background)
                    .opacity(isTransitioning ? 0 : 1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
        }
        .pressable()
        .disabled(isTransitioning)
    }

    private func startNavigation() {
        destination.markAsUsed()

        // Start hero animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isTransitioning = true
        }

        // Navigate after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showNavigation = true
        }
    }

    // MARK: - Computed Properties

    private var isNoRush: Bool {
        wanderMinutes >= maxMinutes
    }

    private var sliderGradient: LinearGradient {
        LinearGradient(
            colors: [Theme.warm.inner, Theme.hot.inner],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var thumbColor: Color {
        if isNoRush {
            return Theme.warm.inner
        }
        let progress = wanderMinutes / maxMinutes
        return Color.interpolate(from: Theme.hot.inner, to: Theme.warm.inner, progress: progress)
    }

    private var arrivalTime: Date? {
        guard !isNoRush else { return nil }
        let totalSeconds = estimatedWalkTime + (wanderMinutes * 60)
        return Date().addingTimeInterval(totalSeconds)
    }

    // MARK: - Slider Helpers

    private func sliderFillWidth(in totalWidth: CGFloat) -> CGFloat {
        let progress = wanderMinutes / maxMinutes
        return max(0, min(totalWidth, totalWidth * progress))
    }

    private func thumbOffset(in totalWidth: CGFloat) -> CGFloat {
        let progress = wanderMinutes / maxMinutes
        let trackableWidth = totalWidth - 28 // Account for thumb width
        return max(0, min(trackableWidth, trackableWidth * progress))
    }

    private func updateSlider(with value: DragGesture.Value, in totalWidth: CGFloat) {
        let trackableWidth = totalWidth - 28
        let progress = max(0, min(1, value.location.x / trackableWidth))
        wanderMinutes = progress * maxMinutes

        // Check if we crossed a tick boundary (every 5 minutes)
        let currentTick = Int(wanderMinutes / tickInterval)
        if currentTick != lastTickValue {
            lastTickValue = currentTick
        }
    }

    /// Current tick value for haptic feedback (changes every 5 minutes)
    private var currentTickValue: Int {
        Int(wanderMinutes / tickInterval)
    }

    // MARK: - Helpers

    private func updateWalkTimeEstimate() {
        guard let location = locationService.currentLocation else {
            // Fallback estimate if no location yet
            estimatedWalkTime = 15 * 60 // 15 minutes default
            return
        }

        let distance = NavigationCalculator.distance(
            from: location.coordinate,
            to: destination.coordinate
        )
        estimatedWalkTime = NavigationCalculator.estimatedWalkingTime(meters: distance)
    }

    private func formatWalkTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds / 60)
        if minutes < 1 {
            return "< 1 min"
        } else if minutes == 1 {
            return "~1 min"
        } else {
            return "~\(minutes) min"
        }
    }

    private func createViewModel() -> NavigationViewModel {
        NavigationViewModel(
            destination: destination,
            arrivalTime: arrivalTime
        )
    }
}

// MARK: - Color Interpolation

extension Color {
    static func interpolate(from: Color, to: Color, progress: Double) -> Color {
        let p = max(0, min(1, progress))
        return Color(
            red: lerp(from: from.components.red, to: to.components.red, t: p),
            green: lerp(from: from.components.green, to: to.components.green, t: p),
            blue: lerp(from: from.components.blue, to: to.components.blue, t: p)
        )
    }

    private static func lerp(from: Double, to: Double, t: Double) -> Double {
        from + (to - from) * t
    }

    private var components: (red: Double, green: Double, blue: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}

// MARK: - Preview

#Preview {
    WanderDialSheet(destination: .testDestination)
}
