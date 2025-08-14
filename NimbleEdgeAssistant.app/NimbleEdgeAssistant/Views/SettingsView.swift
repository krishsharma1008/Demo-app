/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import SwiftUI

struct SettingsView: View {
    @State private var isOnDeviceMode = true
    @State private var voiceEnabled = true
    @State private var hapticFeedback = true
    @State private var showingAbout = false
    @State private var showingPrivacy = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            ScrollView {
                VStack(spacing: 24) {
                    // AI Model Settings
                    SettingsSection(title: "AI Model") {
                        SettingsRow(
                            icon: "brain.head.profile",
                            title: "On-Device Processing",
                            subtitle: "All AI processing happens locally",
                            trailing: {
                                Toggle("", isOn: $isOnDeviceMode)
                                    .tint(.cyan)
                            }
                        )

                        SettingsRow(
                            icon: "cpu",
                            title: "Model",
                            subtitle: "Llama 3.2 1B Instruct",
                            showChevron: true,
                            action: {
                                // Model selection action
                            }
                        )

                        SettingsRow(
                            icon: "gauge.high",
                            title: "Performance",
                            subtitle: "Balanced mode",
                            showChevron: true,
                            action: {
                                // Performance settings action
                            }
                        )
                    }

                    // Voice Settings
                    SettingsSection(title: "Voice") {
                        SettingsRow(
                            icon: "waveform",
                            title: "Voice Mode",
                            subtitle: "Enable speech recognition and synthesis",
                            trailing: {
                                Toggle("", isOn: $voiceEnabled)
                                    .tint(.cyan)
                            }
                        )

                        SettingsRow(
                            icon: "speaker.wave.3",
                            title: "Voice Selection",
                            subtitle: "System default",
                            showChevron: true,
                            action: {
                                // Voice selection action
                            }
                        )

                        SettingsRow(
                            icon: "mic",
                            title: "Speech Recognition",
                            subtitle: "On-device processing",
                            showChevron: true,
                            action: {
                                // Speech settings action
                            }
                        )
                    }

                    // Interface Settings
                    SettingsSection(title: "Interface") {
                        SettingsRow(
                            icon: "iphone.radiowaves.left.and.right",
                            title: "Haptic Feedback",
                            subtitle: "Vibration for interactions",
                            trailing: {
                                Toggle("", isOn: $hapticFeedback)
                                    .tint(.cyan)
                            }
                        )

                        SettingsRow(
                            icon: "paintbrush",
                            title: "Appearance",
                            subtitle: "Dark mode",
                            showChevron: true,
                            action: {
                                // Appearance settings action
                            }
                        )

                        SettingsRow(
                            icon: "textformat.size",
                            title: "Text Size",
                            subtitle: "Medium",
                            showChevron: true,
                            action: {
                                // Text size settings action
                            }
                        )
                    }

                    // Privacy & Security
                    SettingsSection(title: "Privacy & Security") {
                        SettingsRow(
                            icon: "lock.shield",
                            title: "Privacy Policy",
                            subtitle: "How we protect your data",
                            action: {
                                showingPrivacy = true
                            }
                        )

                        SettingsRow(
                            icon: "trash",
                            title: "Clear All Data",
                            subtitle: "Remove conversations and settings",
                            isDestructive: true,
                            action: {
                                // Clear data action
                            }
                        )
                    }

                    // About
                    SettingsSection(title: "About") {
                        SettingsRow(
                            icon: "info.circle",
                            title: "About Bharat Saathi AI",
                            subtitle: "Version 1.0.0",
                            action: {
                                showingAbout = true
                            }
                        )

                        SettingsRow(
                            icon: "star",
                            title: "Rate the App",
                            subtitle: "Share your feedback",
                            action: {
                                // Rate app action
                            }
                        )

                        SettingsRow(
                            icon: "globe",
                            title: "Website",
                            subtitle: "bharatsaathi.ai",
                            action: {
                                // Open website action
                            }
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
        }
        .background(Color.black)
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyView()
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 4)

            VStack(spacing: 1) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isDestructive: Bool
    let showChevron: Bool
    let trailing: Trailing?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isDestructive: Bool = false,
        showChevron: Bool = false,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isDestructive = isDestructive
        self.showChevron = showChevron
        self.trailing = trailing()
        self.action = action
    }

    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .cyan)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(isDestructive ? .red : .white)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                if !(trailing is EmptyView) {
                    trailing
                } else if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.white)
                        )

                    VStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Bharat Saathi AI")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("AI")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.cyan)
                        }

                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }

                VStack(spacing: 16) {
                    Text("Your Private AI Assistant")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Bharat Saathi AI is a fully on-device conversational assistant that ensures your privacy while delivering intelligent responses. All processing happens locally on your device.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                VStack(spacing: 12) {
                    FeatureRow(icon: "brain.head.profile", title: "On-Device AI", description: "Complete privacy with local processing")
                    FeatureRow(icon: "waveform", title: "Voice Interface", description: "Natural speech conversations")
                    FeatureRow(icon: "lock.shield", title: "Secure", description: "No data leaves your device")
                    FeatureRow(icon: "bolt.fill", title: "Fast", description: "Optimized for mobile performance")
                }

                Spacer()

                Text("Built with ❤️ by Bharat Saathi AI")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 32)
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.cyan)
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
    }
}

struct PrivacyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 16) {
                        PrivacySection(
                            title: "On-Device Processing",
                            content: "All AI processing happens entirely on your device. Your conversations, voice recordings, and personal data never leave your device or get transmitted to external servers."
                        )

                        PrivacySection(
                            title: "Data Storage",
                            content: "Conversation history is stored locally on your device using secure iOS storage mechanisms. You can delete this data at any time through the app settings."
                        )

                        PrivacySection(
                            title: "Permissions",
                            content: "The app requests microphone access only for voice mode functionality. Speech recognition is performed on-device using Apple's frameworks."
                        )

                        PrivacySection(
                            title: "No Analytics",
                            content: "We don't collect usage analytics, crash reports, or any telemetry data. Your privacy is completely protected."
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(Color.black)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct PrivacySection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text(content)
                .font(.body)
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
    }
}
