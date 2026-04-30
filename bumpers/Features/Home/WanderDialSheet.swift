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
    let locationService: LocationService

    @Environment(\.dismiss) private var dismiss
    @AppStorage("hapticProfile") private var hapticProfileRawValue = FieldModeSettings.validationDefault.hapticProfile.rawValue
    @AppStorage("fieldModeEnabled") private var fieldModeEnabled = FieldModeSettings.validationDefault.isEnabled
    @AppStorage("hasSeenHapticCalibration") private var hasSeenHapticCalibration = false
    @State private var wanderMinutes: Double = 60 // Start at "no rush" position
    @State private var showNavigation = false
    @State private var walkEstimate: WalkEstimateState = .findingLocation
    @State private var selectedMode: NavigationMode = .roomToWander
    @State private var estimateTask: Task<Void, Never>?
    @State private var sheetStage: SheetStage = .undecided
    @State private var calibrationFlow = HapticCalibrationFlow()
    @State private var calibrationHapticService = HapticService()
    @State private var hasInitializedStage = false

    // For haptic tick feedback on slider
    @State private var lastTickValue: Int = 12 // 60/5 = 12 ticks

    // Hero transition state
    @State private var isTransitioning = false

    private let routeService = RouteService()

    // Slider range: 0 = leave now, 60+ = no rush
    private let maxMinutes: Double = 60
    private let tickInterval: Double = 5 // Fire haptic every 5 minutes

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background
                    .ignoresSafeArea()

                Group {
                    switch sheetStage {
                    case .undecided:
                        Color.clear
                    case .calibration:
                        calibrationStage
                    case .planning:
                        planningStage
                    }
                }
            }
            .navigationDestination(isPresented: $showNavigation) {
                NavigationView(viewModel: createViewModel())
            }
            .onAppear {
                initializeStageIfNeeded()
                locationService.requestPermission()
                locationService.startUpdating()
                updateWalkTimeEstimate()
            }
            .onChange(of: locationService.currentLocation) { _, _ in
                updateWalkTimeEstimate()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
    }

    private var calibrationStage: some View {
        HapticCalibrationView(
            flow: calibrationFlow,
            onStart: {
                runCalibrationTransition(calibrationFlow.start())
            },
            onRecord: { result in
                runCalibrationTransition(calibrationFlow.record(result))
            },
            onReplay: {
                runCalibrationTransition(calibrationFlow.replay())
            },
            onSkip: {
                finishCalibration(with: nil)
            }
        )
    }

    private var planningStage: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)

            destinationHeader
                .padding(.bottom, Theme.Spacing.xxxl)
                .opacity(isTransitioning ? 0 : 1)

            walkTimeEstimate
                .padding(.bottom, 40)
                .opacity(isTransitioning ? 0 : 1)

            NavigationModePicker(selectedMode: $selectedMode)
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.bottom, Theme.Spacing.xl)
                .opacity(isTransitioning ? 0 : 1)

            preflightHapticPanel
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.bottom, Theme.Spacing.xl)
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

            Text(walkEstimate.displayText)
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

    private var preflightHapticPanel: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Field haptics")
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textSecondary)

                    Text(hapticProfile.displayName)
                        .font(Theme.labelFont)
                        .foregroundStyle(Theme.textTertiary)
                }

                Spacer()

                Button("Too weak") {
                    hapticProfileRawValue = HapticProfile.fieldMax.rawValue
                    playPreflightCue(.maxBuzz)
                }
                .font(Theme.labelFont)
                .foregroundStyle(Theme.warm.inner)
            }

            HStack(spacing: Theme.Spacing.sm) {
                preflightButton("Test left", cue: .left)
                preflightButton("Test right", cue: .right)
                preflightButton("Max buzz", cue: .maxBuzz)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.surfaceSubtle)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.md)
                .stroke(Theme.borderSubtle, lineWidth: 1)
        )
    }

    private func preflightButton(_ title: String, cue: PreflightHapticCue) -> some View {
        Button(title) {
            playPreflightCue(cue)
        }
        .font(Theme.labelFont)
        .foregroundStyle(Theme.textSecondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
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
        .disabled(isTransitioning || !canStart)
        .opacity(canStart ? 1 : 0.45)
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
        guard let estimateSeconds = walkEstimate.seconds else { return nil }
        let totalSeconds = estimateSeconds + (wanderMinutes * 60)
        return Date().addingTimeInterval(totalSeconds)
    }

    private var hapticProfile: HapticProfile {
        HapticProfile(rawValue: hapticProfileRawValue) ?? .pocketNormal
    }

    private var canStart: Bool {
        isNoRush || walkEstimate.seconds != nil
    }

    private func initializeStageIfNeeded() {
        guard !hasInitializedStage else { return }
        hasInitializedStage = true
        sheetStage = (fieldModeEnabled || hasSeenHapticCalibration) ? .planning : .calibration
        calibrationHapticService.prepare()
    }

    private func runCalibrationTransition(_ transition: HapticCalibrationFlow.Transition?) {
        guard let transition else { return }

        switch transition {
        case .play(let pattern):
            calibrationHapticService.prepare()
            calibrationHapticService.play(pattern, profile: hapticProfile)
        case .complete(let profile):
            finishCalibration(with: profile)
        }
    }

    private func playPreflightCue(_ cue: PreflightHapticCue) {
        calibrationHapticService.prepare()
        calibrationHapticService.play(
            HapticCalibrationFlow.preflightPattern(for: cue),
            profile: hapticProfile
        )
    }

    private func finishCalibration(with profile: HapticProfile?) {
        if let profile {
            hapticProfileRawValue = profile.rawValue
        }
        hasSeenHapticCalibration = true
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
            sheetStage = .planning
        }
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

    // MARK: - Helpers

    private func updateWalkTimeEstimate() {
        guard let location = locationService.currentLocation else {
            estimateTask?.cancel()
            walkEstimate = locationService.isAuthorized ? .estimating : .findingLocation
            return
        }

        walkEstimate = .estimating
        estimateTask?.cancel()
        estimateTask = Task {
            do {
                let routes = try await routeService.walkingRoutes(from: location.coordinate, to: destination.coordinate)
                if let fastest = routes.min(by: { $0.expectedTravelTime < $1.expectedTravelTime }) {
                    await MainActor.run {
                        guard !Task.isCancelled else { return }
                        walkEstimate = .directRoute(fastest.expectedTravelTime)
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                let distance = NavigationCalculator.distance(
                    from: location.coordinate,
                    to: destination.coordinate
                )
                await MainActor.run {
                    guard !Task.isCancelled else { return }
                    walkEstimate = .roughStraightLine(NavigationCalculator.estimatedWalkingTime(meters: distance))
                }
            }
        }
    }

    private func createViewModel() -> NavigationViewModel {
        NavigationViewModel(
            destination: destination,
            arrivalTime: arrivalTime,
            mode: selectedMode,
            locationService: locationService,
            hapticProfile: hapticProfile,
            fieldModeEnabled: fieldModeEnabled
        )
    }
}

private enum SheetStage {
    case undecided
    case calibration
    case planning
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
    WanderDialSheet(destination: .testDestination, locationService: LocationService())
}
