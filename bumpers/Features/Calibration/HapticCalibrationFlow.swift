import Foundation

struct HapticCalibrationFlow {
    enum Step: Int, CaseIterable, Equatable {
        case intro
        case right
        case left
    }

    enum Transition: Equatable {
        case play(HapticPatternKind)
        case complete(HapticProfile)
    }

    private(set) var step: Step = .intro
    private(set) var rightResult: CalibrationResult?
    private(set) var leftResult: CalibrationResult?

    private let calibrationService = HapticCalibrationService()

    var progressLabel: String {
        switch step {
        case .intro:
            return "Haptic Check"
        case .right:
            return "Step 1 of 2"
        case .left:
            return "Step 2 of 2"
        }
    }

    var title: String {
        switch step {
        case .intro:
            return "Put your phone where you'll actually carry it"
        case .right:
            return "Right cue"
        case .left:
            return "Left cue"
        }
    }

    var subtitle: String {
        switch step {
        case .intro:
            return "This only works if the pattern survives your real pocket, fabric, and stride."
        case .right:
            return "You should feel a short pulse, then a longer one. This means ease right."
        case .left:
            return "You should feel a long pulse, then a shorter one. This means ease left."
        }
    }

    var primaryButtonTitle: String {
        switch step {
        case .intro:
            return "Play first cue"
        case .right, .left:
            return "Felt it clearly"
        }
    }

    var replayButtonTitle: String? {
        switch step {
        case .intro:
            return nil
        case .right:
            return "Replay right cue"
        case .left:
            return "Replay left cue"
        }
    }

    var showsResponseButtons: Bool {
        step != .intro
    }

    mutating func start() -> Transition {
        step = .right
        return .play(.correctRight(severity: .medium))
    }

    mutating func replay() -> Transition? {
        switch step {
        case .intro:
            return nil
        case .right:
            return .play(.correctRight(severity: .medium))
        case .left:
            return .play(.correctLeft(severity: .medium))
        }
    }

    mutating func record(_ result: CalibrationResult) -> Transition? {
        switch step {
        case .intro:
            return nil
        case .right:
            rightResult = result
            step = .left
            return .play(.correctLeft(severity: .medium))
        case .left:
            leftResult = result
            let profile = calibrationService.recommendedProfile(
                rightResult: rightResult ?? .tooWeak,
                leftResult: result
            )
            return .complete(profile)
        }
    }
}
