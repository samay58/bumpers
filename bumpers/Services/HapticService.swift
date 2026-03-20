//
//  HapticService.swift
//  bumpers
//
//  Core Haptics wrapper for directional navigation feedback.
//  Direction is encoded in tap sequence order: rising = correct right, falling = correct left.
//

import Foundation
import CoreHaptics
import UIKit

final class HapticService {

    // MARK: - Properties

    private var engine: CHHapticEngine?
    private var isEngineRunning = false

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    // MARK: - Initialization

    init() {
        prepareGenerators()
    }

    // MARK: - Engine Lifecycle

    func prepare() {
        guard supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            engine?.isAutoShutdownEnabled = true

            engine?.stoppedHandler = { [weak self] _ in
                DispatchQueue.main.async {
                    self?.isEngineRunning = false
                }
            }

            engine?.resetHandler = { [weak self] in
                DispatchQueue.main.async {
                    self?.restartEngine()
                }
            }

            try engine?.start()
            isEngineRunning = true
        } catch {
            print("Haptic engine failed to start: \(error)")
        }
    }

    func stop() {
        engine?.stop()
        isEngineRunning = false
    }

    private func restartEngine() {
        do {
            try engine?.start()
            isEngineRunning = true
        } catch {
            print("Haptic engine restart failed: \(error)")
        }
    }

    private func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notificationGenerator.prepare()
    }

    // MARK: - Public API

    func playForZone(_ zone: TemperatureZone, direction: CorrectionDirection? = nil, intensityScale: Float = 1.0) {
        switch zone {
        case .hot:
            playNod(intensityScale: intensityScale)
        case .warm, .cool, .cold, .freezing:
            if let direction = direction {
                playDirectional(zone: zone, direction: direction, intensityScale: intensityScale)
            } else {
                playNod(intensityScale: intensityScale)
            }
        }
    }

    func playArrival() {
        guard supportsHaptics, isEngineRunning else {
            notificationGenerator.notificationOccurred(.success)
            return
        }

        let events = [
            makeTransient(at: 0.0, intensity: 0.30, sharpness: 0.50),
            makeTransient(at: 0.12, intensity: 0.50, sharpness: 0.55),
            makeTransient(at: 0.24, intensity: 0.70, sharpness: 0.60),
            makeTransient(at: 0.36, intensity: 0.90, sharpness: 0.70),
            makeContinuous(at: 0.45, intensity: 0.60, sharpness: 0.15, duration: 0.6,
                           attackTime: 0.05, releaseTime: 0.4),
        ]

        playPattern(events: events)
    }

    // MARK: - Hot Zone: The Nod

    private func playNod(intensityScale: Float) {
        guard supportsHaptics, isEngineRunning else {
            impactLight.impactOccurred(intensity: CGFloat(0.35 * intensityScale))
            return
        }

        let events = [
            makeTransient(at: 0.0, intensity: 0.35 * intensityScale, sharpness: 0.55),
            makeContinuous(at: 0.02, intensity: 0.15 * intensityScale, sharpness: 0.10, duration: 0.08),
        ]

        playPattern(events: events)
    }

    // MARK: - Directional Patterns

    private func playDirectional(zone: TemperatureZone, direction: CorrectionDirection, intensityScale: Float) {
        guard supportsHaptics, isEngineRunning else {
            playFallback(zone: zone)
            return
        }

        let events: [CHHapticEvent]

        switch zone {
        case .warm:
            events = makeDirectionalTaps(
                intensities: [0.25, 0.45],
                sharpness: 0.65,
                gap: 0.08,
                direction: direction,
                intensityScale: intensityScale
            )
        case .cool:
            events = makeDirectionalTaps(
                intensities: [0.25, 0.60],
                sharpness: 0.70,
                gap: 0.07,
                direction: direction,
                intensityScale: intensityScale
            )
        case .cold:
            events = makeDirectionalTaps(
                intensities: [0.25, 0.50, 0.75],
                sharpness: 0.75,
                gap: 0.06,
                direction: direction,
                intensityScale: intensityScale
            )
        case .freezing:
            let taps = makeDirectionalTaps(
                intensities: [0.20, 0.45, 0.65, 0.85],
                sharpness: 0.80,
                gap: 0.05,
                direction: direction,
                intensityScale: intensityScale
            )
            let rumble = makeContinuous(
                at: 0.0,
                intensity: 0.30 * intensityScale,
                sharpness: 0.05,
                duration: 0.25
            )
            events = [rumble] + taps
        default:
            return
        }

        playPattern(events: events)
    }

    // MARK: - Pattern Builder

    private func makeDirectionalTaps(
        intensities: [Float],
        sharpness: Float,
        gap: TimeInterval,
        direction: CorrectionDirection,
        intensityScale: Float
    ) -> [CHHapticEvent] {
        let ordered = direction == .right ? intensities : intensities.reversed()

        return ordered.enumerated().map { index, intensity in
            makeTransient(
                at: Double(index) * gap,
                intensity: intensity * intensityScale,
                sharpness: sharpness
            )
        }
    }

    // MARK: - UIKit Fallback

    private func playFallback(zone: TemperatureZone) {
        switch zone {
        case .hot:
            impactLight.impactOccurred(intensity: 0.4)
        case .warm:
            impactMedium.impactOccurred()
        case .cool:
            notificationGenerator.notificationOccurred(.warning)
        case .cold:
            impactHeavy.impactOccurred()
        case .freezing:
            notificationGenerator.notificationOccurred(.error)
        }
    }

    // MARK: - Event Helpers

    private func makeTransient(at time: TimeInterval, intensity: Float, sharpness: Float) -> CHHapticEvent {
        CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: time
        )
    }

    private func makeContinuous(
        at time: TimeInterval,
        intensity: Float,
        sharpness: Float,
        duration: TimeInterval,
        attackTime: Float? = nil,
        releaseTime: Float? = nil
    ) -> CHHapticEvent {
        var params = [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
        ]
        if let attack = attackTime {
            params.append(CHHapticEventParameter(parameterID: .attackTime, value: attack))
        }
        if let release = releaseTime {
            params.append(CHHapticEventParameter(parameterID: .releaseTime, value: release))
        }
        return CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: params,
            relativeTime: time,
            duration: duration
        )
    }

    private func playPattern(events: [CHHapticEvent]) {
        guard let engine = engine else { return }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play haptic pattern: \(error)")
        }
    }
}
