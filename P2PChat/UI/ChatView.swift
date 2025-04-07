//
//  ChatView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import P2PKit
import SwiftUI

struct ChatView<ChatPeer: Peer>: View {

    @State private var chatMessageHandler: ChatMessageHandler<ChatPeer>

    @State private var isPresentingAlert = false
    @State private var errorDescription: String?
    @Environment(\.dismiss) private var dismiss
    @State private var sendTask: Task<Void, Error>?

    init(service: any PeerDataTransferService<ChatPeer>, peerID: String) {
        self.chatMessageHandler = ChatMessageHandler(peerID: peerID, transferService: service)
    }

    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack(spacing: 8) {
                    ForEach(chatMessageHandler.chatMessages) { message in
                        ChatMessageCellView(message: message, ownPeerID: chatMessageHandler.ownPeerID)
                    }
                    if chatMessageHandler.chatMessages.isEmpty {
                        Text("No messages yet.")
                            .font(.subheadline)
                    }
                }.padding(.horizontal)
            }.defaultScrollAnchor(.bottom)
            textFieldContainer
        }
        .navigationTitle("Chat")
        .onDisappear {
            chatMessageHandler.onDisappear()
        }
    }

    private var textFieldContainer: some View {
        HStack(spacing: 12) {
            TextField("Message", text: $chatMessageHandler.currentMessage)
                .onSubmit {
                    let task = Task {
                        guard !chatMessageHandler.currentMessage.isEmpty else {
                            return
                        }
                        try await chatMessageHandler.sendMessage()
                    }
                    let currentTask = self.sendTask
                    sendTask = Task {
                        _ = try await currentTask?.value
                        _ = try await task.value
                    }
                }
                .textFieldStyle(.roundedBorder)
            sendButton(title: "Send")
                .disabled(chatMessageHandler.currentMessage.isEmpty)
        }
        .padding()
        .background(.regularMaterial)
        .alert("Error", isPresented: $isPresentingAlert, presenting: errorDescription) { error in
            sendButton(title: "Retry")
        } message: { errorDescription in
            Text(errorDescription)
        }
    }

    private func sendButton(title: LocalizedStringKey) -> some View {
        AsyncButton {
            do {
                try await chatMessageHandler.sendMessage()
            } catch {
                print("Sending failed, show error in UI", error)
                errorDescription = error.localizedDescription
            }
        } label: {
            Label(title, systemImage: "paperplane")
        }
    }

}

struct ChatMessageCellView<ChatPeer: Peer>: View {

    let message: ChatMessage<ChatPeer>
    let ownPeerID: ChatPeer.ID

    var body: some View {
        HStack {
            if isOwnMessage {
                Spacer()
                bubbleView
            } else {
                bubbleView
                Spacer()
            }
        }
    }

    private var bubbleView: some View {
        VStack(alignment: isOwnMessage ? .trailing : .leading, spacing: 4) {
            Text(message.content)
                .font(.body)
                .foregroundStyle(textColor)
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(bubbleColor)
                }
            Text(message.sender)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var isOwnMessage: Bool {
        message.sender == ownPeerID
    }

    private var textColor: Color {
        isOwnMessage ? .black : .white
    }

    private var bubbleColor: Color {
        isOwnMessage ? Color(white: 0.9) : .blue
    }

}

#Preview("Chat") {
    ChatView(
        service: BonjourDiscoveryService(service: .bonjourIdentifier, ownPeerID: "test1"),
        peerID: "test"
    )
}

#Preview("Message Bubbles") {
    VStack {
        ScrollView(.vertical) {
            VStack(spacing: 8) {
                ChatMessageCellView(
                    message: PreviewMessage(date: .now, content: "Test message", sender: "me", recipient: "you"),
                    ownPeerID: "me"
                )
                ChatMessageCellView(
                    message: PreviewMessage(date: .now, content: "Test message", sender: "you", recipient: "me"),
                    ownPeerID: "me"
                )
                ChatMessageCellView(
                    message: PreviewMessage(date: .now, content: "Test message", sender: "me", recipient: "you"),
                    ownPeerID: "me"
                )
                ChatMessageCellView(
                    message: PreviewMessage(date: .now, content: "Test message", sender: "you", recipient: "me"),
                    ownPeerID: "me"
                )
            }.padding(.horizontal)
        }.defaultScrollAnchor(.bottom)
    }
}
