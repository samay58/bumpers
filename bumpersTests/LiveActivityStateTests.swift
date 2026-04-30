import Testing
@testable import bumpers

struct LiveActivityStateTests {

    @Test func contentStateDefaultsDescribeQuietInLaneNavigation() {
        let state = NavigationActivityAttributes.ContentState(
            zone: "hot",
            distanceMeters: 245
        )

        #expect(state.status == "In lane")
        #expect(state.action == "Quiet means on track")
        #expect(state.guidanceDisplayName == "Route corridor")
        #expect(state.directionSymbolName == "circle.fill")
    }

    @Test func contentStateBucketsDistanceForMeaningfulUpdates() {
        let near = NavigationActivityAttributes.ContentState(
            zone: "hot",
            distanceMeters: 128,
            confidence: 0.96
        )
        let far = NavigationActivityAttributes.ContentState(
            zone: "cold",
            distanceMeters: 1_240,
            confidence: 0.42
        )

        #expect(near.distanceBucket == 12)
        #expect(near.confidenceBucket == 9)
        #expect(far.distanceBucket == 24)
        #expect(far.confidenceBucket == 4)
    }

    @Test func contentStateDoesNotShowFakeZeroDistanceBeforeLocation() {
        let state = NavigationActivityAttributes.ContentState(
            zone: "cool",
            distanceMeters: 0,
            distanceAvailable: false
        )

        #expect(state.distanceString == "--")
        #expect(state.compactDistanceString == "--")
        #expect(state.distanceBucket == -1)
    }

    @Test func contentStateMapsLowConfidenceAndDirectionSymbols() {
        let uncertain = NavigationActivityAttributes.ContentState(
            zone: "cool",
            distanceMeters: 680,
            guidanceMode: "lowConfidence",
            confidence: -1
        )
        let leftCorrection = NavigationActivityAttributes.ContentState(
            zone: "cold",
            distanceMeters: 680,
            direction: "left",
            confidence: 2
        )

        #expect(uncertain.confidence == 0)
        #expect(uncertain.guidanceDisplayName == "Signal low")
        #expect(uncertain.directionSymbolName == "location.slash")
        #expect(leftCorrection.confidence == 1)
        #expect(leftCorrection.directionSymbolName == "arrow.turn.up.left")
    }
}
