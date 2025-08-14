/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import AVFoundation

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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { _, response, _ in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    self.isOnline = httpResponse.statusCode == 401 || httpResponse.statusCode == 200
                    // 401 is expected for HEAD request with valid auth, 200 is also good
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
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "messages": [
                [
                    "role": "system",
                    "content": "You are a helpful AI assistant. Respond in a friendly and informative manner."
                ],
                [
                    "role": "user",
                    "content": message
                ]
            ],
            "model": "sarvam-2b-v0.5",
            "max_tokens": 500,
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SarvamAIError.networkError
        }

        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorData["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw SarvamAIError.apiError(message)
            }
            throw SarvamAIError.networkError
        }

        let chatResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return chatResponse.choices.first?.message.content ?? "No response available"
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

    func translateText(_ text: String, from sourceLanguage: String = "auto", to targetLanguage: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/translate") else {
            throw SarvamAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "api-subscription-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "input": text,
            "source_language_code": sourceLanguage,
            "target_language_code": targetLanguage
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SarvamAIError.networkError
        }

        let translationResponse = try JSONDecoder().decode(TranslationResponse.self, from: data)
        return translationResponse.translated_text
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

struct TranslationResponse: Codable {
    let translated_text: String
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
