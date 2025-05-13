//
//  ChatView.swift
//  P2PChat
//
//  Created by Henrik Panhans on 07.03.25.
//

import OSLog
import P2PKit
import PhotosUI
import SwiftUI

struct ChatView<ChatPeer: Peer>: View {

    @Bindable
    var chatMessageHandler: ChatMessageHandler<ChatPeer>

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                List {
                    if chatMessageHandler.chatMessages.isEmpty {
                        ContentUnavailableView(
                            "No messages",
                            systemImage: "tray",
                            description: Text("Messages will be displayed here when you send or receive them.")
                        )
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(chatMessageHandler.chatMessages) { message in
                            ChatMessageCellView(
                                message: message,
                                ownPeerID: chatMessageHandler.ownPeerID,
                                peerGivenName: chatMessageHandler.peerGivenName
                            )

                        }.listRowSeparator(.hidden)
                    }
                }
                .defaultScrollAnchor(.bottom)
                .listStyle(.plain)
            }
            ChatMessageComposerView(chatMessageHandler: chatMessageHandler)
        }
        .navigationTitle(chatMessageHandler.peerGivenName ?? chatMessageHandler.peerID)
        .frame(minHeight: 400)
    }

}

#Preview("Chat") {
    ChatViewPreview()
}

#Preview("Message Bubbles") {
    VStack {
        ScrollView(.vertical) {
            VStack(spacing: 8) {
                ChatMessageCellView(
                    message: ChatMessage(date: .now, sender: "me", recipient: "you", content: .text("Test message")),
                    ownPeerID: "me",
                    peerGivenName: "LePeer"
                )
                ChatMessageCellView(
                    message: ChatMessage(date: .now, sender: "you", recipient: "me", content: .text("Test message")),
                    ownPeerID: "me",
                    peerGivenName: "LePeer"
                )
                ChatMessageCellView(
                    message: ChatMessage(date: .now, sender: "me", recipient: "you", content: .text("Test message")),
                    ownPeerID: "me",
                    peerGivenName: "LePeer"
                )
                ChatMessageCellView(
                    message: ChatMessage(date: .now, sender: "you", recipient: "me", content: .text("Test message")),
                    ownPeerID: "me",
                    peerGivenName: "LePeer"
                )
            }.padding(.horizontal)
        }.defaultScrollAnchor(.bottom)
    }
}
