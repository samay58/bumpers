import SwiftUI

struct NavigationModePicker: View {
    @Binding var selectedMode: NavigationMode

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(NavigationMode.allCases) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    VStack(spacing: 3) {
                        Text(mode.label)
                            .font(Theme.labelFont)
                            .foregroundStyle(selectedMode == mode ? Theme.background : Theme.textSecondary)
                            .lineLimit(1)

                        Text(mode.subtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(selectedMode == mode ? Theme.background.opacity(0.65) : Theme.textTertiary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(selectedMode == mode ? Theme.warm.inner : Theme.surfaceDefault)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.sm))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(mode.label), \(mode.subtitle)")
            }
        }
    }
}
