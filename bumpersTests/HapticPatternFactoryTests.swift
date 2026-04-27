import Testing
@testable import bumpers

struct HapticPatternFactoryTests {

    @Test func pocketDirectionPatternsUseDurationOrder() {
        let factory = HapticPatternFactory()

        let right = factory.makePattern(.correctRight(severity: .medium), profile: .pocketMax)
        let left = factory.makePattern(.correctLeft(severity: .medium), profile: .pocketMax)

        #expect(right.events.first?.type == .transient)
        #expect(right.events.last?.type == .continuous)
        #expect(left.events.first?.type == .continuous)
        #expect(left.events.last?.type == .transient)
    }

    @Test func strongCorrectionRepeatsDirectionalSignature() {
        let factory = HapticPatternFactory()
        let pattern = factory.makePattern(.correctRight(severity: .strong), profile: .pocketMax)

        #expect(pattern.events.count == 4)
        #expect(pattern.cooldown == 1.5)
    }

    @Test func pocketMaxUsesHigherEnergyThanPocketNormal() throws {
        let factory = HapticPatternFactory()
        let maxPattern = factory.makePattern(.correctLeft(severity: .medium), profile: .pocketMax)
        let normalPattern = factory.makePattern(.correctLeft(severity: .medium), profile: .pocketNormal)
        let maxIntensity = try #require(maxPattern.events.map(\.intensity).max())
        let normalIntensity = try #require(normalPattern.events.map(\.intensity).max())

        #expect(maxIntensity > normalIntensity)
    }

    @Test func arrivalPatternHasSingleCrescendo() {
        let factory = HapticPatternFactory()
        let pattern = factory.makePattern(.arrival, profile: .pocketNormal)

        #expect(pattern.events.count == 5)
        #expect(pattern.events.last?.type == .continuous)
    }
}
