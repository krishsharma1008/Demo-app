/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import SwiftUI

struct OnlineChatView: View {
    @ObservedObject var sarvamAI: SarvamAIService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var chatManager = OnlineChatManager()

    @State private var inputText = ""
    @State private var selectedLanguage = "en-IN"
    @State private var isTyping = false
    @State private var showingLanguagePicker = false

    private let languages = [
        ("English", "en-IN"),
        ("Hindi", "hi-IN"),
        ("Tamil", "ta-IN"),
        ("Telugu", "te-IN"),
        ("Bengali", "bn-IN"),
        ("Gujarati", "gu-IN"),
        ("Marathi", "mr-IN"),
        ("Kannada", "kn-IN")
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.blue.opacity(0.05),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerView

                    // Messages
                    messagesView

                    // Input area
                    inputView
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            chatManager.setSarvamAIService(sarvamAI)
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("Sarvam AI Chat")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)

                        Text("Online")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                Button(action: { showingLanguagePicker = true }) {
                    Image(systemName: "globe")
                        .font(.title2)
                        .foregroundColor(.cyan)
                }
            }

            // Language selector
            if showingLanguagePicker {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(languages, id: \.1) { language in
                            Button(action: {
                                selectedLanguage = language.1
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                            }) {
                                Text(language.0)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(selectedLanguage == language.1 ? .black : .white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(selectedLanguage == language.1 ? Color.cyan : Color.clear)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                                            )
                                    )
                            }
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedLanguage)
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .transition(.opacity.combined(with: .slide))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingLanguagePicker)
    }

    // MARK: - Messages View
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(chatManager.messages) { message in
                        OnlineMessageView(message: message)
                            .id(message.id)
                    }

                    if chatManager.isLoading {
                        TypingIndicatorView()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: chatManager.messages.count) { _ in
                withAnimation(.easeOut(duration: 0.3)) {
                    if let lastMessage = chatManager.messages.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Input View
    private var inputView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))

            HStack(spacing: 12) {
                // Text input
                HStack {
                    TextField("Type your message...", text: $inputText, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .accentColor(.cyan)
                        .lineLimit(1...4)
                        .onChange(of: inputText) { _ in
                            isTyping = !inputText.isEmpty
                        }

                    if !inputText.isEmpty {
                        Button(action: clearText) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                        )
                )

                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(inputText.isEmpty ? .gray : .cyan)
                }
                .disabled(inputText.isEmpty || chatManager.isLoading)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: inputText.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.black)
    }

    // MARK: - Actions
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let messageText = inputText
        inputText = ""
        isTyping = false

        Task {
            await chatManager.sendMessage(messageText, language: selectedLanguage)
        }

        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }

    private func clearText() {
        inputText = ""
        isTyping = false
    }
}

// MARK: - Online Message View
struct OnlineMessageView: View {
    let message: OnlineChatMessage

    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 50)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                        )

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)

                        Text("Sarvam AI")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)

                        Spacer()

                        if message.hasAudio {
                            Button(action: {
                                // Play audio
                            }) {
                                Image(systemName: "speaker.wave.2.fill")
                                    .font(.caption)
                                    .foregroundColor(.cyan)
                            }
                        }
                    }

                    Text(message.content)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )

                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer(minLength: 50)
            }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicatorView: View {
    @State private var animatePhase = 0

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)

                    Text("Sarvam AI")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }

                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.gray)
                            .frame(width: 6, height: 6)
                            .opacity(animatePhase == index ? 1 : 0.3)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                )
            }

            Spacer(minLength: 50)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    animatePhase = (animatePhase + 1) % 3
                }
            }
        }
    }
}

// MARK: - Online Chat Manager
class OnlineChatManager: ObservableObject {
    @Published var messages: [OnlineChatMessage] = []
    @Published var isLoading = false

    private var sarvamAI: SarvamAIService?

    func setSarvamAIService(_ service: SarvamAIService) {
        self.sarvamAI = service
    }

    @MainActor
    func sendMessage(_ text: String, language: String) async {
        // Add user message
        let userMessage = OnlineChatMessage(
            id: UUID(),
            content: text,
            isUser: true,
            timestamp: Date(),
            hasAudio: false
        )
        messages.append(userMessage)

        isLoading = true

        do {
            // Get response from Sarvam AI
            guard let sarvamAI = sarvamAI else { return }
            let response = try await sarvamAI.sendChatMessage(text, language: language)

            // Add AI response
            let aiMessage = OnlineChatMessage(
                id: UUID(),
                content: response,
                isUser: false,
                timestamp: Date(),
                hasAudio: true
            )
            messages.append(aiMessage)

            // Generate and play audio
            try await sarvamAI.synthesizeSpeech(response, language: language)

        } catch {
            // Add error message
            let errorMessage = OnlineChatMessage(
                id: UUID(),
                content: "Sorry, I encountered an error: \(error.localizedDescription)",
                isUser: false,
                timestamp: Date(),
                hasAudio: false
            )
            messages.append(errorMessage)
        }

        isLoading = false
    }
}

// MARK: - Online Chat Message Model
struct OnlineChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    let hasAudio: Bool
}

#Preview {
    OnlineChatView(sarvamAI: SarvamAIService())
}
