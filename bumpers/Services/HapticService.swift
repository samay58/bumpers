//
//  HapticService.swift
//  bumpers
//
//  Core Haptics wrapper for navigation feedback.
//

import Foundation
import CoreHaptics
import UIKit

final class HapticService {

    // MARK: - Properties

    private var engine: CHHapticEngine?
    private var isEngineRunning = false

    /// Fallback generators for when Core Haptics isn't available
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()

    /// Check if device supports Core Haptics
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

            // Handle engine stopping
            engine?.stoppedHandler = { [weak self] reason in
                self?.isEngineRunning = false
            }

            // Handle engine reset
            engine?.resetHandler = { [weak self] in
                self?.restartEngine()
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

    // MARK: - Haptic Patterns

    /// Gentle single tap — "You're on track"
    func playOnTrackPulse() {
        guard supportsHaptics, isEngineRunning else {
            impactLight.impactOccurred()
            return
        }

        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0
            )
        ]

        playPattern(events: events)
    }

    /// Double tap — "You're veering slightly"
    func playVeerWarning() {
        guard supportsHaptics, isEngineRunning else {
            impactMedium.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.impactMedium.impactOccurred()
            }
            return
        }

        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0.1
            )
        ]

        playPattern(events: events)
    }

    /// Triple tap — "You're off course"
    func playOffCourseAlert() {
        guard supportsHaptics, isEngineRunning else {
            notificationGenerator.notificationOccurred(.warning)
            return
        }

        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0.08
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0.16
            )
        ]

        playPattern(events: events)
    }

    /// Continuous gentle buzz — "You're going the wrong way"
    func playWrongWayBuzz() {
        guard supportsHaptics, isEngineRunning else {
            notificationGenerator.notificationOccurred(.error)
            return
        }

        let events = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0,
                duration: 0.5
            )
        ]

        playPattern(events: events)
    }

    /// Celebratory pattern — "You made it!"
    func playArrival() {
        guard supportsHaptics, isEngineRunning else {
            notificationGenerator.notificationOccurred(.success)
            return
        }

        // Rising intensity taps followed by a satisfying buzz
        let events = [
            // Rising taps
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.08
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
                ],
                relativeTime: 0.16
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0.24
            ),
            // Final satisfying buzz
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0.4,
                duration: 0.3
            )
        ]

        playPattern(events: events)
    }

    /// Play haptic for a specific temperature zone.
    func playForZone(_ zone: TemperatureZone) {
        switch zone {
        case .hot:
            playOnTrackPulse()
        case .warm:
            playVeerWarning()
        case .cool:
            playOffCourseAlert()
        case .cold:
            playOffCourseAlert()
        case .freezing:
            playWrongWayBuzz()
        }
    }

    // MARK: - Private Helpers

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
