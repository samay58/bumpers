//
//  Interactions.swift
//  bumpers
//
//  Micro-interaction modifiers for consistent feedback.
//  Every tap should feel warm and intentional.
//

import SwiftUI

// MARK: - Pressable Modifier

/// Adds scale + haptic feedback on press.
/// Use on any tappable element for consistent feel.
struct PressableModifier: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
            .sensoryFeedback(.selection, trigger: isPressed)
    }
}

extension View {
    /// Makes the view respond to press with scale and haptic feedback.
    func pressable() -> some View {
        modifier(PressableModifier())
    }
}

// MARK: - Row Pressable Modifier

/// Variant for list rows — adds warm background highlight on press.
struct RowPressableModifier: ViewModifier {
    @State private var isPressed = false
    let cornerRadius: CGFloat

    init(cornerRadius: CGFloat = 10) {
        self.cornerRadius = cornerRadius
    }

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Theme.warm.inner.opacity(isPressed ? 0.08 : 0))
                    .animation(.easeOut(duration: 0.15), value: isPressed)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
            .sensoryFeedback(.selection, trigger: isPressed)
    }
}

extension View {
    /// Makes the row respond to press with warm highlight and haptic.
    func rowPressable(cornerRadius: CGFloat = 10) -> some View {
        modifier(RowPressableModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Staggered Entrance Modifier

/// Animates view entrance with staggered delay based on index.
struct StaggeredEntranceModifier: ViewModifier {
    let index: Int
    let appeared: Bool
    let baseDelay: Double
    let staggerDelay: Double

    init(index: Int, appeared: Bool, baseDelay: Double = 0, staggerDelay: Double = 0.05) {
        self.index = index
        self.appeared = appeared
        self.baseDelay = baseDelay
        self.staggerDelay = staggerDelay
    }

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
            .animation(
                .easeOut(duration: 0.3).delay(baseDelay + Double(index) * staggerDelay),
                value: appeared
            )
    }
}

extension View {
    /// Animates entrance with staggered delay based on index.
    func staggeredEntrance(index: Int, appeared: Bool, baseDelay: Double = 0) -> some View {
        modifier(StaggeredEntranceModifier(index: index, appeared: appeared, baseDelay: baseDelay))
    }
}

// MARK: - Preview

#Preview("Pressable Button") {
    ZStack {
        Theme.background.ignoresSafeArea()

        VStack(spacing: 24) {
            Button("Pressable Button") {}
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(Theme.warm.inner)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .pressable()

            VStack(spacing: 0) {
                ForEach(0..<3) { i in
                    HStack {
                        Text("Row \(i + 1)")
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .rowPressable()
                }
            }
            .padding(.horizontal, 24)
        }
    }
}
