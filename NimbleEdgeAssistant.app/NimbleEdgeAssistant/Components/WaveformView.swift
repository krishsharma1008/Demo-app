/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import SwiftUI

struct WaveformView: View {
    @Binding var isAnimating: Bool
    @Binding var isListening: Bool
    @Binding var isSpeaking: Bool
    @Binding var audioLevel: CGFloat

    @State private var animationValues: [CGFloat] = Array(repeating: 0.1, count: 12)
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.3

    private let numberOfBars = 12

    var body: some View {
        ZStack {
            // Background glow effect
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            isListening ? Color.cyan.opacity(glowOpacity) :
                            isSpeaking ? Color.green.opacity(glowOpacity) :
                            Color.gray.opacity(0.1),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(pulseScale)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseScale)

            // Animated waveform bars in circle
            ForEach(0..<numberOfBars, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(getBarColor(for: index))
                    .frame(width: 4, height: barHeight(for: index))
                    .offset(y: -30)
                    .rotationEffect(.degrees(Double(index) * 30 + rotationAngle))
                    .scaleEffect(animationValues[index])
                    .animation(.easeInOut(duration: 0.3 + Double(index) * 0.05), value: animationValues[index])
            }

            // Central status indicator
            VStack(spacing: 4) {
                Image(systemName: getStatusIcon())
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(getStatusColor())
                    .scaleEffect(pulseScale)

                Text(getStatusText())
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .opacity(0.8)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isListening) { _ in
            updateAnimation()
        }
        .onChange(of: isSpeaking) { _ in
            updateAnimation()
        }
        .onChange(of: audioLevel) { _ in
            updateAudioLevelAnimation()
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 20
        let variation = animationValues[index] * 40
        return baseHeight + variation
    }

    private func waveScale(for index: Int) -> CGFloat {
        let scales: [CGFloat] = [0.3, 0.7, 1.0, 0.8, 1.2, 1.0, 0.9, 1.1, 0.6, 0.8, 0.5, 0.3]
        return scales[index]
    }

    private func generateWaveform() {
        for i in 0..<numberOfBars {
            animationValues[i] = CGFloat.random(in: 0.2...1.0)
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

    private func getBarColor(for index: Int) -> Color {
        if isListening || isSpeaking {
            let normalizedIndex = Double(index) / Double(numberOfBars)
            let hue = (normalizedIndex + rotationAngle / 360.0).truncatingRemainder(dividingBy: 1.0)

            if audioLevel > 0.3 {
                return Color(hue: hue, saturation: 0.8, brightness: 1.0)
            } else {
                return isListening ? Color.cyan : Color.green
            }
        } else {
            return Color.gray.opacity(0.6)
        }
    }

    private func startAnimations() {
        // Continuous rotation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }

        // Pulse effect
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.1
        }

        // Glow animation
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowOpacity = 0.6
        }

        updateAnimation()
    }

    private func updateAnimation() {
        if isListening || isSpeaking {
            for i in 0..<numberOfBars {
                animationValues[i] = CGFloat.random(in: 0.5...1.2)
            }
        } else {
            for i in 0..<numberOfBars {
                animationValues[i] = isAnimating ? CGFloat.random(in: 0.3...0.8) : 0.1
            }
        }
    }

    private func updateAudioLevelAnimation() {
        if (isListening || isSpeaking) && audioLevel > 0 {
            let scaledLevel = CGFloat(audioLevel) * 1.5
            for i in 0..<numberOfBars {
                animationValues[i] = max(0.2, scaledLevel + CGFloat.random(in: -0.3...0.3))
            }
        }
    }
}

struct PulsatingCircle: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.7

    let color: Color
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(color.opacity(opacity))
            .frame(width: size, height: size)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.2
                    opacity = 0.3
                }
            }
    }
}

struct AnimatedWaveBackground: View {
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                .cyan.opacity(0.1),
                                .blue.opacity(0.05),
                                .purple.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: CGFloat(100 + index * 50))
                    .scaleEffect(1.0 + animationOffset * 0.1)
                    .opacity(1.0 - animationOffset * 0.3)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 4.0)
                .repeatForever(autoreverses: true)
            ) {
                animationOffset = 1.0
            }
        }
    }
}
