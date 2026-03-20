//
//  NavigationViewModel.swift
//  bumpers
//
//  The brain of navigation: calculates bearing, deviation, and orchestrates haptics.
//

import Foundation
import CoreLocation
import Combine
import UIKit

@Observable
final class NavigationViewModel {

    // MARK: - Inputs

    let destination: Destination
    var arrivalTime: Date?

    // MARK: - Services

    let locationService: LocationService
    let hapticService: HapticService
    let liveActivityManager: LiveActivityManager

    // MARK: - Navigation State

    var isNavigating = false
    var hasArrived = false
    var startTime: Date?
    var totalDistance: CLLocationDistance = 0
    var hapticPulseID = 0

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
        TemperatureZone.from(absoluteDeviation: absoluteDeviation)
    }

    /// Directional shift for the orb (-1 to 1).
    /// -1 = turn hard left, 0 = on track, 1 = turn hard right.
    var directionShift: Double {
        // Normalize deviation to -1...1 range
        // Max shift at 90° deviation
        let normalizedDeviation = deviation / 90.0
        return max(-1, min(1, normalizedDeviation))
    }

    var correctionDirection: CorrectionDirection? {
        guard zone != .hot else { return nil }
        return deviation > 0 ? .left : .right
    }

    /// Wander budget in seconds (time available beyond minimum walking time).
    var wanderBudget: TimeInterval? {
        guard let current = currentCoordinate else { return nil }
        return NavigationCalculator.wanderBudget(
            currentLocation: current,
            destination: destination.coordinate,
            arrivalTime: arrivalTime
        )
    }

    /// Estimated walking time to destination in seconds.
    var estimatedWalkingTime: TimeInterval {
        NavigationCalculator.estimatedWalkingTime(meters: distance)
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
    private var lastZone: TemperatureZone?
    private var previousLocation: CLLocation?

    // Zone debounce: require 1.5s stability before switching haptic zone
    private var pendingZone: TemperatureZone?
    private var pendingZoneStartTime: Date?
    private var stableZone: TemperatureZone = .hot
    private var isFirstPlayInNewZone = false

    private static let zoneDebounceInterval: TimeInterval = 1.5

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
        locationService: LocationService = LocationService(),
        hapticService: HapticService = HapticService(),
        liveActivityManager: LiveActivityManager = LiveActivityManager()
    ) {
        self.destination = destination
        self.arrivalTime = arrivalTime
        self.locationService = locationService
        self.hapticService = hapticService
        self.liveActivityManager = liveActivityManager
    }

    deinit {
        // Ensure screen idle timer is re-enabled even if navigation wasn't stopped cleanly
        UIApplication.shared.isIdleTimerDisabled = false
        hapticTimer?.invalidate()
    }

    // MARK: - Navigation Control

    func startNavigation() {
        guard !isNavigating else { return }

        isNavigating = true
        hasArrived = false
        startTime = Date()
        totalDistance = 0
        previousLocation = nil
        hapticPulseID = 0

        // Reset journey tracking
        journeyPoints = []
        lastSampledLocation = nil
        lastSampledZone = nil

        // Keep screen on during navigation
        UIApplication.shared.isIdleTimerDisabled = true

        // Start services
        hapticService.prepare()
        locationService.startUpdating()

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
            self?.updateNavigation()
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

        // Sample journey point for trail visualization
        sampleJourneyPointIfNeeded()

        // Update Live Activity with current state
        liveActivityManager.updateNavigation(zone: zone, distance: distance)

        // Optimize battery based on navigation state
        updateLocationMode()

        // Check for arrival
        if let current = currentCoordinate,
           NavigationCalculator.hasArrived(current: current, destination: destination.coordinate) {
            handleArrival()
            return
        }

        // Fire haptics based on zone and timing
        fireHapticsIfNeeded()
    }

    private func updateLocationMode() {
        let currentZone = zone
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
        guard hasHeading else { return }

        let currentZone = zone
        let now = Date()

        // Zone debounce: require 1.5s stability before adopting a new zone
        if currentZone != stableZone {
            if pendingZone == currentZone {
                if let start = pendingZoneStartTime,
                   now.timeIntervalSince(start) >= Self.zoneDebounceInterval {
                    stableZone = currentZone
                    pendingZone = nil
                    pendingZoneStartTime = nil
                    isFirstPlayInNewZone = true
                }
            } else {
                pendingZone = currentZone
                pendingZoneStartTime = now
            }
        } else {
            pendingZone = nil
            pendingZoneStartTime = nil
        }

        // Check if enough time has passed since last haptic
        let interval = stableZone.hapticInterval
        if let lastTime = lastHapticTime {
            guard now.timeIntervalSince(lastTime) >= interval else { return }
        }

        // If user just corrected course (zone improved), give them a reward pause
        if let last = lastZone, stableZone.hapticInterval > last.hapticInterval {
            lastHapticTime = now
            lastZone = stableZone
            return
        }

        // Fire haptic with direction and boundary blending
        let scale: Float = isFirstPlayInNewZone ? 0.75 : 1.0
        hapticService.playForZone(stableZone, direction: correctionDirection, intensityScale: scale)
        if isFirstPlayInNewZone { isFirstPlayInNewZone = false }

        lastHapticTime = now
        lastZone = stableZone
        hapticPulseID += 1
    }

    private func handleArrival() {
        guard !hasArrived else { return }

        hasArrived = true
        hapticService.playArrival()

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
