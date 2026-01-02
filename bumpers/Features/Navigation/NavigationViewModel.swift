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
        hapticService: HapticService = HapticService()
    ) {
        self.destination = destination
        self.arrivalTime = arrivalTime
        self.locationService = locationService
        self.hapticService = hapticService
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

        // Keep screen on during navigation
        UIApplication.shared.isIdleTimerDisabled = true

        // Start services
        hapticService.prepare()
        locationService.startUpdating()

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

        // Stop haptic timer
        hapticTimer?.invalidate()
        hapticTimer = nil
    }

    // MARK: - Haptic Logic

    private func startHapticTimer() {
        // Check every 0.5 seconds for haptic timing
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateNavigation()
        }
    }

    private func updateNavigation() {
        guard isNavigating else { return }

        // Track distance traveled
        if let current = currentLocation, let previous = previousLocation {
            totalDistance += current.distance(from: previous)
        }
        previousLocation = currentLocation

        // Check for arrival
        if let current = currentCoordinate,
           NavigationCalculator.hasArrived(current: current, destination: destination.coordinate) {
            handleArrival()
            return
        }

        // Fire haptics based on zone and timing
        fireHapticsIfNeeded()
    }

    private func fireHapticsIfNeeded() {
        guard hasHeading else { return }

        let currentZone = zone
        let now = Date()

        // Check if enough time has passed since last haptic
        let interval = currentZone.hapticInterval
        if let lastTime = lastHapticTime {
            guard now.timeIntervalSince(lastTime) >= interval else { return }
        }

        // If user just corrected course (zone improved), give them a break
        if let last = lastZone, currentZone.hapticInterval > last.hapticInterval {
            // Zone improved — pause haptics for 3 seconds as "reward"
            lastHapticTime = now
            lastZone = currentZone
            return
        }

        // Fire haptic
        hapticService.playForZone(currentZone)
        lastHapticTime = now
        lastZone = currentZone
        hapticPulseID += 1
    }

    private func handleArrival() {
        guard !hasArrived else { return }

        hasArrived = true
        hapticService.playArrival()

        // Keep navigation running briefly to show arrival state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.stopNavigation()
        }
    }
}
