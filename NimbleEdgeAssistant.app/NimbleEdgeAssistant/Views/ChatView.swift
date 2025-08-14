/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import SwiftUI
import DeliteAI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var chatManager: ChatManager

    var sarvamAI: SarvamAIService?

    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool

    private static let loadingId = UUID()

    init(chatManager: ChatManager, sarvamAI: SarvamAIService? = nil) {
        self.chatManager = chatManager
        self.sarvamAI = sarvamAI
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Navigation header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.gray.opacity(0.2)))
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("Bharat Saathi AI")
                            .font(.headline)
                            .foregroundColor(.white)

                        HStack(spacing: 4) {
                            // Status indicator
                            Circle()
                                .fill(chatManager.isModelReady ? Color.green : Color.orange)
                                .frame(width: 6, height: 6)

                            Text(chatManager.isModelReady ? "DialoGPT • Ready" : "Model Loading...")
                                .font(.caption)
                                .foregroundColor(chatManager.isModelReady ? .green : .gray)
                        }
                    }

                    Spacer()

                    Button(action: { chatManager.clearHistory() }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.black)

                Divider()
                    .background(Color.gray.opacity(0.2))

                // Chat messages
                if chatManager.messages.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(chatManager.messages) { message in
                                    MessageBubble(message: message)
                                        .id(message.id)
                                }

                                if chatManager.isLoading {
                                    TypingIndicator()
                                        .id(ChatView.loadingId)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .onChange(of: chatManager.messages.count) { _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                if let lastMessageId = chatManager.messages.last?.id {
                                    proxy.scrollTo(lastMessageId, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: chatManager.isLoading) { _ in
                            if chatManager.isLoading {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(ChatView.loadingId, anchor: .bottom)
                                }
                            }
                        }
                    }
                }

                // Input section
                VStack(spacing: 12) {
                    Divider()
                        .background(Color.gray.opacity(0.2))

                    HStack(spacing: 12) {
                        HStack(spacing: 12) {
                            TextField("Ask me anything...", text: $messageText, axis: .vertical)
                                .textFieldStyle(PlainTextFieldStyle())
                                .foregroundColor(.white)
                                .focused($isTextFieldFocused)
                                .lineLimit(1...4)

                            if !messageText.isEmpty {
                                Button(action: clearText) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )

                        Button(action: sendMessage) {
                            Image(systemName: chatManager.isLoading ? "stop.circle.fill" : "arrow.up.circle.fill")
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(canSend ? .cyan : .gray)
                        }
                        .disabled(!canSend && !chatManager.isLoading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .background(Color.black)
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            if let sarvamAI = sarvamAI {
                chatManager.setSarvamAIService(sarvamAI)
            }
        }
    }

    private var canSend: Bool {
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !chatManager.isLoading
    }

    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        let currentMessage = messageText
        messageText = ""

        Task {
            // ChatManager.sendMessage now handles adding the user message
            await chatManager.sendMessage(currentMessage)
        }
    }

    private func clearText() {
        messageText = ""
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.cyan)

                VStack(spacing: 8) {
                    Text("Hi there! 👋")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("I'm your private AI assistant. Ask me anything!")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: 12) {
                Text("Try asking me:")
                    .font(.caption)
                    .foregroundColor(.gray)

                VStack(spacing: 8) {
                    ForEach(sampleQuestions, id: \.self) { question in
                        Text("• \(question)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private let sampleQuestions = [
        "Write a haiku about technology",
        "Explain quantum computing",
        "Help me plan my day",
        "What's a healthy breakfast recipe?"
    ]
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.cyan)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.cyan.opacity(0.1)))

                        Text(message.content)
                            .font(.body)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.gray.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .padding(.leading, 44)
                }

                Spacer(minLength: 50)
            }
        }
    }
}

struct TypingIndicator: View {
    @State private var animatingDots = false

    var body: some View {
        HStack {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.cyan)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.cyan.opacity(0.1)))

                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                            .scaleEffect(animatingDots ? 1.0 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: animatingDots
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            }

            Spacer(minLength: 50)
        }
        .onAppear {
            animatingDots = true
        }
    }
}
