/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import SwiftUI
import DeliteAI
#if canImport(MetricKit)
import MetricKit
#endif

// MARK: - MetricKit Integration
#if canImport(MetricKit)
@available(iOS 13.0, *)
final class MetricKitManager: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricKitManager()

    private override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        guard !payloads.isEmpty else { return }
        print("📈 MetricKit received \(payloads.count) payload(s)")
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        guard !payloads.isEmpty else { return }
        print("🩺 MetricKit received \(payloads.count) diagnostic payload(s)")
    }
}
#else
// Fallback stub so references compile on platforms without MetricKit
final class MetricKitManager {
    static let shared = MetricKitManager(); private init() {}
}
#endif

extension Notification.Name {
    static let modelReadyNotification = Notification.Name("modelReady")
}

@main
struct BharatSaathiAIApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var isSDKInitialized = false
    @State private var isSDKReady = false
    @State private var showInitializationFailureAlert = false
    @State private var showAppNotSupportedAlert = false

    init() {
        // Configure app appearance
        configureAppearance()

        // Register MetricKit subscriber early in app lifecycle to capture launch metrics
#if canImport(MetricKit)
        if #available(iOS 13.0, *) {
            _ = MetricKitManager.shared
        }
#endif
    }

    var body: some Scene {
        WindowGroup {
            if isSDKReady {
                ContentView()
                    .preferredColorScheme(.dark)
            } else {
                LaunchView(
                    isSDKInitialized: $isSDKInitialized,
                    isSDKReady: $isSDKReady,
                    onInitialize: initializeSDK
                )
                .preferredColorScheme(.dark)
                .alert("Initialization Failed", isPresented: $showInitializationFailureAlert) {
                    Button("Retry") { initializeSDK() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Failed to initialize the AI assistant. Please try again.")
                }
                .alert("Device Not Supported", isPresented: $showAppNotSupportedAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("This device is not supported for on-device AI processing.")
                }
            }
        }
    }

    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    private func initializeSDK() {
        Task {
            do {
                print("🚀 Starting SDK initialization...")

                // Local assets manifest for offline model - paths relative to app bundle
                let llamaAssets: [[String: Any]] = [
                    [
                        "name": "dialogpt-small",
                        "version": "1.0",
                        "location": ["path": "Models/llama3/model"],
                        "arguments": [
                            [
                                "name": "tokenizer",
                                "version": "1.0",
                                "location": ["path": "Models/llama3/tokenizer"]
                            ],
                            [
                                "name": "config",
                                "version": "1.0",
                                "location": ["path": "Models/llama3/config"]
                            ],
                            [
                                "name": "vocab",
                                "version": "1.0",
                                "location": ["path": "Models/llama3/vocab"]
                            ],
                            [
                                "name": "merges",
                                "version": "1.0",
                                "location": ["path": "Models/llama3/merges"]
                            ]
                        ]
                    ]
                ]

                // Create configuration for DeliteAI SDK
                let config = NimbleNetConfig(
                    clientId: "offline-demo",
                    clientSecret: "assistant-secret",
                    host: "",
                    deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
                    debug: true,
                    compatibilityTag: "dialogpt-small",
                    online: false
                )

                print("📦 Assets JSON: \(llamaAssets)")
                print("⚙️ Config: online=\(config.online), compatibilityTag=\(config.compatibilityTag)")

                let result = NimbleNetApi.initialize(config: config, assetsJson: llamaAssets)

                await MainActor.run {
                    if result.status {
                        print("✅ SDK initialization successful")
                        isSDKInitialized = true
                        checkSDKReadiness()

                        // Notify all chat managers that the model is ready
                        NotificationCenter.default.post(name: .modelReadyNotification, object: nil)
                    } else {
                        let errorMessage = result.error?.message ?? "Unknown error"
                        let errorCode = result.error?.code ?? -1
                        print("❌ SDK initialization failed:")
                        print("   Error code: \(errorCode)")
                        print("   Error message: \(errorMessage)")
                        // Still mark as initialized to allow UI interaction
                        isSDKInitialized = true

                        // Set ready to true to allow app to continue
                        isSDKReady = true
                    }
                }
            } catch {
                print("💥 Critical error during SDK initialization: \(error)")
                await MainActor.run {
                    isSDKInitialized = true
                    isSDKReady = true
                    showInitializationFailureAlert = true
                }
            }
        }
    }

    private func checkSDKReadiness() {
        Task {
            // Wait for SDK to be ready with timeout
            let maxAttempts = 30 // 3 seconds max
            var attempts = 0

            while !isSDKReady {
                attempts += 1

                do {
                    let readyResult = NimbleNetApi.isReady()
                    print("🔍 SDK readiness check attempt \(attempts): status=\(readyResult.status)")

                    if readyResult.status {
                        await MainActor.run {
                            isSDKReady = true
                            print("✅ SDK is ready!")
                        }
                        break
                    }

                    if attempts >= maxAttempts {
                        await MainActor.run {
                            print("⚠️ SDK readiness timeout after \(maxAttempts) attempts")
                            // Still allow UI to proceed even if SDK isn't "ready"
                            isSDKReady = true
                        }
                        break
                    }

                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                } catch {
                    print("❌ Error checking SDK readiness: \(error)")
                    await MainActor.run {
                        isSDKReady = true // Fallback to allow UI progression
                    }
                    break
                }
            }
        }
    }
}
