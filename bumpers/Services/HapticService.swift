//
//  HapticService.swift
//  bumpers
//
//  Core Haptics wrapper for directional navigation feedback.
//  Direction is encoded with duration rhythm for pocket legibility.
//

import Foundation
import CoreHaptics
import UIKit

@MainActor
final class HapticService {

    // MARK: - Properties

    private var engine: CHHapticEngine?
    private var isEngineRunning = false
    private let patternFactory = HapticPatternFactory()

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

    func play(_ kind: HapticPatternKind, profile: HapticProfile = .pocketNormal) {
        let pattern = patternFactory.makePattern(kind, profile: profile)
        playPattern(pattern)
    }

    func playArrival() {
        play(.arrival)
    }

    private func playPattern(_ pattern: HapticPattern) {
        guard !pattern.events.isEmpty else { return }

        guard supportsHaptics, isEngineRunning else {
            playFallback(kind: pattern.kind)
            return
        }

        playPattern(events: pattern.events.map(makeEvent))
    }

    // MARK: - UIKit Fallback

    private func playFallback(kind: HapticPatternKind) {
        switch kind {
        case .none:
            return
        case .onTrackNod, .lowConfidence:
            impactLight.impactOccurred(intensity: 0.4)
        case .correctLeft(let severity), .correctRight(let severity):
            switch severity {
            case .gentle:
                impactLight.impactOccurred(intensity: 0.8)
            case .medium:
                impactMedium.impactOccurred()
            case .strong, .urgent:
                impactHeavy.impactOccurred()
            }
        case .wrongWay:
            notificationGenerator.notificationOccurred(.warning)
        case .arrival:
            notificationGenerator.notificationOccurred(.success)
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

    private func makeEvent(_ spec: HapticEventSpec) -> CHHapticEvent {
        switch spec.type {
        case .transient:
            return makeTransient(at: spec.relativeTime, intensity: spec.intensity, sharpness: spec.sharpness)
        case .continuous:
            return makeContinuous(
                at: spec.relativeTime,
                intensity: spec.intensity,
                sharpness: spec.sharpness,
                duration: spec.duration,
                attackTime: spec.attackTime,
                releaseTime: spec.releaseTime
            )
        }
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
