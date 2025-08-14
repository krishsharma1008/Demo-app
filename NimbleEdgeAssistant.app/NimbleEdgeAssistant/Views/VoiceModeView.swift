/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import SwiftUI
import AVFoundation
import Speech

struct VoiceModeView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var voiceManager = VoiceManager()
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @StateObject private var chatManager = ChatManager()

    @State private var isListening = false
    @State private var isSpeaking = false
    @State private var currentTranscript = ""
    @State private var conversationHistory: [VoiceMessage] = []

    let sarvamAI: SarvamAIService?

    init(sarvamAI: SarvamAIService? = nil) {
        self.sarvamAI = sarvamAI
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
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
                            Text("\(localization.getText("voice_mode")) • \(languageManager.selectedLanguageName)")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(isListening ? localization.getText("listening") :
                                 isSpeaking ? localization.getText("speaking") :
                                 localization.getText("tap_to_speak"))
                                .font(.caption)
                                .foregroundColor(isListening ? .cyan : isSpeaking ? .green : .gray)
                        }

                        Spacer()

                        Button(action: { conversationHistory.removeAll() }) {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    Spacer()

                    // Central voice interface
                    VStack(spacing: 40) {
                        // Interactive voice visualization with haptic feedback
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
                                        endRadius: 120
                                    )
                                )
                                .frame(width: 240, height: 240)
                                .scaleEffect(isListening ? 1.2 : isSpeaking ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isListening || isSpeaking)

                            // Animated ring of dots
                            ForEach(0..<16, id: \.self) { index in
                                Circle()
                                    .fill(getDotColor(for: index))
                                    .frame(width: isListening || isSpeaking ? 8 : 4, height: isListening || isSpeaking ? 8 : 4)
                                    .offset(
                                        x: cos(Double(index) * .pi * 2 / 16) * 80,
                                        y: sin(Double(index) * .pi * 2 / 16) * 80
                                    )
                                    .scaleEffect(getDotScale(for: index))
                                    .animation(.easeInOut(duration: 1.0 + Double(index) * 0.1).repeatForever(autoreverses: true), value: isListening || isSpeaking)
                            }

                            // Central interactive area
                            VStack(spacing: 8) {
                                Image(systemName: getVoiceIcon())
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(getVoiceColor())
                                    .scaleEffect(isListening || isSpeaking ? 1.2 : 1.0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isListening || isSpeaking)

                                Text(getVoiceStatusText())
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .opacity(0.8)
                            }
                        }
                        .frame(width: 240, height: 240)
                        .onTapGesture {
                            // Haptic feedback on tap
                            voiceManager.performMediumHaptic()

                            if isListening {
                                stopListening()
                            } else {
                                startListening()
                            }
                        }

                        // Current transcript with enhanced styling
                        if !currentTranscript.isEmpty {
                            ScrollView {
                                VStack(spacing: 12) {
                                    Text("You said:")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .textCase(.uppercase)
                                        .tracking(1.0)

                                    Text(currentTranscript)
                                        .font(.title2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 32)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.gray.opacity(0.1))
                                                .blur(radius: 10)
                                        )
                                }
                            }
                            .frame(maxHeight: 120)
                        } else if !conversationHistory.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)

                                Text("Conversation active")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                        } else {
                            VStack(spacing: 16) {
                                VStack(spacing: 8) {
                                    Image(systemName: "waveform.circle")
                                        .font(.system(size: 32))
                                        .foregroundColor(.cyan.opacity(0.7))

                                    Text("Voice Assistant Ready")
                                        .font(.title3)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }

                                VStack(spacing: 4) {
                                    Text("Tap the ring to start speaking")
                                        .font(.body)
                                        .foregroundColor(.gray)

                                    Text("Touch and hold for continuous listening")
                                        .font(.caption)
                                        .foregroundColor(.gray.opacity(0.7))
                                }
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            }
                        }
                    }

                    Spacer()

                    // Conversation history (compact)
                    if !conversationHistory.isEmpty {
                        VStack(spacing: 0) {
                            Divider()
                                .background(Color.gray.opacity(0.2))

                            ScrollView {
                                LazyVStack(spacing: 8) {
                                    ForEach(conversationHistory.suffix(3)) { message in
                                        CompactVoiceMessageView(message: message)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }
                            .frame(maxHeight: 120)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            voiceManager.requestPermissions()
            voiceManager.updateLanguage() // Update to current language

            // Set up Sarvam AI integration if available
            if let sarvamAI = sarvamAI {
                chatManager.setSarvamAIService(sarvamAI)
            }
        }
        .onChange(of: languageManager.selectedLanguage) { _ in
            // Update voice recognition when language changes
            voiceManager.updateLanguage()
        }
        .onChange(of: voiceManager.transcript) { transcript in
            currentTranscript = transcript
        }
        .onChange(of: voiceManager.finalTranscript) { finalTranscript in
            print("🎤 Final transcript received: '\(finalTranscript)'")
            if !finalTranscript.isEmpty {
                processVoiceInput(finalTranscript)
                currentTranscript = ""
                // Clear the final transcript to prevent reprocessing
                voiceManager.finalTranscript = ""
            }
        }
    }

    private func startListening() {
        guard !isListening else { return }

        // Haptic feedback for start
        voiceManager.performListeningStartHaptic()

        Task {
            await voiceManager.requestPermissions()

            if voiceManager.hasPermission {
                await MainActor.run {
                    isListening = true
                    currentTranscript = ""
                }

                // Choose between Sarvam STT and local speech recognition
                if let sarvamAI = sarvamAI, sarvamAI.isOnline {
                    print("🌐 Using Sarvam STT for voice recognition")
                    // Start audio recording for Sarvam STT
                    if voiceManager.startRecording() {
                        print("🎤 Recording started for Sarvam STT")
                    } else {
                        print("❌ Failed to start recording, falling back to local STT")
                        await voiceManager.startAdvancedListening()
                    }
                } else {
                    print("🤖 Using local speech recognition")
                    await voiceManager.startAdvancedListening()
                }
            } else {
                // Show permission request or error
                await MainActor.run {
                    // Handle permission denied state
                    print("Voice permission denied")
                }
            }
        }
    }

    private func stopListening() {
        guard isListening else { return }

        // Haptic feedback for stop
        voiceManager.performListeningStopHaptic()

        isListening = false

        // Handle different STT methods
        if let sarvamAI = sarvamAI, sarvamAI.isOnline {
            // Stop recording and process with Sarvam STT
            if let audioData = voiceManager.stopRecording() {
                print("🌐 Processing audio with Sarvam STT")
                Task {
                    do {
                        let transcript = try await sarvamAI.speechToText(
                            audioData: audioData,
                            language: languageManager.selectedLanguage
                        )

                        await MainActor.run {
                            if !transcript.isEmpty {
                                print("🎤 Sarvam STT transcript: '\(transcript)'")
                                processVoiceInput(transcript)
                            }
                        }
                    } catch {
                        print("❌ Sarvam STT failed: \(error)")
                        // Could implement fallback here if needed
                        await MainActor.run {
                            currentTranscript = "Sorry, I couldn't understand that. Please try again."
                        }
                    }
                }
            }
        } else {
            // Use local speech recognition result
            voiceManager.stopListening()

            // Process the final transcript from local STT
            if !voiceManager.finalTranscript.isEmpty {
                processVoiceInput(voiceManager.finalTranscript)
            }
        }
    }

    private func processVoiceInput(_ input: String) {
        print("🎤 Processing voice input: '\(input)'")

        // Add user message to conversation
        let userMessage = VoiceMessage(
            content: input,
            isUser: true
        )
        conversationHistory.append(userMessage)

        // Start processing with haptic feedback
        voiceManager.performMediumHaptic()
        voiceManager.isProcessing = true

        print("🔄 Starting AI processing...")

        // Use ChatManager for AI response with Sarvam AI integration
        Task {
            await MainActor.run {
                isSpeaking = true
                print("🎵 Set speaking state to true")
            }

            do {
                print("📡 Sending message to ChatManager...")
                // Get AI response through ChatManager (includes Sarvam AI if online)
                // Disable TTS since voice mode handles its own local TTS
                await chatManager.sendMessage(input, enableTTS: false)

                print("⏳ Waiting for response to be processed...")
                // Wait a moment for the response to be added to messages
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                // Get the latest AI response from ChatManager
                let response = await MainActor.run {
                    let lastMessage = chatManager.messages.last?.content ?? "I'm here to help with your question!"
                    print("📝 Retrieved response: '\(lastMessage)'")
                    return lastMessage
                }

                print("🤖 AI Response for voice: '\(response)'")

                await MainActor.run {
                    let aiMessage = VoiceMessage(
                        content: response,
                        isUser: false
                    )
                    conversationHistory.append(aiMessage)

                    print("🎵 Starting local TTS...")
                    // For voice mode, use local TTS for immediate feedback
                    // Note: Sarvam AI TTS is already handled in ChatManager for chat mode
                    voiceManager.speakWithExpression(response, emotion: .friendly)
                    voiceManager.performSpeakingStartHaptic()

                    voiceManager.isProcessing = false
                    isSpeaking = false
                    currentTranscript = ""
                    print("✅ Voice processing completed")
                }
            } catch {
                print("❌ Error processing voice input: \(error)")

                // Fallback response
                let fallbackResponse = "I'm sorry, I couldn't process that. Could you please try again?"

                await MainActor.run {
                    let aiMessage = VoiceMessage(
                        content: fallbackResponse,
                        isUser: false
                    )
                    conversationHistory.append(aiMessage)

                    voiceManager.speakWithExpression(fallbackResponse, emotion: .calm)
                    voiceManager.performSpeakingStartHaptic()

                    voiceManager.isProcessing = false
                    isSpeaking = false
                    currentTranscript = ""
                    print("🚨 Used fallback response")
                }
            }
        }
    }

    private func generateAIResponse(for input: String) -> String {
        // This would integrate with your ChatManager for actual AI responses
        // For now, providing contextual responses

        let lowercaseInput = input.lowercased()

        if lowercaseInput.contains("hello") || lowercaseInput.contains("hi") {
            return "Hello! How can I help you today?"
        } else if lowercaseInput.contains("weather") {
            return "I'd be happy to help with weather information. Unfortunately, I don't have access to current weather data right now, but you can check your local weather app for the most up-to-date information."
        } else if lowercaseInput.contains("time") {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "The current time is \(formatter.string(from: Date()))."
        } else if lowercaseInput.contains("thank") {
            return "You're very welcome! Is there anything else I can help you with?"
        } else {
            return "I heard you say: '\(input)'. How can I assist you with that?"
        }
    }

    private func getDotColor(for index: Int) -> Color {
        if isListening {
            return .cyan
        } else if isSpeaking {
            return .green
        } else {
            return .gray.opacity(0.5)
        }
    }

    private func getDotScale(for index: Int) -> CGFloat {
        if isListening || isSpeaking {
            return CGFloat.random(in: 0.8...1.2)
        } else {
            return 1.0
        }
    }

    private func getVoiceIcon() -> String {
        if isListening {
            return "stop.fill"
        } else {
            return "mic.fill"
        }
    }

    private func getVoiceColor() -> Color {
        if isListening {
            return .white
        } else if isSpeaking {
            return .white
        } else {
            return .gray
        }
    }

    private func getVoiceStatusText() -> String {
        if isListening {
            return "Listening..."
        } else if isSpeaking {
            return "Speaking..."
        } else {
            return "Tap to speak"
        }
    }
}

struct CompactVoiceMessageView: View {
    let message: VoiceMessage

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: message.isUser ? "person.circle.fill" : "brain.head.profile")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(message.isUser ? .cyan : .green)

            Text(message.content)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Voice Message Model
struct VoiceMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

