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
        #expect(pattern.cooldown == 1.5 * HapticProfile.pocketMax.cooldownScale)
    }

    @Test func pocketMaxUsesHigherEnergyThanPocketNormal() throws {
        let factory = HapticPatternFactory()
        let maxPattern = factory.makePattern(.correctLeft(severity: .medium), profile: .pocketMax)
        let normalPattern = factory.makePattern(.correctLeft(severity: .medium), profile: .pocketNormal)
        let maxIntensity = try #require(maxPattern.events.map(\.intensity).max())
        let normalIntensity = try #require(normalPattern.events.map(\.intensity).max())

        #expect(maxIntensity > normalIntensity)
    }

    @Test func fieldMaxUsesStrongerContinuousEnergyThanPocketMax() throws {
        let factory = HapticPatternFactory()
        let fieldMax = factory.makePattern(.correctLeft(severity: .medium), profile: .fieldMax)
        let pocketMax = factory.makePattern(.correctLeft(severity: .medium), profile: .pocketMax)
        let fieldContinuous = try #require(fieldMax.events.first)
        let pocketContinuous = try #require(pocketMax.events.first)

        #expect(fieldContinuous.type == .continuous)
        #expect(pocketContinuous.type == .continuous)
        #expect(fieldContinuous.intensity > pocketContinuous.intensity)
        #expect(fieldContinuous.duration > pocketContinuous.duration)
        #expect(fieldMax.cooldown < pocketMax.cooldown)
    }

    @Test func fieldMaxWrongWayHasLongPocketLegibleRumble() throws {
        let factory = HapticPatternFactory()
        let pattern = factory.makePattern(.wrongWay(direction: .right), profile: .fieldMax)
        let firstEvent = try #require(pattern.events.first)

        #expect(firstEvent.type == .continuous)
        #expect(firstEvent.intensity == 1)
        #expect(firstEvent.duration >= 0.55)
        #expect(pattern.cooldown <= 0.9)
    }

    @Test func fieldMaxLeftSignatureKeepsGapBetweenLongAndShortEvents() throws {
        let factory = HapticPatternFactory()
        let pattern = factory.makePattern(.correctLeft(severity: .strong), profile: .fieldMax)
        let longEvent = try #require(pattern.events.first)
        let shortEvent = try #require(pattern.events.dropFirst().first)

        #expect(longEvent.type == .continuous)
        #expect(shortEvent.type == .transient)
        #expect(shortEvent.relativeTime >= longEvent.relativeTime + longEvent.duration + 0.09)
    }

    @Test func fieldMaxStrongLeftRepeatDoesNotSwallowShortTap() throws {
        let factory = HapticPatternFactory()
        let pattern = factory.makePattern(.correctLeft(severity: .strong), profile: .fieldMax)
        let shortEvent = try #require(pattern.events.dropFirst().first)
        let repeatedLongEvent = try #require(pattern.events.dropFirst(2).first)

        #expect(shortEvent.type == .transient)
        #expect(repeatedLongEvent.type == .continuous)
        #expect(repeatedLongEvent.relativeTime >= shortEvent.relativeTime + 0.14)
    }

    @Test func arrivalPatternHasSingleCrescendo() {
        let factory = HapticPatternFactory()
        let pattern = factory.makePattern(.arrival, profile: .pocketNormal)

        #expect(pattern.events.count == 5)
        #expect(pattern.events.last?.type == .continuous)
    }
}
