import CoreLocation
import Foundation

struct CorridorNavigationInput {
    let currentLocation: CLLocation?
    let currentHeading: Double?
    let destination: CLLocationCoordinate2D
    let corridor: RouteCorridor?
    let mode: NavigationMode
    let arrivalTime: Date?
    let now: Date
    let fieldModeEnabled: Bool

    init(
        currentLocation: CLLocation?,
        currentHeading: Double?,
        destination: CLLocationCoordinate2D,
        corridor: RouteCorridor?,
        mode: NavigationMode,
        arrivalTime: Date?,
        now: Date,
        fieldModeEnabled: Bool = false
    ) {
        self.currentLocation = currentLocation
        self.currentHeading = currentHeading
        self.destination = destination
        self.corridor = corridor
        self.mode = mode
        self.arrivalTime = arrivalTime
        self.now = now
        self.fieldModeEnabled = fieldModeEnabled
    }
}

final class CorridorNavigationEngine {
    private struct HistoryPoint {
        let date: Date
        let distanceToDestination: CLLocationDistance
        let routeProgress: Double?
    }

    private var history: [HistoryPoint] = []
    private var arrivalCandidateStart: Date?

    func reset() {
        history.removeAll()
        arrivalCandidateStart = nil
    }

    func instruction(for input: CorridorNavigationInput) -> CorrectionInstruction {
        guard let location = input.currentLocation else {
            return instruction(
                state: .acquiringLocation,
                direction: nil,
                severity: .gentle,
                urgency: 0,
                haptic: .none,
                zone: .cool,
                confidence: 0,
                usesSimpleGuidance: input.corridor == nil
            )
        }

        guard location.horizontalAccuracy >= 0, location.horizontalAccuracy <= 50 else {
            return instruction(
                state: .lowConfidence(.poorLocationAccuracy),
                direction: nil,
                severity: .gentle,
                urgency: 0.1,
                haptic: .lowConfidence,
                zone: .cool,
                confidence: 0.2,
                usesSimpleGuidance: input.corridor == nil
            )
        }

        let distanceToDestination = NavigationCalculator.distance(
            from: location.coordinate,
            to: input.destination
        )

        if isArrived(
            distanceToDestination: distanceToDestination,
            accuracy: location.horizontalAccuracy,
            now: input.now
        ) {
            return instruction(
                state: .arrived,
                direction: nil,
                severity: .gentle,
                urgency: 0,
                haptic: .arrival,
                zone: .hot,
                confidence: confidence(for: location),
                usesSimpleGuidance: input.corridor == nil
            )
        }

        guard let heading = input.currentHeading ?? courseHeading(from: location) else {
            return instruction(
                state: .lowConfidence(.headingUnavailable),
                direction: nil,
                severity: .gentle,
                urgency: 0,
                haptic: .lowConfidence,
                zone: .cool,
                confidence: 0.4,
                usesSimpleGuidance: input.corridor == nil
            )
        }

        guard let corridor = input.corridor,
              let projection = corridor.nearestPoint(to: location.coordinate) else {
            recordHistory(now: input.now, distance: distanceToDestination, progress: nil)
            return simpleInstruction(
                location: location,
                heading: heading,
                destination: input.destination
            )
        }

        recordHistory(now: input.now, distance: distanceToDestination, progress: projection.routeProgress)

        let trend = progressTrend(now: input.now)
        let width = corridor.width(
            distanceToDestination: distanceToDestination,
            isMakingProgress: trend.distanceDelta <= 8 && trend.progressDelta >= -0.005,
            arrivalSlack: arrivalSlack(input.arrivalTime, routeRemaining: projection.remainingDistanceEstimate)
        )
        let effectiveWidth = input.fieldModeEnabled ? width * 0.72 : width

        if isWrongWay(trend: trend, projection: projection) {
            let direction = correctionDirection(
                from: location.coordinate,
                toward: input.destination,
                currentHeading: heading
            )
            return instruction(
                state: .wrongWay(direction: direction),
                direction: direction,
                severity: .urgent,
                urgency: 1,
                haptic: .wrongWay(direction: direction),
                zone: .freezing,
                confidence: confidence(for: location),
                usesSimpleGuidance: false
            )
        }

        if projection.distanceFromCorridorCenter <= effectiveWidth,
           trend.distanceDelta <= 15 || trend.progressDelta >= -0.01 {
            return instruction(
                state: .inLane,
                direction: nil,
                severity: .gentle,
                urgency: 0,
                haptic: .none,
                zone: .hot,
                confidence: confidence(for: location),
                usesSimpleGuidance: false
            )
        }

        let direction = correctionDirection(
            from: location.coordinate,
            toward: projection.nearestCoordinate,
            currentHeading: heading
        ) ?? correctionDirection(from: location.coordinate, toward: input.destination, currentHeading: heading)
        let ratio = projection.distanceFromCorridorCenter / max(effectiveWidth, 1)

        if ratio <= 1.75 {
            let severity: Severity = ratio < 1.3 ? .gentle : .medium
            return instruction(
                state: .drifting(direction: direction ?? .right, severity: severity),
                direction: direction,
                severity: severity,
                urgency: min(0.6, ratio / 1.75),
                haptic: haptic(for: direction, severity: severity),
                zone: severity == .gentle ? .warm : .cool,
                confidence: confidence(for: location),
                usesSimpleGuidance: false
            )
        }

        let severity: Severity = ratio > 2.5 ? .urgent : .strong
        return instruction(
            state: .offCourse(direction: direction ?? .right, severity: severity),
            direction: direction,
            severity: severity,
            urgency: min(1, ratio / 2.5),
            haptic: haptic(for: direction, severity: severity),
            zone: severity == .urgent ? .freezing : .cold,
            confidence: confidence(for: location),
            usesSimpleGuidance: false
        )
    }

    private func simpleInstruction(
        location: CLLocation,
        heading: Double,
        destination: CLLocationCoordinate2D
    ) -> CorrectionInstruction {
        let bearing = NavigationCalculator.bearing(from: location.coordinate, to: destination)
        let deviation = NavigationCalculator.deviation(currentHeading: heading, targetBearing: bearing)
        let zone = TemperatureZone.from(absoluteDeviation: abs(deviation))
        let direction = CorrectionDirection.from(deviation: deviation, deadZone: 15)
        let severity: Severity
        switch zone {
        case .hot, .warm:
            severity = .gentle
        case .cool:
            severity = .medium
        case .cold:
            severity = .strong
        case .freezing:
            severity = .urgent
        }

        return instruction(
            state: .simpleGuidance(direction: direction, severity: severity),
            direction: direction,
            severity: severity,
            urgency: min(1, abs(deviation) / 180),
            haptic: zone == .hot ? .none : haptic(for: direction, severity: severity),
            zone: zone,
            confidence: confidence(for: location),
            usesSimpleGuidance: true
        )
    }

    private func instruction(
        state: CorridorState,
        direction: CorrectionDirection?,
        severity: Severity,
        urgency: Double,
        haptic: HapticPatternKind,
        zone: TemperatureZone,
        confidence: Double,
        usesSimpleGuidance: Bool
    ) -> CorrectionInstruction {
        CorrectionInstruction(
            state: state,
            correctionDirection: direction,
            severity: severity,
            urgency: urgency,
            hapticPattern: haptic,
            visualTemperature: zone,
            confidence: confidence,
            usesSimpleGuidance: usesSimpleGuidance
        )
    }

    private func haptic(for direction: CorrectionDirection?, severity: Severity) -> HapticPatternKind {
        switch direction {
        case .left:
            return .correctLeft(severity: severity)
        case .right:
            return .correctRight(severity: severity)
        case nil:
            return .lowConfidence
        }
    }

    private func courseHeading(from location: CLLocation) -> Double? {
        guard location.course >= 0, location.speed >= 0.7 else {
            return nil
        }
        return location.course
    }

    private func correctionDirection(
        from current: CLLocationCoordinate2D,
        toward target: CLLocationCoordinate2D,
        currentHeading: Double
    ) -> CorrectionDirection? {
        let bearing = NavigationCalculator.bearing(from: current, to: target)
        let deviation = NavigationCalculator.deviation(currentHeading: currentHeading, targetBearing: bearing)
        return CorrectionDirection.from(deviation: deviation, deadZone: 10)
    }

    private func confidence(for location: CLLocation) -> Double {
        let accuracyScore = max(0, min(1, 1 - (location.horizontalAccuracy / 50)))
        let speedScore = location.speed >= 0.7 ? 1.0 : 0.6
        return max(0, min(1, (accuracyScore * 0.75) + (speedScore * 0.25)))
    }

    private func recordHistory(now: Date, distance: CLLocationDistance, progress: Double?) {
        history.append(HistoryPoint(date: now, distanceToDestination: distance, routeProgress: progress))
        history.removeAll { now.timeIntervalSince($0.date) > 30 }
    }

    private func progressTrend(now: Date) -> (distanceDelta: CLLocationDistance, progressDelta: Double) {
        guard let current = history.last else {
            return (0, 0)
        }
        let reference = history.first { now.timeIntervalSince($0.date) >= 10 } ?? history.first
        guard let reference else {
            return (0, 0)
        }

        return (
            current.distanceToDestination - reference.distanceToDestination,
            (current.routeProgress ?? 0) - (reference.routeProgress ?? 0)
        )
    }

    private func isWrongWay(
        trend: (distanceDelta: CLLocationDistance, progressDelta: Double),
        projection: CorridorProjection
    ) -> Bool {
        guard let oldest = history.first,
              let newest = history.last,
              newest.date.timeIntervalSince(oldest.date) >= 20 else {
            return false
        }

        return trend.distanceDelta > 15 && trend.progressDelta < -0.005 && projection.routeProgress < 0.98
    }

    private func arrivalSlack(_ arrivalTime: Date?, routeRemaining: CLLocationDistance) -> TimeInterval? {
        guard let arrivalTime else { return nil }
        let routeETA = routeRemaining / NavigationCalculator.walkingSpeedMetersPerSecond
        return arrivalTime.timeIntervalSinceNow - routeETA
    }

    private func isArrived(
        distanceToDestination: CLLocationDistance,
        accuracy: CLLocationAccuracy,
        now: Date
    ) -> Bool {
        let radius: CLLocationDistance = accuracy <= 20 ? 35 : max(50, accuracy * 1.5)

        guard distanceToDestination <= radius else {
            arrivalCandidateStart = nil
            return false
        }

        if arrivalCandidateStart == nil {
            arrivalCandidateStart = now
        }

        return now.timeIntervalSince(arrivalCandidateStart ?? now) >= 3
    }
}
