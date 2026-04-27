import SwiftUI

struct HapticCalibrationView: View {
    let flow: HapticCalibrationFlow
    let onStart: () -> Void
    let onRecord: (CalibrationResult) -> Void
    let onReplay: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.top, 28)
                .padding(.horizontal, Theme.Spacing.xxl)

            Spacer(minLength: 44)

            hero
                .padding(.bottom, Theme.Spacing.xl)

            copyBlock
                .padding(.horizontal, Theme.Spacing.xxl)

            Spacer(minLength: 36)

            footerActions
                .padding(.horizontal, Theme.Spacing.xxl)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background.ignoresSafeArea())
    }

    private var topBar: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                Text(flow.progressLabel)
                    .font(Theme.labelFont)
                    .foregroundStyle(Theme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Spacer()

                Button("Skip") {
                    onSkip()
                }
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textTertiary)
            }

            HStack(spacing: 8) {
                ForEach(0..<2, id: \.self) { index in
                    Capsule()
                        .fill(progressColor(for: index))
                        .frame(maxWidth: .infinity)
                        .frame(height: 4)
                }
            }
        }
    }

    private var hero: some View {
        ZStack {
            Circle()
                .fill(Theme.warm.inner.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 40)

            RoundedRectangle(cornerRadius: 28)
                .fill(Theme.surfaceDefault)
                .frame(width: 112, height: 112)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Theme.borderDefault, lineWidth: 1)
                )

            Image(systemName: flow.showsResponseButtons ? "iphone.radiowaves.left.and.right" : "iphone")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.warm.inner)
        }
    }

    private var copyBlock: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text(flow.title)
                .font(Theme.screenTitleFont)
                .foregroundStyle(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Text(flow.subtitle)
                .font(Theme.captionFont)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footerActions: some View {
        VStack(spacing: Theme.Spacing.md) {
            if flow.showsResponseButtons {
                Button(flow.primaryButtonTitle) {
                    onRecord(.clear)
                }
                .bumperButton(.primary)

                Button("Too weak") {
                    onRecord(.tooWeak)
                }
                .bumperButton(.secondary)

                Button("Couldn't feel it") {
                    onRecord(.couldNotFeel)
                }
                .bumperButton(.secondary)

                if let replayButtonTitle = flow.replayButtonTitle {
                    Button(replayButtonTitle) {
                        onReplay()
                    }
                    .font(Theme.captionFont)
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.top, Theme.Spacing.sm)
                }
            } else {
                Button(flow.primaryButtonTitle) {
                    onStart()
                }
                .bumperButton(.primary)

                Text("Front pocket is the truth test. Handheld is fine for calibration but less honest.")
                    .font(Theme.labelFont)
                    .foregroundStyle(Theme.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.top, Theme.Spacing.sm)
            }
        }
    }

    private func progressColor(for index: Int) -> Color {
        switch flow.step {
        case .intro:
            return Theme.borderDefault
        case .right:
            return index == 0 ? Theme.warm.inner : Theme.borderDefault
        case .left:
            return Theme.warm.inner
        }
    }
}

#Preview {
    HapticCalibrationView(
        flow: HapticCalibrationFlow(),
        onStart: {},
        onRecord: { _ in },
        onReplay: {},
        onSkip: {}
    )
}
