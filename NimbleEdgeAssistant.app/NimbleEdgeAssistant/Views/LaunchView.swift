/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import SwiftUI

struct LaunchView: View {
    @Binding var isSDKInitialized: Bool
    @Binding var isSDKReady: Bool
    let onInitialize: () -> Void

    @State private var animationProgress: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var showInitializeButton = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.black,
                    Color.gray.opacity(0.1),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo and branding
                VStack(spacing: 16) {
                    // Animated logo placeholder
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulseScale)
                        .overlay(
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(.white)
                        )
                        .onAppear {
                            withAnimation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                            ) {
                                pulseScale = 1.1
                            }
                        }

                    // App title
                    HStack(spacing: 4) {
                        Text("Bharat Saathi")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("AI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                    }

                    Text("Your Private AI Assistant")
                        .font(.title3)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Status and controls
                VStack(spacing: 24) {
                    if isSDKReady {
                        // Ready state
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                                .scaleEffect(animationProgress)
                                .onAppear {
                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                                        animationProgress = 1.0
                                    }
                                }

                            Text("AI Assistant Ready!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    } else if isSDKInitialized {
                        // Initializing state
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.cyan)

                            Text("Loading AI Models...")
                                .font(.title3)
                                .foregroundColor(.white)

                            Text("This may take a moment on first launch")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        // Initial state
                        VStack(spacing: 16) {
                            if showInitializeButton {
                                Button(action: onInitialize) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "power")
                                            .font(.system(size: 20, weight: .medium))

                                        Text("Initialize AI Assistant")
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 30)
                                            .fill(
                                                LinearGradient(
                                                    colors: [.cyan, .blue],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                    )
                                    .scaleEffect(animationProgress)
                                }
                                .transition(.scale.combined(with: .opacity))
                            }

                            Text("✨ Fully on-device AI processing\n🔒 Complete privacy and security\n⚡ Works without internet")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            // Show initialize button after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                    showInitializeButton = true
                    animationProgress = 1.0
                }
            }
        }
    }
}
