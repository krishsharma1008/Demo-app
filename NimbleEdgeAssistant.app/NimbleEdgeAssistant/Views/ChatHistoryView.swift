/*
 * SPDX-FileCopyrightText: (C) 2025 DeliteAI Authors
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import SwiftUI

struct ChatHistoryView: View {
    @StateObject private var chatStorage = ChatHistoryManager()
    @State private var showingChatSession: ChatSession?
    @ObservedObject private var mainChatManager: ChatManager
    @Environment(\.dismiss) private var dismiss

    init(chatManager: ChatManager) {
        self.mainChatManager = chatManager
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Chat History")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                if !chatStorage.sessions.isEmpty {
                    Button("Clear All") {
                        chatStorage.clearAllHistory()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)

            if chatStorage.sessions.isEmpty {
                EmptyHistoryView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatStorage.sessions) { session in
                            ChatSessionCard(session: session) {
                                loadChatSession(session)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            chatStorage.loadSessions()
        }
    }

    private func loadChatSession(_ session: ChatSession) {
        // Load the selected session into the main chat manager
        mainChatManager.loadSession(session)
        dismiss()
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "clock.circle")
                    .font(.system(size: 60, weight: .light))
                    .foregroundColor(.gray)

                VStack(spacing: 8) {
                    Text("No Chat History")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("Your conversations will appear here")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

struct ChatSessionCard: View {
    let session: ChatSession
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(session.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Spacer()

                            // Online/Offline indicator
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(session.isOnlineSession ? Color.green : Color.orange)
                                    .frame(width: 6, height: 6)

                                Text(session.isOnlineSession ? "Online" : "Offline")
                                    .font(.caption2)
                                    .foregroundColor(session.isOnlineSession ? .green : .orange)
                            }
                        }

                        HStack {
                            Text("\(session.messages.count) messages")
                                .font(.caption)
                                .foregroundColor(.gray)

                            if session.isOnlineSession {
                                Text("• Sarvam AI")
                                    .font(.caption2)
                                    .foregroundColor(.cyan)
                            } else {
                                Text("• Local AI")
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    VStack(alignment: .trailing, spacing: 4) {
                        Text(session.lastMessageAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(session.lastMessageAt, style: .time)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }

                if let lastMessage = session.messages.last {
                    HStack {
                        Text(lastMessage.content)
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        // Message source indicator
                        if !lastMessage.isUser {
                            Image(systemName: lastMessage.source == .sarvamAI ? "cloud.fill" : "cpu")
                                .font(.caption2)
                                .foregroundColor(lastMessage.source == .sarvamAI ? .cyan : .gray)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(session.isOnlineSession ? Color.cyan.opacity(0.05) : Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(session.isOnlineSession ? Color.cyan.opacity(0.2) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ChatSessionDetailView: View {
    let session: ChatSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
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
                        Text(session.title)
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("\(session.messages.count) messages")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Button(action: { }) {
                        Image(systemName: "square.and.arrow.up")
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

                // Messages
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(session.messages) { message in
                            MessageBubble(message: message)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .background(Color.black)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Chat History Manager
@MainActor
class ChatHistoryManager: ObservableObject {
    @Published var sessions: [ChatSession] = []

    private let chatStorage = ChatStorage()

    func loadSessions() {
        sessions = chatStorage.loadChatHistory()
    }

    func clearAllHistory() {
        sessions.removeAll()
        chatStorage.clearCurrentSession()
        chatStorage.clearAllHistory()
    }
}
