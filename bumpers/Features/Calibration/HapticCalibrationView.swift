import SwiftUI

struct HapticCalibrationView: View {
    let hapticProfile: HapticProfile
    let hapticService: HapticService
    let onComplete: (HapticProfile) -> Void
    let onSkip: () -> Void

    @State private var step: Step = .intro
    @State private var rightResult: CalibrationResult?
    @State private var leftResult: CalibrationResult?

    private let calibrationService = HapticCalibrationService()

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 42, weight: .light))
                    .foregroundStyle(Theme.warm.inner)

                VStack(spacing: Theme.Spacing.sm) {
                    Text(title)
                        .font(Theme.sheetTitleFont)
                        .foregroundStyle(Theme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.xl)
                }

                Spacer()

                VStack(spacing: Theme.Spacing.md) {
                    if step == .intro {
                        Button("Start") {
                            hapticService.prepare()
                            step = .right
                            playRight()
                        }
                        .bumperButton(.primary)
                    } else {
                        Button("Clear") {
                            record(.clear)
                        }
                        .bumperButton(.primary)

                        Button("Too weak") {
                            record(.tooWeak)
                        }
                        .bumperButton(.secondary)

                        Button("Couldn't feel it") {
                            record(.couldNotFeel)
                        }
                        .bumperButton(.secondary)

                        Button(step == .right ? "Replay right" : "Replay left") {
                            step == .right ? playRight() : playLeft()
                        }
                        .font(Theme.captionFont)
                        .foregroundStyle(Theme.textTertiary)
                        .padding(.top, Theme.Spacing.sm)
                    }

                    Button("Skip") {
                        onSkip()
                    }
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.top, Theme.Spacing.sm)
                }
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.bottom, 44)
            }
        }
    }

    private var title: String {
        switch step {
        case .intro:
            return "Put your phone where you'll walk with it"
        case .right:
            return "This means correct right"
        case .left:
            return "This means correct left"
        }
    }

    private var subtitle: String {
        switch step {
        case .intro:
            return "Bumper works only if the pattern survives your real pocket, fabric, and stride."
        case .right:
            return "Short pulse, then longer pulse."
        case .left:
            return "Long pulse, then short pulse."
        }
    }

    private func record(_ result: CalibrationResult) {
        switch step {
        case .intro:
            return
        case .right:
            rightResult = result
            step = .left
            playLeft()
        case .left:
            leftResult = result
            let profile = calibrationService.recommendedProfile(
                rightResult: rightResult ?? .tooWeak,
                leftResult: leftResult ?? result
            )
            onComplete(profile)
        }
    }

    private func playRight() {
        hapticService.play(.correctRight(severity: .medium), profile: hapticProfile)
    }

    private func playLeft() {
        hapticService.play(.correctLeft(severity: .medium), profile: hapticProfile)
    }

    private enum Step {
        case intro
        case right
        case left
    }
}

#Preview {
    HapticCalibrationView(
        hapticProfile: .pocketNormal,
        hapticService: HapticService(),
        onComplete: { _ in },
        onSkip: {}
    )
}
