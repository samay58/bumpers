//
//  LocationService.swift
//  bumpers
//
//  CoreLocation wrapper for location and heading updates.
//

import Foundation
import CoreLocation
import Combine

@Observable
final class LocationService: NSObject {

    // MARK: - Published State

    var currentLocation: CLLocation?
    var currentHeading: CLHeading?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: Error?

    // MARK: - Computed Properties

    var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    var headingAvailable: Bool {
        CLLocationManager.headingAvailable()
    }

    /// Current heading in degrees (0-360), or nil if unavailable.
    /// Prefers true heading; falls back to magnetic heading.
    var headingDegrees: Double? {
        guard let heading = currentHeading else { return nil }

        // True heading requires location; magnetic is always available
        if heading.trueHeading >= 0 {
            return heading.trueHeading
        } else if heading.magneticHeading >= 0 {
            return heading.magneticHeading
        }
        return nil
    }

    /// If heading is unavailable, use GPS course (direction of movement).
    /// Only valid when moving at reasonable speed.
    var courseHeading: Double? {
        guard let location = currentLocation,
              location.course >= 0,
              location.speed > 0.5 else { // Moving at least 0.5 m/s
            return nil
        }
        return location.course
    }

    /// Best available heading: compass first, then GPS course.
    var bestHeading: Double? {
        return headingDegrees ?? courseHeading
    }

    // MARK: - Private

    private let locationManager = CLLocationManager()

    // MARK: - Initialization

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // Update every 5 meters
        locationManager.headingFilter = 5  // Update every 5 degrees

        // Get initial authorization status
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public Methods

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        guard isAuthorized else {
            requestPermission()
            return
        }

        locationManager.startUpdatingLocation()

        if headingAvailable {
            locationManager.startUpdatingHeading()
        }
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Take the most recent, most accurate location
        guard let location = locations.last else { return }

        // Filter out stale or inaccurate locations
        let age = -location.timestamp.timeIntervalSinceNow
        guard age < 10, // Less than 10 seconds old
              location.horizontalAccuracy >= 0,
              location.horizontalAccuracy < 100 else { // Reasonably accurate
            return
        }

        currentLocation = location
        locationError = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Filter out unreliable headings
        guard newHeading.headingAccuracy >= 0 else { return }

        currentHeading = newHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error

        // Don't clear location on transient errors
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                // User denied permission
                stopUpdating()
            case .locationUnknown:
                // Temporary failure, keep trying
                break
            default:
                break
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // Auto-start if we just got permission
        if isAuthorized {
            startUpdating()
        }
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        // Show calibration UI if heading accuracy is poor
        guard let heading = currentHeading else { return true }
        return heading.headingAccuracy < 0 || heading.headingAccuracy > 25
    }
}
