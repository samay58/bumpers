import Foundation

struct HapticPatternFactory {

    func makePattern(_ kind: HapticPatternKind, profile: HapticProfile) -> HapticPattern {
        switch kind {
        case .none:
            return HapticPattern(kind: kind, events: [], cooldown: 0)
        case .onTrackNod:
            guard profile.allowsOnTrackNod else {
                return HapticPattern(kind: .none, events: [], cooldown: 10)
            }
            return HapticPattern(
                kind: kind,
                events: [
                    transient(at: 0, intensity: 0.35 * profile.energyScale, sharpness: 0.55),
                    continuous(at: 0.02, duration: 0.08, intensity: 0.15 * profile.energyScale, sharpness: 0.10),
                ],
                cooldown: 12
            )
        case .correctRight(let severity):
            return directional(direction: .right, severity: severity, profile: profile, kind: kind)
        case .correctLeft(let severity):
            return directional(direction: .left, severity: severity, profile: profile, kind: kind)
        case .wrongWay(let direction):
            var events = [
                continuous(at: 0, duration: profile.wrongWayRumbleDuration, intensity: 1.0 * profile.energyScale, sharpness: 0.10),
            ]
            if let direction {
                events += signature(direction: direction, severity: .strong, profile: profile, start: 0.60)
            }
            return HapticPattern(kind: kind, events: events, cooldown: 1.2 * profile.cooldownScale)
        case .arrival:
            return HapticPattern(
                kind: kind,
                events: [
                    transient(at: 0.00, intensity: 0.30 * profile.energyScale, sharpness: 0.50),
                    transient(at: 0.12, intensity: 0.50 * profile.energyScale, sharpness: 0.55),
                    transient(at: 0.24, intensity: 0.70 * profile.energyScale, sharpness: 0.60),
                    transient(at: 0.36, intensity: 0.90 * profile.energyScale, sharpness: 0.70),
                    continuous(
                        at: 0.45,
                        duration: 0.60,
                        intensity: 0.60 * profile.energyScale,
                        sharpness: 0.15,
                        attackTime: 0.05,
                        releaseTime: 0.40
                    ),
                ],
                cooldown: 10
            )
        case .lowConfidence:
            return HapticPattern(
                kind: kind,
                events: [
                    transient(at: 0, intensity: 0.25 * profile.energyScale, sharpness: 0.25),
                ],
                cooldown: 8
            )
        }
    }

    private func directional(
        direction: CorrectionDirection,
        severity: Severity,
        profile: HapticProfile,
        kind: HapticPatternKind
    ) -> HapticPattern {
        var events = signature(direction: direction, severity: severity, profile: profile, start: 0)
        let cooldown: TimeInterval

        switch severity {
        case .gentle:
            cooldown = 3.0
        case .medium:
            cooldown = 2.2
        case .strong:
            let repeatStart: TimeInterval = direction == .left ? 0.62 : 0.38
            events += signature(direction: direction, severity: severity, profile: profile, start: repeatStart)
            cooldown = 1.5
        case .urgent:
            events = [
                continuous(at: 0, duration: 0.45, intensity: 1.0 * profile.energyScale, sharpness: 0.10),
            ] + signature(direction: direction, severity: .strong, profile: profile, start: 0.60)
            cooldown = 1.2
        }

        return HapticPattern(kind: kind, events: events, cooldown: cooldown * profile.cooldownScale)
    }

    private func signature(
        direction: CorrectionDirection,
        severity: Severity,
        profile: HapticProfile,
        start: TimeInterval
    ) -> [HapticEventSpec] {
        let params = parameters(for: severity)
        let scale = profile.energyScale
        let leftLongBoost = direction == .left ? 1.12 : 1.0
        let longDuration = params.longDuration * profile.continuousDurationScale * leftLongBoost
        let followUpGap: TimeInterval = direction == .left ? 0.10 : 0.05

        switch direction {
        case .right:
            return [
                transient(at: start, intensity: params.shortIntensity * scale, sharpness: params.shortSharpness),
                continuous(at: start + 0.12, duration: longDuration, intensity: params.longIntensity * scale, sharpness: params.longSharpness),
            ]
        case .left:
            return [
                continuous(at: start, duration: longDuration, intensity: params.longIntensity * scale, sharpness: params.longSharpness),
                transient(at: start + longDuration + followUpGap, intensity: params.shortIntensity * scale, sharpness: params.shortSharpness),
            ]
        }
    }

    private func parameters(for severity: Severity) -> (
        longIntensity: Float,
        longDuration: TimeInterval,
        longSharpness: Float,
        shortIntensity: Float,
        shortSharpness: Float
    ) {
        switch severity {
        case .gentle:
            return (0.65, 0.16, 0.20, 0.85, 0.85)
        case .medium:
            return (0.75, 0.20, 0.20, 0.90, 0.88)
        case .strong:
            return (0.85, 0.24, 0.20, 1.00, 0.90)
        case .urgent:
            return (0.90, 0.28, 0.18, 1.00, 0.92)
        }
    }

    private func transient(at time: TimeInterval, intensity: Float, sharpness: Float) -> HapticEventSpec {
        HapticEventSpec(
            type: .transient,
            relativeTime: time,
            duration: 0,
            intensity: min(1, max(0, intensity)),
            sharpness: min(1, max(0, sharpness)),
            attackTime: nil,
            releaseTime: nil
        )
    }

    private func continuous(
        at time: TimeInterval,
        duration: TimeInterval,
        intensity: Float,
        sharpness: Float,
        attackTime: Float? = nil,
        releaseTime: Float? = nil
    ) -> HapticEventSpec {
        HapticEventSpec(
            type: .continuous,
            relativeTime: time,
            duration: duration,
            intensity: min(1, max(0, intensity)),
            sharpness: min(1, max(0, sharpness)),
            attackTime: attackTime,
            releaseTime: releaseTime
        )
    }
}
