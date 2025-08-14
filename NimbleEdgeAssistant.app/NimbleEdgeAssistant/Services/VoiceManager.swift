/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation
import Speech
import AVFoundation
import Combine
import UIKit // Added for haptic feedback

@MainActor
class VoiceManager: NSObject, ObservableObject {
    @Published var transcript = ""
    @Published var finalTranscript = ""
    @Published var audioLevel: Float = 0.0
    @Published var isListening = false
    @Published var hasPermission = false

    // MARK: - Expressive Voice Interactions
    @Published var voiceEmotionLevel: Float = 0.5
    @Published var speechRate: Float = 0.5
    @Published var voicePitch: Float = 1.0
    @Published var isProcessing = false

    // Haptic feedback generators
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let selectionGenerator = UISelectionFeedbackGenerator()

    // Language support
    private let languageManager = LanguageManager.shared
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()

    private let speechSynthesizer = AVSpeechSynthesizer()
    private var audioSession = AVAudioSession.sharedInstance()

    private var audioLevelTimer: Timer?

    // Language to locale mapping for speech recognition
    private let languageLocales = [
        "en-IN": "en-IN",
        "hi-IN": "hi-IN",
        "ta-IN": "ta-IN",
        "te-IN": "te-IN",
        "bn-IN": "bn-IN",
        "gu-IN": "gu-IN",
        "mr-IN": "mr-IN",
        "kn-IN": "kn-IN"
    ]

    override init() {
        super.init()
        setupSpeechRecognizer()
        speechSynthesizer.delegate = self
        setupAudioSession()
        prepareHapticGenerators()
    }

    private func setupSpeechRecognizer() {
        let locale = languageLocales[languageManager.selectedLanguage] ?? "en-IN"
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: locale))
        print("🎤 Speech recognizer set to: \(locale)")
    }

    func updateLanguage() {
        // Stop current recognition if active
        stopListening()

        // Setup new speech recognizer for the selected language
        setupSpeechRecognizer()

        performLightHaptic()
        print("🌍 Voice recognition updated to: \(languageManager.selectedLanguageName)")
    }

    private func prepareHapticGenerators() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        selectionGenerator.prepare()
    }

    // MARK: - Enhanced Haptic Feedback
    func performLightHaptic() {
        lightImpactGenerator.impactOccurred()
    }

    func performMediumHaptic() {
        mediumImpactGenerator.impactOccurred()
    }

    func performHeavyHaptic() {
        heavyImpactGenerator.impactOccurred()
    }

    func performSelectionHaptic() {
        selectionGenerator.selectionChanged()
    }

    func performListeningStartHaptic() {
        // Double tap feedback for listening start
        performMediumHaptic()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.performLightHaptic()
        }
    }

    func performListeningStopHaptic() {
        // Triple tap feedback for listening stop
        performLightHaptic()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.performMediumHaptic()
        }
    }

    func performSpeakingStartHaptic() {
        // Gentle continuous feedback for speaking
        performLightHaptic()
    }

    func requestPermissions() {
        Task {
            // Request speech recognition permission
            let speechStatus = await requestSpeechPermission()

            // Request microphone permission
            let micStatus = await requestMicrophonePermission()

            await MainActor.run {
                hasPermission = speechStatus && micStatus
            }
        }
    }

    private func requestSpeechPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    private func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }

    func startListening() {
        guard hasPermission else {
            print("No permission to record audio")
            return
        }

        // Stop any previous tasks
        stopListening()

        do {
            try startSpeechRecognition()
            isListening = true
            startAudioLevelMonitoring()
        } catch {
            print("Failed to start speech recognition: \(error)")
        }
    }

    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil

        isListening = false
        stopAudioLevelMonitoring()
    }

    private func startSpeechRecognition() throws {
        let inputNode = audioEngine.inputNode

        // Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.recognitionRequestFailed
        }

        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = true // On-device processing

        // Create recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            Task { @MainActor in
                if let result = result {
                    self.transcript = result.bestTranscription.formattedString

                    if result.isFinal {
                        self.finalTranscript = result.bestTranscription.formattedString
                        self.stopListening()
                    }
                }

                if let error = error {
                    print("Speech recognition error: \(error)")
                    self.stopListening()
                }
            }
        }

        // Configure audio format
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)

            // Calculate audio level for visualization
            let level = self.calculateAudioLevel(from: buffer)
            Task { @MainActor in
                self.audioLevel = level
            }
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()
    }

    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }

        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride).map { channelDataValue[$0] }

        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(channelDataValueArray.count))
        let avgPower = 20 * log10(rms)
        let normalizedPower = max(0.0, (avgPower + 80) / 80) // Normalize to 0-1 range

        return min(1.0, max(0.0, normalizedPower))
    }

    func speak(_ text: String, completion: @escaping () -> Void = {}) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        // Try to use a high-quality voice
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        // Store completion callback
        speechCompletionCallback = completion

        speechSynthesizer.speak(utterance)
    }

    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }

    private var speechCompletionCallback: (() -> Void)?

    // Enhanced voice recognition with real-time processing
    func startAdvancedListening() {
        guard hasPermission else {
            requestPermissions()
            return
        }

        startListening()

        // Start real-time audio level monitoring
        startAudioLevelMonitoring()
    }

    func speakWithExpression(_ text: String, emotion: VoiceEmotion = .neutral) {
        let utterance = AVSpeechUtterance(string: text)

        // Set language for TTS
        let ttsLanguage = languageLocales[languageManager.selectedLanguage] ?? "en-IN"
        utterance.voice = AVSpeechSynthesisVoice(language: ttsLanguage)

        print("🎵 TTS speaking in: \(languageManager.selectedLanguageName) (\(ttsLanguage))")

        // Configure expressive voice parameters based on emotion
        switch emotion {
        case .excited:
            utterance.rate = 0.6
            utterance.pitchMultiplier = 1.2
            utterance.volume = 0.8
        case .calm:
            utterance.rate = 0.4
            utterance.pitchMultiplier = 0.9
            utterance.volume = 0.6
        case .friendly:
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.1
            utterance.volume = 0.7
        case .serious:
            utterance.rate = 0.45
            utterance.pitchMultiplier = 0.8
            utterance.volume = 0.7
        case .neutral:
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 0.7
        }

        // Real-time voice processing
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1

        speechSynthesizer.speak(utterance)
    }

    enum VoiceEmotion {
        case excited, calm, friendly, serious, neutral
    }

    private func startAudioLevelMonitoring() {
        audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                self.updateAudioLevel()
            }
        }
    }

    private func updateAudioLevel() {
        if audioEngine.isRunning {
            // Simulate audio level for expressive feedback
            audioLevel = Float.random(in: 0.1...0.9)
        }
    }

    private func stopAudioLevelMonitoring() {
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil
        audioLevel = 0.0
    }

    // MARK: - Audio Recording for Sarvam STT
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?

    func startRecording() -> Bool {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingURL = documentsPath.appendingPathComponent("recording.wav")
        self.recordingURL = recordingURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsFloatKey: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            print("🎤 Started audio recording for Sarvam STT")
            return true
        } catch {
            print("❌ Failed to start recording: \(error)")
            return false
        }
    }

    func stopRecording() -> Data? {
        audioRecorder?.stop()
        audioRecorder = nil

        guard let recordingURL = recordingURL else {
            print("❌ No recording URL available")
            return nil
        }

        do {
            let audioData = try Data(contentsOf: recordingURL)
            print("🎤 Stopped recording, got \(audioData.count) bytes")

            // Clean up the file
            try? FileManager.default.removeItem(at: recordingURL)

            return audioData
        } catch {
            print("❌ Failed to read audio data: \(error)")
            return nil
        }
    }
}

// MARK: - AVSpeechSynthesizerDelegate
extension VoiceManager: @preconcurrency AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            speechCompletionCallback?()
            speechCompletionCallback = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            speechCompletionCallback?()
            speechCompletionCallback = nil
        }
    }
}

// MARK: - Voice Errors
enum VoiceError: Error {
    case recognitionRequestFailed
    case noPermission
    case audioEngineError

    var localizedDescription: String {
        switch self {
        case .recognitionRequestFailed:
            return "Failed to create speech recognition request"
        case .noPermission:
            return "No permission for speech recognition or microphone access"
        case .audioEngineError:
            return "Audio engine error"
        }
    }
}
