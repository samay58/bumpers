//
//  NavigationViewModel.swift
//  bumpers
//
//  The brain of navigation: calculates bearing, deviation, and orchestrates haptics.
//

import Foundation
import CoreLocation
import UIKit

@MainActor
@Observable
final class NavigationViewModel {

    // MARK: - Inputs

    let destination: Destination
    var arrivalTime: Date?
    let mode: NavigationMode

    // MARK: - Services

    let locationService: LocationService
    let hapticService: HapticService
    let liveActivityManager: LiveActivityManager
    let routeService: RouteService

    // MARK: - Navigation State

    var isNavigating = false
    var hasArrived = false
    var startTime: Date?
    var totalDistance: CLLocationDistance = 0
    var hapticPulseID = 0
    var routeCorridor: RouteCorridor?
    var currentInstruction = CorrectionInstruction(
        state: .acquiringLocation,
        correctionDirection: nil,
        severity: .gentle,
        urgency: 0,
        hapticPattern: .none,
        visualTemperature: .cool,
        confidence: 0,
        usesSimpleGuidance: false
    )
    var isLoadingRoute = false
    var simpleGuidanceMessage: String?
    var hapticProfile: HapticProfile
    var fieldModeEnabled: Bool
    var lastHapticFiredAt: Date?
    var currentHapticCooldown: TimeInterval = 0

    // MARK: - Computed Properties

    var currentLocation: CLLocation? {
        locationService.currentLocation
    }

    var currentHeading: Double? {
        locationService.bestHeading
    }

    var currentCoordinate: CLLocationCoordinate2D? {
        currentLocation?.coordinate
    }

    /// Distance to destination in meters.
    var distance: CLLocationDistance {
        guard let current = currentCoordinate else { return 0 }
        return NavigationCalculator.distance(from: current, to: destination.coordinate)
    }

    /// Bearing to destination (0-360 degrees, 0 = north).
    var bearing: Double {
        guard let current = currentCoordinate else { return 0 }
        return NavigationCalculator.bearing(from: current, to: destination.coordinate)
    }

    /// Deviation from target bearing (-180 to 180).
    /// Positive = turn right, negative = turn left.
    var deviation: Double {
        guard let heading = currentHeading else { return 0 }
        return NavigationCalculator.deviation(currentHeading: heading, targetBearing: bearing)
    }

    /// Absolute deviation (0-180).
    var absoluteDeviation: Double {
        abs(deviation)
    }

    /// Current temperature zone based on deviation.
    var zone: TemperatureZone {
        currentInstruction.visualTemperature
    }

    /// Directional shift for the orb (-1 to 1).
    /// -1 = turn hard left, 0 = on track, 1 = turn hard right.
    var directionShift: Double {
        guard let direction = currentInstruction.correctionDirection else { return 0 }
        let magnitude = max(0.2, min(1, currentInstruction.urgency))
        return direction == .right ? magnitude : -magnitude
    }

    var orbSignal: FieldOrbSignal {
        FieldOrbSignal.make(
            instruction: currentInstruction,
            deviation: deviation,
            fieldModeEnabled: fieldModeEnabled
        )
    }

    var lastHapticAge: TimeInterval? {
        guard let lastHapticFiredAt else { return nil }
        return Date().timeIntervalSince(lastHapticFiredAt)
    }

    var fieldDiagnosticsText: String {
        FieldModeDiagnostics.text(
            instruction: currentInstruction,
            hapticProfile: hapticProfile,
            lastHapticAge: lastHapticAge,
            cooldown: currentHapticCooldown,
            headingAvailable: hasHeading
        )
    }

    var correctionDirection: CorrectionDirection? {
        currentInstruction.correctionDirection
    }

    var statusText: String {
        switch currentInstruction.state {
        case .acquiringLocation:
            return "Finding your location"
        case .lowConfidence(.poorLocationAccuracy):
            return "GPS uncertain"
        case .lowConfidence(.headingUnavailable):
            return locationService.headingAvailable ? "Calibrating direction" : "Start walking to detect direction"
        case .lowConfidence(.locationUnavailable):
            return "Location unavailable"
        case .inLane:
            return "In lane"
        case .drifting(let direction, _):
            return "Ease \(direction.label)"
        case .offCourse(let direction, _):
            return "Correct \(direction.label)"
        case .wrongWay:
            return "You're moving away"
        case .arrived:
            return "Arrived"
        case .simpleGuidance:
            return "Simple direction guidance"
        }
    }

    /// Wander budget in seconds (time available beyond minimum walking time).
    var wanderBudget: TimeInterval? {
        guard let arrivalTime else { return nil }
        let walkingTime = estimatedWalkingTime
        return max(0, arrivalTime.timeIntervalSinceNow - walkingTime)
    }

    /// Estimated walking time to destination in seconds.
    var estimatedWalkingTime: TimeInterval {
        if let route = routeCorridor?.routes.first {
            return route.expectedTravelTime
        }
        return NavigationCalculator.estimatedWalkingTime(meters: distance)
    }

    /// Whether heading data is available.
    var hasHeading: Bool {
        currentHeading != nil
    }

    /// Whether location permission is granted.
    var isLocationAuthorized: Bool {
        locationService.isAuthorized
    }

    /// Formatted distance string.
    var distanceString: String {
        let measurement = Measurement(value: distance, unit: UnitLength.meters)
        return Self.distanceFormatter.string(from: measurement)
    }

    /// Formatted total distance string.
    var totalDistanceString: String {
        let measurement = Measurement(value: totalDistance, unit: UnitLength.meters)
        return Self.distanceFormatter.string(from: measurement)
    }

    /// Formatted wander budget string.
    var wanderBudgetString: String? {
        guard let budget = wanderBudget else { return nil }

        if budget <= 0 {
            return "Leave now!"
        }

        let minutes = Int(budget / 60)
        if minutes < 1 {
            return "< 1 min to wander"
        } else if minutes == 1 {
            return "~1 min to wander"
        } else {
            return "~\(minutes) min to wander"
        }
    }

    // MARK: - Private State

    private var hapticTimer: Timer?
    private var lastHapticTime: Date?
    private var previousLocation: CLLocation?
    private var routeTask: Task<Void, Never>?
    private var lastRouteOrigin: CLLocation?
    private var offCorridorSince: Date?
    private let corridorEngine = CorridorNavigationEngine()
    private let hapticPatternFactory = HapticPatternFactory()

    // MARK: - Journey Tracking

    private var journeyPoints: [JourneyPoint] = []
    private var lastSampledLocation: CLLocation?
    private var lastSampledZone: TemperatureZone?

    private enum JourneySampling {
        static let minDistanceMeters: CLLocationDistance = 10
        static let maxTimeSeconds: TimeInterval = 30
    }

    private static let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .naturalScale
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()

    // MARK: - Initialization

    init(
        destination: Destination,
        arrivalTime: Date? = nil,
        mode: NavigationMode = .roomToWander,
        locationService: LocationService? = nil,
        hapticService: HapticService? = nil,
        liveActivityManager: LiveActivityManager? = nil,
        routeService: RouteService? = nil,
        hapticProfile: HapticProfile = .pocketNormal,
        fieldModeEnabled: Bool = false
    ) {
        self.destination = destination
        self.arrivalTime = arrivalTime
        self.mode = mode
        self.locationService = locationService ?? LocationService()
        self.hapticService = hapticService ?? HapticService()
        self.liveActivityManager = liveActivityManager ?? LiveActivityManager()
        self.routeService = routeService ?? RouteService()
        self.hapticProfile = hapticProfile
        self.fieldModeEnabled = fieldModeEnabled
    }

    deinit {
        Task { @MainActor in
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Navigation Control

    func startNavigation() {
        guard !isNavigating else { return }

        isNavigating = true
        hasArrived = false
        startTime = Date()
        totalDistance = 0
        previousLocation = nil
        lastHapticTime = nil
        lastHapticFiredAt = nil
        currentHapticCooldown = 0
        hapticPulseID = 0
        routeCorridor = nil
        simpleGuidanceMessage = nil
        currentInstruction = CorrectionInstruction(
            state: .acquiringLocation,
            correctionDirection: nil,
            severity: .gentle,
            urgency: 0,
            hapticPattern: .none,
            visualTemperature: .cool,
            confidence: 0,
            usesSimpleGuidance: false
        )
        corridorEngine.reset()

        // Reset journey tracking
        journeyPoints = []
        lastSampledLocation = nil
        lastSampledZone = nil

        // Keep screen on during navigation
        UIApplication.shared.isIdleTimerDisabled = true

        // Start services
        hapticService.prepare()
        locationService.startUpdating()
        if let currentLocation {
            loadRoute(from: currentLocation)
        }

        // Start Live Activity (Lock Screen + Dynamic Island)
        liveActivityManager.startNavigation(
            destinationName: destination.name,
            zone: zone,
            distance: distance
        )

        // Start haptic timer
        startHapticTimer()
    }

    func stopNavigation() {
        isNavigating = false

        // Re-enable idle timer
        UIApplication.shared.isIdleTimerDisabled = false

        // Stop services
        locationService.stopUpdating()
        hapticService.stop()
        routeTask?.cancel()

        // End Live Activity
        liveActivityManager.endNavigation(showFinalState: false)

        // Stop haptic timer
        hapticTimer?.invalidate()
        hapticTimer = nil
    }

    // MARK: - Haptic Logic

    private func startHapticTimer() {
        // Check every 0.5 seconds for haptic timing
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.updateNavigation()
            }
        }
        // Add to .common mode so timer continues during UI interaction (scrolling, etc.)
        RunLoop.current.add(timer, forMode: .common)
        hapticTimer = timer
    }

    private func updateNavigation() {
        guard isNavigating else { return }

        // Track distance traveled
        if let current = currentLocation, let previous = previousLocation {
            totalDistance += current.distance(from: previous)
        }
        previousLocation = currentLocation

        if let currentLocation {
            ensureRouteLoaded(from: currentLocation)
        }

        currentInstruction = corridorEngine.instruction(
            for: CorridorNavigationInput(
                currentLocation: currentLocation,
                currentHeading: currentHeading,
                destination: destination.coordinate,
                corridor: routeCorridor,
                mode: mode,
                arrivalTime: arrivalTime,
                now: Date(),
                fieldModeEnabled: fieldModeEnabled
            )
        )
        simpleGuidanceMessage = currentInstruction.usesSimpleGuidance ? "Using simple direction guidance" : nil

        // Sample journey point for trail visualization
        sampleJourneyPointIfNeeded()

        // Update Live Activity with current state
        liveActivityManager.updateNavigation(zone: currentInstruction.visualTemperature, distance: distance)

        // Optimize battery based on navigation state
        updateLocationMode()

        // Check for arrival
        if currentInstruction.state == .arrived {
            handleArrival()
            return
        }

        updateRerouteState()

        // Fire haptics based on zone and timing
        fireHapticsIfNeeded()
    }

    private func updateLocationMode() {
        let currentZone = currentInstruction.visualTemperature
        let currentDistance = distance

        // Precise mode: close to destination or significantly off-track
        if currentDistance < 200 || currentZone == .cold || currentZone == .freezing {
            locationService.setMode(.precise)
        }
        // Efficient mode: on-track and far from destination
        else if (currentZone == .hot || currentZone == .warm) && currentDistance > 500 {
            locationService.setMode(.efficient)
        }
        // Balanced mode: everything else
        else {
            locationService.setMode(.balanced)
        }
    }

    private func fireHapticsIfNeeded() {
        let kind = currentInstruction.hapticPattern
        guard kind != .none else { return }
        let now = Date()

        // Check if enough time has passed since last haptic
        let pattern = hapticPatternFactory.makePattern(kind, profile: hapticProfile)
        let interval = pattern.cooldown
        currentHapticCooldown = interval
        if let lastTime = lastHapticTime {
            guard now.timeIntervalSince(lastTime) >= interval else { return }
        }

        hapticService.play(kind, profile: hapticProfile)

        lastHapticTime = now
        lastHapticFiredAt = now
        hapticPulseID += 1
    }

    private func handleArrival() {
        guard !hasArrived else { return }

        hasArrived = true
        hapticService.play(.arrival, profile: hapticProfile)

        // End Live Activity with celebration state (shows for 5 seconds)
        liveActivityManager.endNavigation(showFinalState: true)

        // Stop haptic timer but keep stats available for ArrivalView
        hapticTimer?.invalidate()
        hapticTimer = nil
    }

    // MARK: - Journey Sampling

    private func sampleJourneyPointIfNeeded() {
        guard let location = currentLocation else { return }

        let now = Date()
        let currentZone = zone

        // Determine if we should sample
        var shouldSample = false

        // Reason 1: First point
        if journeyPoints.isEmpty {
            shouldSample = true
        }

        // Reason 2: Moved 10+ meters
        if let lastLocation = lastSampledLocation {
            let moved = location.distance(from: lastLocation)
            if moved >= JourneySampling.minDistanceMeters {
                shouldSample = true
            }
        }

        // Reason 3: Zone changed (captures turning points)
        if let lastZone = lastSampledZone, lastZone != currentZone {
            shouldSample = true
        }

        // Reason 4: Time fallback (ensure points even when stationary)
        if let lastPoint = journeyPoints.last {
            let elapsed = now.timeIntervalSince(lastPoint.timestamp)
            if elapsed >= JourneySampling.maxTimeSeconds {
                shouldSample = true
            }
        }

        guard shouldSample else { return }

        // Create and store point
        let point = JourneyPoint(
            coordinate: location.coordinate,
            timestamp: now,
            zone: currentZone,
            distanceToDestination: distance
        )
        journeyPoints.append(point)

        // Update tracking state
        lastSampledLocation = location
        lastSampledZone = currentZone
    }

    // MARK: - Route Loading

    private func ensureRouteLoaded(from location: CLLocation) {
        if routeCorridor == nil, !isLoadingRoute {
            loadRoute(from: location)
            return
        }

        if let lastRouteOrigin, location.distance(from: lastRouteOrigin) > 80,
           case .offCourse = currentInstruction.state,
           !isLoadingRoute {
            loadRoute(from: location)
        }
    }

    private func loadRoute(from location: CLLocation) {
        routeTask?.cancel()
        isLoadingRoute = true
        lastRouteOrigin = location

        routeTask = Task { [weak self] in
            guard let self else { return }
            do {
                let routes = try await routeService.walkingRoutes(
                    from: location.coordinate,
                    to: destination.coordinate
                )
                await MainActor.run {
                    self.routeCorridor = RouteCorridor(
                        routes: routes,
                        mode: self.mode,
                        destination: self.destination.coordinate
                    )
                    self.simpleGuidanceMessage = nil
                    self.isLoadingRoute = false
                }
            } catch {
                await MainActor.run {
                    self.routeCorridor = nil
                    self.simpleGuidanceMessage = "Using simple direction guidance"
                    self.isLoadingRoute = false
                }
            }
        }
    }

    private func updateRerouteState() {
        let now = Date()
        switch currentInstruction.state {
        case .offCourse:
            if offCorridorSince == nil {
                offCorridorSince = now
            }
            if let since = offCorridorSince,
               now.timeIntervalSince(since) >= 45,
               let currentLocation,
               !isLoadingRoute {
                loadRoute(from: currentLocation)
                offCorridorSince = nil
            }
        case .drifting, .wrongWay:
            break
        case .acquiringLocation, .lowConfidence, .inLane, .arrived, .simpleGuidance:
            offCorridorSince = nil
        }
    }

    // MARK: - Journey Export

    /// Build the complete journey for display in ArrivalView.
    func buildJourney() -> Journey? {
        guard let start = startTime, !journeyPoints.isEmpty else { return nil }

        return Journey(
            destination: destination,
            startTime: start,
            endTime: Date(),
            points: journeyPoints
        )
    }
}
