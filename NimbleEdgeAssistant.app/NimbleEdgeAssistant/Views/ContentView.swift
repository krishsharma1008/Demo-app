/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import SwiftUI
import UIKit
import Foundation
import AVFoundation

// MARK: - Sarvam AI Service (Embedded)
class SarvamAIService: ObservableObject {
    private let apiKey = "sk_expgu3fc_onbGOO7xjKGLXhsVPwjGVxnG"
    private let baseURL = "https://api.sarvam.ai"
    private var audioPlayer: AVAudioPlayer?

    @Published var isOnline = false
    @Published var isProcessing = false

    init() {
        checkOnlineStatus()
    }

    private func checkOnlineStatus() {
        // Simple network connectivity check
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
            isOnline = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0
        request.setValue(apiKey, forHTTPHeaderField: "api-subscription-key")

        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    self.isOnline = httpResponse.statusCode == 401 || httpResponse.statusCode == 200 || httpResponse.statusCode == 405
                    // 405 Method Not Allowed is expected for HEAD request on this endpoint
                } else {
                    self.isOnline = false
                }
            }
        }.resume()
    }

    func sendChatMessage(_ message: String, language: String = "en-IN") async throws -> String {
        guard !apiKey.isEmpty else {
            throw SarvamAIError.missingAPIKey
        }

        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else {
            throw SarvamAIError.invalidURL
        }

        DispatchQueue.main.async {
            self.isProcessing = true
        }

        defer {
            DispatchQueue.main.async {
                self.isProcessing = false
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "api-subscription-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Create language-specific system prompt
        let languageNames = [
            "en-IN": "English",
            "hi-IN": "Hindi (हिंदी)",
            "ta-IN": "Tamil (தமிழ்)",
            "te-IN": "Telugu (తెలుగు)",
            "bn-IN": "Bengali (বাংলা)",
            "gu-IN": "Gujarati (ગુજરાતી)",
            "mr-IN": "Marathi (मराठी)",
            "kn-IN": "Kannada (ಕನ್ನಡ)"
        ]

        let languageName = languageNames[language] ?? "English"
        let systemPrompt = language == "en-IN"
            ? "You are a helpful AI assistant. Respond in a friendly and informative manner in English."
            : "You are a helpful AI assistant. Respond in a friendly and informative manner in \(languageName). Always respond in \(languageName) language only, even if the user asks in English."

        // Updated request body based on Sarvam AI documentation
        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": message
                ]
            ],
            "model": "sarvam-m"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            throw SarvamAIError.apiError("Failed to serialize request: \(error.localizedDescription)")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SarvamAIError.networkError
        }

        print("📡 Sarvam AI Response Status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            // Better error parsing
            if let errorString = String(data: data, encoding: .utf8) {
                print("📡 Sarvam AI Error Response: \(errorString)")
            }

            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let error = errorData["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    throw SarvamAIError.apiError("API Error: \(message)")
                } else if let message = errorData["message"] as? String {
                    throw SarvamAIError.apiError("API Error: \(message)")
                } else if let detail = errorData["detail"] as? String {
                    throw SarvamAIError.apiError("API Error: \(detail)")
                }
            }
            throw SarvamAIError.apiError("HTTP \(httpResponse.statusCode): \(HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))")
        }

        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Sarvam AI Raw Response: \(responseString.prefix(200))...")
        }

        do {
            let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
            return chatResponse.choices.first?.message.content ?? "No response available"
        } catch {
            print("📡 Sarvam AI Decode Error: \(error)")
            // Fallback: try to parse as simple text response
            if let responseString = String(data: data, encoding: .utf8) {
                return responseString
            }
            throw SarvamAIError.apiError("Failed to decode response: \(error.localizedDescription)")
        }
    }

    func synthesizeSpeech(_ text: String, language: String = "hi-IN") async throws {
        guard !apiKey.isEmpty else {
            throw SarvamAIError.missingAPIKey
        }

        guard let url = URL(string: "\(baseURL)/text-to-speech") else {
            throw SarvamAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "api-subscription-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "text": text,
            "target_language_code": language,
            "speaker": "meera",
            "quality": "medium"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SarvamAIError.networkError
        }

        let ttsResponse = try JSONDecoder().decode(TTSResponse.self, from: data)

        // Play the audio
        if let audioBase64 = ttsResponse.audios.first,
           let audioData = Data(base64Encoded: audioBase64) {
            try await playAudio(data: audioData)
        }
    }

    func speechToText(audioData: Data, language: String = "hi-IN") async throws -> String {
        guard !apiKey.isEmpty else {
            throw SarvamAIError.missingAPIKey
        }

        guard let url = URL(string: "\(baseURL)/speech-to-text") else {
            throw SarvamAIError.invalidURL
        }

        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "api-subscription-key")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("saarika:v2\r\n".data(using: .utf8)!)

        // Add language code parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"language_code\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(language)\r\n".data(using: .utf8)!)

        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SarvamAIError.networkError
        }

        print("📡 Sarvam STT Response Status: \(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            if let errorString = String(data: data, encoding: .utf8) {
                print("📡 Sarvam STT Error Response: \(errorString)")
            }
            throw SarvamAIError.apiError("STT API Error: HTTP \(httpResponse.statusCode)")
        }

        // Parse the response
        if let responseString = String(data: data, encoding: .utf8) {
            print("📡 Sarvam STT Raw Response: \(responseString)")
        }

        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let transcript = jsonResponse["transcript"] as? String {
                return transcript
            } else {
                throw SarvamAIError.apiError("Failed to parse STT response")
            }
        } catch {
            throw SarvamAIError.apiError("Failed to decode STT response: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func playAudio(data: Data) async throws {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.play()

            // Wait for audio to finish
            while audioPlayer?.isPlaying == true {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        } catch {
            throw SarvamAIError.audioPlaybackError
        }
    }
}

// MARK: - Response Models
struct ChatCompletionResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message

        struct Message: Codable {
            let content: String
            let role: String
        }
    }
}

struct TTSResponse: Codable {
    let audios: [String]
}

// MARK: - Error Types
enum SarvamAIError: Error, LocalizedError {
    case missingAPIKey
    case invalidURL
    case networkError
    case audioPlaybackError
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Sarvam AI API key is missing"
        case .invalidURL:
            return "Invalid API URL"
        case .networkError:
            return "Network error occurred"
        case .audioPlaybackError:
            return "Audio playback failed"
        case .apiError(let message):
            return "API Error: \(message)"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var showingChat = false
    @State private var showingVoiceMode = false
    @StateObject private var sarvamAI = SarvamAIService()
    @StateObject private var sharedChatManager = ChatManager()

    var body: some View {
        TabView(selection: $selectedTab) {
            ModernHomeView(
                showingChat: $showingChat,
                showingVoiceMode: $showingVoiceMode,
                selectedTab: $selectedTab,
                sarvamAI: sarvamAI
            )
            .tabItem {
                Image(systemName: tabIcon(for: 0))
                Text(tabTitle(for: 0))
            }
            .tag(0)

            ChatHistoryView(chatManager: sharedChatManager)
                .tabItem {
                    Image(systemName: tabIcon(for: 1))
                    Text(tabTitle(for: 1))
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Image(systemName: tabIcon(for: 2))
                    Text(tabTitle(for: 2))
                }
                .tag(2)
        }
        .accentColor(.cyan)
        .onAppear {
            // Set up Sarvam AI integration for shared chat manager
            sharedChatManager.setSarvamAIService(sarvamAI)
        }
        .sheet(isPresented: $showingChat) {
            ChatView(chatManager: sharedChatManager, sarvamAI: sarvamAI)
        }
        .sheet(isPresented: $showingVoiceMode) {
            VoiceModeView(sarvamAI: sarvamAI)
        }
    }

    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "house.fill"
        case 1: return "clock.fill"
        case 2: return "gearshape.fill"
        default: return "house.fill"
        }
    }

    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Home"
        case 1: return "History"
        case 2: return "Settings"
        default: return "Home"
        }
    }
}

struct ModernHomeView: View {
    @Binding var showingChat: Bool
    @Binding var showingVoiceMode: Bool
    @Binding var selectedTab: Int
    @ObservedObject var sarvamAI: SarvamAIService
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var localization = LocalizationManager.shared

    @State private var greeting = ""
    @State private var animateGlow = false
    @State private var animateParticles = false
    @State private var touchLocation: CGPoint = .zero
    @State private var isTouching = false

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
        GeometryReader { geometry in
            ZStack {
                // Modern gradient background
                LinearGradient(
                    colors: [
                        Color.black,
                        Color.blue.opacity(0.1),
                        Color.cyan.opacity(0.05),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Animated background particles
                ForEach(0..<15, id: \.self) { index in
                    Circle()
                        .fill(Color.cyan.opacity(0.1))
                        .frame(width: CGFloat.random(in: 2...4))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(animateParticles ? 0.3 : 0.1)
                        .animation(
                            .easeInOut(duration: Double.random(in: 3...6))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2)),
                            value: animateParticles
                        )
                }

                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section
                        headerSection
                            .padding(.top, 20)

                        Spacer(minLength: 40)

                        // Main Interaction Area
                        mainInteractionArea

                        Spacer(minLength: 40)

                        // Action Cards
                        actionCardsSection

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .onAppear {
            updateGreeting()
            startAnimations()
        }
        .onChange(of: languageManager.selectedLanguage) { _ in
            updateGreeting()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                                            Text("Bharat Saathi AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(localization.getText("how_can_help"))
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Status indicator
                statusIndicator
            }

            // Language selector for online mode
            if sarvamAI.isOnline {
                languageSelector
            }
        }
    }

    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(sarvamAI.isOnline ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            Text(sarvamAI.isOnline ? localization.getText("online") : localization.getText("offline"))
                .font(.caption)
                .foregroundColor(sarvamAI.isOnline ? .green : .gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(sarvamAI.isOnline ? Color.green.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private var languageSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(languageManager.supportedLanguages, id: \.1) { language in
                    Button(action: {
                        languageManager.setLanguage(language.1)

                        // Update voice recognition language
                        Task { @MainActor in
                            // We'll need to access VoiceManager from VoiceModeView
                            // For now, we'll handle this in VoiceModeView.onAppear
                        }

                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }) {
                        Text(language.0)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(languageManager.selectedLanguage == language.1 ? .black : .white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(languageManager.selectedLanguage == language.1 ? Color.cyan : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                                    )
                            )
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: languageManager.selectedLanguage)
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Main Interaction Area
    private var mainInteractionArea: some View {
        VStack(spacing: 24) {
            // Interactive Atomic Sphere
            ZStack {
                // Outer glow rings
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.cyan.opacity(0.3), .blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 200 + CGFloat(ring * 40))
                        .opacity(animateGlow ? 0.6 : 0.2)
                        .scaleEffect(animateGlow ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 2.0 + Double(ring) * 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(ring) * 0.3),
                            value: animateGlow
                        )
                }

                // Main atomic sphere
                atomicSphere
            }
            .frame(height: 280)

            // Interaction instructions
            VStack(spacing: 8) {
                Text(localization.getText("ai_voice_assistant"))
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(sarvamAI.isOnline ?
                     "\(localization.getText("touch_sphere_voice")) • \(localization.getText("chat_in_language")) \(languageManager.selectedLanguageName)" :
                     "\(localization.getText("touch_sphere_voice")) • \(localization.getText("offline_mode"))"
                )
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
    }

    private var atomicSphere: some View {
        ZStack {
            // Background sphere
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.cyan.opacity(0.3),
                            Color.blue.opacity(0.2),
                            Color.cyan.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(animateGlow ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: animateGlow)

            // Interactive particles
            ForEach(0..<24, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.white, .cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 3, height: 3)
                    .offset(interactiveParticleOffset(index: index))
                    .scaleEffect(animateParticles ? 1.2 : 0.8)
                    .opacity(animateParticles ? 1.0 : 0.7)
                    .animation(
                        .easeInOut(duration: 1.8 + Double(index) * 0.02)
                        .repeatForever(autoreverses: true),
                        value: animateParticles
                    )
                    .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isTouching)
            }

            // Central core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.9), .cyan.opacity(0.7), .blue.opacity(0.4)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 15
                    )
                )
                .frame(width: 20, height: 20)
                .scaleEffect(animateGlow ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateGlow)
        }
        .contentShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    touchLocation = value.location
                    if !isTouching {
                        isTouching = true
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                    }
                }
                .onEnded { _ in
                    isTouching = false
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    showingVoiceMode = true
                }
        )
    }

    // MARK: - Action Cards Section
    private var actionCardsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Chat Card
                ModernActionCard(
                    icon: sarvamAI.isOnline ? "globe" : "message.circle.fill",
                    title: sarvamAI.isOnline ? "Online Chat" : "Local Chat",
                    subtitle: sarvamAI.isOnline ? "Powered by Sarvam AI" : "Local AI Assistant",
                    color: .cyan,
                    isPrimary: true
                ) {
                    showingChat = true
                }

                // History Card
                ModernActionCard(
                    icon: "clock.fill",
                    title: "History",
                    subtitle: "View past conversations",
                    color: .purple,
                    isPrimary: false
                ) {
                    selectedTab = 1
                }
            }

            // Settings Card (Full Width)
            ModernActionCard(
                icon: "gearshape.fill",
                title: "Settings",
                subtitle: "Customize your AI experience",
                color: .gray,
                isPrimary: false,
                isFullWidth: true
            ) {
                selectedTab = 2
            }
        }
    }

    // MARK: - Helper Functions
    private func updateGreeting() {
        greeting = localization.getGreeting()
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animateGlow = true
        }

        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            animateParticles = true
        }
    }

    private func interactiveParticleOffset(index: Int) -> CGSize {
        let angle = (Double(index) / 24.0) * 2.0 * .pi
        let baseRadius: CGFloat = 60 + CGFloat(index % 4) * 8

        let baseX = cos(angle) * baseRadius
        let baseY = sin(angle) * baseRadius

        if isTouching {
            let particleX = baseX + 100
            let particleY = baseY + 100

            let deltaX = particleX - touchLocation.x
            let deltaY = particleY - touchLocation.y
            let distance = sqrt(deltaX * deltaX + deltaY * deltaY)

            let repulsionStrength: CGFloat = 50
            let maxDistance: CGFloat = 100

            if distance < maxDistance && distance > 0 {
                let repulsionFactor = (maxDistance - distance) / maxDistance
                let pushX = (deltaX / distance) * repulsionStrength * repulsionFactor
                let pushY = (deltaY / distance) * repulsionStrength * repulsionFactor

                return CGSize(width: baseX + pushX, height: baseY + pushY)
            }
        }

        return CGSize(width: baseX, height: baseY)
    }
}

// MARK: - Modern Action Card Component
struct ModernActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isPrimary: Bool
    let isFullWidth: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(icon: String, title: String, subtitle: String, color: Color, isPrimary: Bool, isFullWidth: Bool = false, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.isPrimary = isPrimary
        self.isFullWidth = isFullWidth
        self.action = action
    }

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(alignment: isFullWidth ? .leading : .center, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(isPrimary ? .black : color)

                    if isFullWidth {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(isPrimary ? .black : .white)

                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(isPrimary ? .black.opacity(0.7) : .gray)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(isPrimary ? .black.opacity(0.7) : .gray)
                    }
                }

                if !isFullWidth {
                    VStack(spacing: 4) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isPrimary ? .black : .white)

                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(isPrimary ? .black.opacity(0.7) : .gray)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isPrimary ? color : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(isPrimary ? 0 : 0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
    }
}

// MARK: - Press Event Modifier
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventModifier(onPress: onPress, onRelease: onRelease))
    }
}

struct PressEventModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

#Preview {
    ContentView()
}
