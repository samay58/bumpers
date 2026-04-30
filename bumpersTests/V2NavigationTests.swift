import CoreLocation
import MapKit
import Testing
@testable import bumpers

struct V2NavigationTests {

    @Test func correctionDirectionMatchesPositiveRightConvention() {
        #expect(CorrectionDirection.from(deviation: 90) == .right)
        #expect(CorrectionDirection.from(deviation: -90) == .left)
        #expect(CorrectionDirection.from(deviation: 20) == .right)
        #expect(CorrectionDirection.from(deviation: -20) == .left)
        #expect(CorrectionDirection.from(deviation: 0) == nil)
    }

    @Test func routeCorridorProjectsToNearestSegmentAndProgress() throws {
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let end = CLLocationCoordinate2D(latitude: 0, longitude: 0.01)
        let route = makeRoute(start, end)
        let corridor = RouteCorridor(routes: [route], mode: .roomToWander, destination: end)

        let northOfMidpoint = CLLocationCoordinate2D(latitude: 0.0001, longitude: 0.005)
        let projection = try #require(corridor.nearestPoint(to: northOfMidpoint))

        #expect(projection.distanceFromCorridorCenter > 9)
        #expect(projection.distanceFromCorridorCenter < 13)
        #expect(abs(projection.routeProgress - 0.5) < 0.05)
        #expect(projection.remainingDistanceEstimate > 500)
        #expect(projection.remainingDistanceEstimate < 600)
    }

    @Test func corridorEngineTreatsInsideCorridorAsSilentSuccess() {
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let end = CLLocationCoordinate2D(latitude: 0, longitude: 0.01)
        let corridor = RouteCorridor(routes: [makeRoute(start, end)], mode: .roomToWander, destination: end)
        let engine = CorridorNavigationEngine()

        let instruction = engine.instruction(
            for: CorridorNavigationInput(
                currentLocation: makeLocation(latitude: 0.0001, longitude: 0.005, accuracy: 8, speed: 1.2),
                currentHeading: 90,
                destination: end,
                corridor: corridor,
                mode: .roomToWander,
                arrivalTime: nil,
                now: Date(timeIntervalSince1970: 100)
            )
        )

        #expect(instruction.state == .inLane)
        #expect(instruction.hapticPattern == .none)
        #expect(instruction.visualTemperature == .hot)
    }

    @Test func corridorEngineDetectsDriftAndCorrectionDirection() {
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let end = CLLocationCoordinate2D(latitude: 0, longitude: 0.01)
        let corridor = RouteCorridor(routes: [makeRoute(start, end)], mode: .direct, destination: end)
        let engine = CorridorNavigationEngine()

        let instruction = engine.instruction(
            for: CorridorNavigationInput(
                currentLocation: makeLocation(latitude: 0.00045, longitude: 0.005, accuracy: 8, speed: 1.3),
                currentHeading: 90,
                destination: end,
                corridor: corridor,
                mode: .direct,
                arrivalTime: nil,
                now: Date(timeIntervalSince1970: 100)
            )
        )

        if case let .drifting(direction, severity) = instruction.state {
            #expect(direction == .right)
            #expect(severity == .gentle || severity == .medium)
        } else {
            Issue.record("Expected drifting state, got \(instruction.state)")
        }
        #expect(instruction.hapticPattern == .correctRight(severity: instruction.severity))
    }

    @Test func fieldModeTightensCorridorForEarlierDrift() {
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let end = CLLocationCoordinate2D(latitude: 0, longitude: 0.01)
        let corridor = RouteCorridor(routes: [makeRoute(start, end)], mode: .direct, destination: end)
        let normalEngine = CorridorNavigationEngine()
        let fieldEngine = CorridorNavigationEngine()
        let location = makeLocation(latitude: 0.00034, longitude: 0.005, accuracy: 8, speed: 1.2)

        let normal = normalEngine.instruction(
            for: CorridorNavigationInput(
                currentLocation: location,
                currentHeading: 90,
                destination: end,
                corridor: corridor,
                mode: .direct,
                arrivalTime: nil,
                now: Date(timeIntervalSince1970: 100)
            )
        )

        let field = fieldEngine.instruction(
            for: CorridorNavigationInput(
                currentLocation: location,
                currentHeading: 90,
                destination: end,
                corridor: corridor,
                mode: .direct,
                arrivalTime: nil,
                now: Date(timeIntervalSince1970: 100),
                fieldModeEnabled: true
            )
        )

        #expect(normal.state == .inLane)
        if case .drifting = field.state {
            #expect(field.hapticPattern != .none)
        } else {
            Issue.record("Expected field mode drift, got \(field.state)")
        }
    }

    @Test func lowLocationConfidenceSuppressesDirectionalHaptics() {
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let end = CLLocationCoordinate2D(latitude: 0, longitude: 0.01)
        let corridor = RouteCorridor(routes: [makeRoute(start, end)], mode: .direct, destination: end)
        let engine = CorridorNavigationEngine()

        let instruction = engine.instruction(
            for: CorridorNavigationInput(
                currentLocation: makeLocation(latitude: 0.001, longitude: 0.005, accuracy: 80, speed: 1.2),
                currentHeading: 90,
                destination: end,
                corridor: corridor,
                mode: .direct,
                arrivalTime: nil,
                now: Date(timeIntervalSince1970: 100)
            )
        )

        if case .lowConfidence(.poorLocationAccuracy) = instruction.state {
            #expect(instruction.hapticPattern == .lowConfidence)
        } else {
            Issue.record("Expected poor location confidence, got \(instruction.state)")
        }
    }

    @Test func arrivalDoesNotRequireHeadingAfterDebounce() {
        let destination = CLLocationCoordinate2D(latitude: 0, longitude: 0.01)
        let engine = CorridorNavigationEngine()
        let location = makeLocation(latitude: 0, longitude: 0.01, accuracy: 8, speed: 0)

        _ = engine.instruction(
            for: CorridorNavigationInput(
                currentLocation: location,
                currentHeading: nil,
                destination: destination,
                corridor: nil,
                mode: .roomToWander,
                arrivalTime: nil,
                now: Date(timeIntervalSince1970: 100)
            )
        )

        let instruction = engine.instruction(
            for: CorridorNavigationInput(
                currentLocation: location,
                currentHeading: nil,
                destination: destination,
                corridor: nil,
                mode: .roomToWander,
                arrivalTime: nil,
                now: Date(timeIntervalSince1970: 104)
            )
        )

        #expect(instruction.state == .arrived)
        #expect(instruction.hapticPattern == .arrival)
    }

    @Test func wrongWayRequiresSustainedBadProgress() {
        let start = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        let end = CLLocationCoordinate2D(latitude: 0, longitude: 0.01)
        let corridor = RouteCorridor(routes: [makeRoute(start, end)], mode: .roomToWander, destination: end)
        let engine = CorridorNavigationEngine()

        _ = engine.instruction(
            for: CorridorNavigationInput(
                currentLocation: makeLocation(latitude: 0, longitude: 0.006, accuracy: 8, speed: 1.2),
                currentHeading: 270,
                destination: end,
                corridor: corridor,
                mode: .roomToWander,
                arrivalTime: nil,
                now: Date(timeIntervalSince1970: 100)
            )
        )

        let instruction = engine.instruction(
            for: CorridorNavigationInput(
                currentLocation: makeLocation(latitude: 0, longitude: 0.0054, accuracy: 8, speed: 1.2),
                currentHeading: 270,
                destination: end,
                corridor: corridor,
                mode: .roomToWander,
                arrivalTime: nil,
                now: Date(timeIntervalSince1970: 122)
            )
        )

        if case .wrongWay = instruction.state {
            #expect(instruction.visualTemperature == .freezing)
        } else {
            Issue.record("Expected wrong way state, got \(instruction.state)")
        }
    }
}

private func makeRoute(_ coordinates: CLLocationCoordinate2D...) -> WalkingRoute {
    let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
    var distance: CLLocationDistance = 0
    for pair in zip(coordinates, coordinates.dropFirst()) {
        distance += NavigationCalculator.distance(from: pair.0, to: pair.1)
    }
    return WalkingRoute(polyline: polyline, expectedTravelTime: distance / 1.39, distance: distance, steps: [])
}

private func makeLocation(
    latitude: CLLocationDegrees,
    longitude: CLLocationDegrees,
    accuracy: CLLocationAccuracy,
    speed: CLLocationSpeed
) -> CLLocation {
    CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
        altitude: 0,
        horizontalAccuracy: accuracy,
        verticalAccuracy: 5,
        course: 90,
        speed: speed,
        timestamp: Date()
    )
}
