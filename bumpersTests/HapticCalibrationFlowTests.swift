import Testing
@testable import bumpers

@MainActor
struct HapticCalibrationFlowTests {

    @Test func startAdvancesToRightCue() {
        var flow = HapticCalibrationFlow()

        let transition = flow.start()

        #expect(flow.step == .right)
        #expect(transition == .play(.correctRight(severity: .strong)))
        #expect(flow.showsResponseButtons)
    }

    @Test func firstResponseAdvancesToLeftCue() {
        var flow = HapticCalibrationFlow()
        _ = flow.start()

        let transition = flow.record(.clear)

        #expect(flow.step == .left)
        #expect(flow.rightResult == .clear)
        #expect(transition == .play(.correctLeft(severity: .strong)))
    }

    @Test func finalResponseCompletesWithRecommendedProfile() {
        var flow = HapticCalibrationFlow()
        _ = flow.start()
        _ = flow.record(.clear)

        let transition = flow.record(.tooWeak)

        #expect(flow.leftResult == .tooWeak)
        #expect(transition == .complete(.pocketMax))
    }

    @Test func replayMatchesCurrentCue() {
        var flow = HapticCalibrationFlow()
        #expect(flow.replay() == nil)

        _ = flow.start()
        #expect(flow.replay() == .play(.correctRight(severity: .strong)))

        _ = flow.record(.clear)
        #expect(flow.replay() == .play(.correctLeft(severity: .strong)))
    }

    @Test func preflightCueMappingUsesFieldStrengthPatterns() {
        #expect(HapticCalibrationFlow.preflightPattern(for: .right) == .correctRight(severity: .strong))
        #expect(HapticCalibrationFlow.preflightPattern(for: .left) == .correctLeft(severity: .strong))
        #expect(HapticCalibrationFlow.preflightPattern(for: .maxBuzz) == .wrongWay(direction: nil))
    }
}
