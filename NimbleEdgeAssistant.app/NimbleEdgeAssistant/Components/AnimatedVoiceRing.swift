/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import SwiftUI

struct AnimatedVoiceRing: View {
    let isListening: Bool
    let isSpeaking: Bool
    let audioLevel: Float
    let onTap: () -> Void

    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var dotAnimations: [CGFloat] = Array(repeating: 1.0, count: 24)
    @State private var ringRadius: CGFloat = 120
    @State private var audioResponsiveScale: CGFloat = 1.0

    private let numberOfDots = 24
    private let baseRadius: CGFloat = 120
    private let dotSize: CGFloat = 8

    var body: some View {
        ZStack {
            // Background glow effect
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            isListening ? Color.cyan.opacity(0.3) :
                            isSpeaking ? Color.green.opacity(0.3) :
                            Color.gray.opacity(0.1),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: ringRadius * 1.5
                    )
                )
                .frame(width: ringRadius * 3, height: ringRadius * 3)
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseScale)

            // Animated dots ring
            ForEach(0..<numberOfDots, id: \.self) { index in
                DotView(
                    isActive: isListening || isSpeaking,
                    audioLevel: audioLevel,
                    index: index,
                    totalDots: numberOfDots,
                    baseRadius: ringRadius,
                    dotSize: dotSize,
                    animationOffset: rotationAngle,
                    scaleAnimation: dotAnimations[index]
                )
            }

            // Central interactive area
            Circle()
                .fill(Color.clear)
                .frame(width: ringRadius * 1.6, height: ringRadius * 1.6)
                .contentShape(Circle())
                .scaleEffect(audioResponsiveScale)
                .onTapGesture {
                    performTapFeedback()
                    onTap()
                }
                .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 50) {
                    performHoldFeedback()
                    onTap()
                }

            // Central status indicator
            VStack(spacing: 8) {
                // Status icon
                Image(systemName: getStatusIcon())
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(getStatusColor())
                    .scaleEffect(audioResponsiveScale)

                // Status text
                Text(getStatusText())
                    .font(.caption)
                    .foregroundColor(.gray)
                    .opacity(0.8)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isListening) { _, newValue in
            updateAnimationState()
        }
        .onChange(of: isSpeaking) { _, newValue in
            updateAnimationState()
        }
        .onChange(of: audioLevel) { _, newValue in
            updateAudioResponsiveEffects()
        }
    }

    private func getStatusIcon() -> String {
        if isListening {
            return "waveform"
        } else if isSpeaking {
            return "speaker.wave.2"
        } else {
            return "mic"
        }
    }

    private func getStatusColor() -> Color {
        if isListening {
            return .cyan
        } else if isSpeaking {
            return .green
        } else {
            return .white
        }
    }

    private func getStatusText() -> String {
        if isListening {
            return "Listening"
        } else if isSpeaking {
            return "Speaking"
        } else {
            return "Tap to speak"
        }
    }

    private func startAnimations() {
        // Continuous rotation
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Pulse effect
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }

        // Staggered dot animations
        for i in 0..<numberOfDots {
            let delay = Double(i) * 0.05
            withAnimation(.easeInOut(duration: 1.5).delay(delay).repeatForever(autoreverses: true)) {
                dotAnimations[i] = 1.3
            }
        }
    }

    private func updateAnimationState() {
        let targetRadius: CGFloat = isListening ? 140 : isSpeaking ? 130 : baseRadius

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            ringRadius = targetRadius
        }
    }

    private func updateAudioResponsiveEffects() {
        let scaleFactor = 1.0 + (CGFloat(audioLevel) * 0.2)
        withAnimation(.easeOut(duration: 0.1)) {
            audioResponsiveScale = scaleFactor
        }
    }

    private func performTapFeedback() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()

        // Visual feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            audioResponsiveScale = 0.95
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                audioResponsiveScale = 1.0
            }
        }
    }

    private func performHoldFeedback() {
        // Stronger haptic feedback for long press
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()

        // Selection feedback
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
}

struct DotView: View {
    let isActive: Bool
    let audioLevel: Float
    let index: Int
    let totalDots: Int
    let baseRadius: CGFloat
    let dotSize: CGFloat
    let animationOffset: Double
    let scaleAnimation: CGFloat

    @State private var currentScale: CGFloat = 1.0
    @State private var currentOpacity: Double = 0.7

    var body: some View {
        Circle()
            .fill(getDotColor())
            .frame(width: dotSize * currentScale, height: dotSize * currentScale)
            .opacity(currentOpacity)
            .position(getDotPosition())
            .onAppear {
                startDotAnimation()
            }
            .onChange(of: isActive) { _, newValue in
                updateDotState()
            }
            .onChange(of: audioLevel) { _, newValue in
                updateAudioResponse()
            }
    }

    private func getDotColor() -> Color {
        if isActive {
            // Create a gradient effect around the ring
            let normalizedIndex = Double(index) / Double(totalDots)
            let hue = (normalizedIndex + animationOffset / 360.0).truncatingRemainder(dividingBy: 1.0)

            if audioLevel > 0.3 {
                return Color(hue: hue, saturation: 0.8, brightness: 1.0)
            } else {
                return Color.cyan
            }
        } else {
            return Color.gray.opacity(0.6)
        }
    }

    private func getDotPosition() -> CGPoint {
        let angle = (Double(index) / Double(totalDots)) * 2 * .pi + (animationOffset * .pi / 180)
        let audioRadius = baseRadius + (CGFloat(audioLevel) * 20)

        let x = cos(angle) * audioRadius
        let y = sin(angle) * audioRadius

        return CGPoint(x: x + baseRadius + 40, y: y + baseRadius + 40)
    }

    private func startDotAnimation() {
        let delay = Double(index) * 0.02

        withAnimation(.easeInOut(duration: 1.0 + Double.random(in: -0.2...0.2))
                      .delay(delay)
                      .repeatForever(autoreverses: true)) {
            currentScale = scaleAnimation
        }

        withAnimation(.easeInOut(duration: 2.0 + Double.random(in: -0.5...0.5))
                      .delay(delay)
                      .repeatForever(autoreverses: true)) {
            currentOpacity = isActive ? 1.0 : 0.4
        }
    }

    private func updateDotState() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            currentOpacity = isActive ? 1.0 : 0.4
            currentScale = isActive ? scaleAnimation : 1.0
        }
    }

    private func updateAudioResponse() {
        if isActive && audioLevel > 0.1 {
            let responsiveness = 1.0 + (CGFloat(audioLevel) * 0.5)
            withAnimation(.easeOut(duration: 0.05)) {
                currentScale = scaleAnimation * responsiveness
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AnimatedVoiceRing(
            isListening: true,
            isSpeaking: false,
            audioLevel: 0.5,
            onTap: {}
        )
    }
}
