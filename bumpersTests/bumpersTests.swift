//
//  bumpersTests.swift
//  bumpersTests
//
//  Created by Samay Dhawan on 1/1/26.
//

import CoreLocation
import Testing
@testable import bumpers

struct NavigationCalculatorTests {

    @Test func bearingMatchesCardinalDirections() {
        let origin = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let north = CLLocationCoordinate2D(latitude: 1, longitude: 0)
        let east = CLLocationCoordinate2D(latitude: 0, longitude: 1)

        let northBearing = NavigationCalculator.bearing(from: origin, to: north)
        let eastBearing = NavigationCalculator.bearing(from: origin, to: east)

        #expect(abs(northBearing - 0) < 0.01)
        #expect(abs(eastBearing - 90) < 0.01)
    }

    @Test func normalizeAngleWrapsToSignedRange() {
        #expect(NavigationCalculator.normalizeAngle(190) == -170)
        #expect(NavigationCalculator.normalizeAngle(-190) == 170)
        #expect(NavigationCalculator.normalizeAngle(180) == 180)
        #expect(NavigationCalculator.normalizeAngle(-180) == -180)
    }

    @Test func deviationUsesSignedShortestTurn() {
        #expect(NavigationCalculator.deviation(currentHeading: 0, targetBearing: 10) == 10)
        #expect(NavigationCalculator.deviation(currentHeading: 10, targetBearing: 350) == -20)
        #expect(NavigationCalculator.deviation(currentHeading: 350, targetBearing: 10) == 20)
    }

    @Test func estimatedWalkingTimeMatchesSpeedAssumption() {
        let time = NavigationCalculator.estimatedWalkingTime(meters: 139)
        #expect(abs(time - 100) < 0.5)
    }

    @Test func hasArrivedIsTrueAtSameCoordinate() {
        let current = CLLocationCoordinate2D(latitude: 19.4184425, longitude: -99.1762134)
        #expect(NavigationCalculator.hasArrived(current: current, destination: current))
    }

    @Test func wanderBudgetUsesAvailableTimeMinusWalkingTime() {
        let current = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let destination = current
        let arrival = Date().addingTimeInterval(120)

        let budget = NavigationCalculator.wanderBudget(
            currentLocation: current,
            destination: destination,
            arrivalTime: arrival
        )

        #expect(budget != nil)
        if let budget {
            #expect(budget <= 120)
            #expect(budget >= 118)
        }
    }
}

struct TemperatureZoneTests {

    @Test func zoneBoundariesMatchSpec() {
        #expect(TemperatureZone.from(absoluteDeviation: 0) == .hot)
        #expect(TemperatureZone.from(absoluteDeviation: 20) == .hot)
        #expect(TemperatureZone.from(absoluteDeviation: 20.01) == .warm)
        #expect(TemperatureZone.from(absoluteDeviation: 45) == .warm)
        #expect(TemperatureZone.from(absoluteDeviation: 90) == .cool)
        #expect(TemperatureZone.from(absoluteDeviation: 135) == .cold)
        #expect(TemperatureZone.from(absoluteDeviation: 179) == .freezing)
    }
}
