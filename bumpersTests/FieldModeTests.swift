import Testing
@testable import bumpers

struct FieldModeTests {

    @Test func inLaneFieldModeKeepsOrbAliveWithoutDirectionalCorrection() {
        let instruction = CorrectionInstruction(
            state: .inLane,
            correctionDirection: nil,
            severity: .gentle,
            urgency: 0,
            hapticPattern: .none,
            visualTemperature: .hot,
            confidence: 0.82,
            usesSimpleGuidance: false
        )

        let signal = FieldOrbSignal.make(
            instruction: instruction,
            deviation: 45,
            fieldModeEnabled: true
        )

        #expect(signal.shift > 0)
        #expect(signal.shift <= 0.18)
        #expect(signal.isAlive)
        #expect(!signal.isDirectionalCorrection)
    }

    @Test func correctionDirectionWinsOverAliveBias() {
        let instruction = CorrectionInstruction(
            state: .offCourse(direction: .left, severity: .strong),
            correctionDirection: .left,
            severity: .strong,
            urgency: 0.9,
            hapticPattern: .correctLeft(severity: .strong),
            visualTemperature: .cold,
            confidence: 0.8,
            usesSimpleGuidance: false
        )

        let signal = FieldOrbSignal.make(
            instruction: instruction,
            deviation: 20,
            fieldModeEnabled: true
        )

        #expect(signal.shift < -0.85)
        #expect(signal.isAlive)
        #expect(signal.isDirectionalCorrection)
    }

    @Test func productModeKeepsInLaneOrbStill() {
        let instruction = CorrectionInstruction(
            state: .inLane,
            correctionDirection: nil,
            severity: .gentle,
            urgency: 0,
            hapticPattern: .none,
            visualTemperature: .hot,
            confidence: 0.8,
            usesSimpleGuidance: false
        )

        let signal = FieldOrbSignal.make(
            instruction: instruction,
            deviation: 90,
            fieldModeEnabled: false
        )

        #expect(signal.shift == 0)
        #expect(!signal.isAlive)
        #expect(!signal.isDirectionalCorrection)
    }

    @Test func diagnosticsMentionStateProfileAndHapticAge() {
        let instruction = CorrectionInstruction(
            state: .drifting(direction: .right, severity: .medium),
            correctionDirection: .right,
            severity: .medium,
            urgency: 0.5,
            hapticPattern: .correctRight(severity: .medium),
            visualTemperature: .cool,
            confidence: 0.74,
            usesSimpleGuidance: false
        )

        let diagnostics = FieldModeDiagnostics.text(
            instruction: instruction,
            hapticProfile: .fieldMax,
            lastHapticAge: 3.2,
            cooldown: 1.4,
            headingAvailable: true
        )

        #expect(diagnostics.contains("Drifting right"))
        #expect(diagnostics.contains("Field Max"))
        #expect(diagnostics.contains("buzz 3s ago"))
        #expect(diagnostics.contains("cooldown 1.4s"))
    }
}
